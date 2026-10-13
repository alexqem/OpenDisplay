import Foundation

/// Pure functional calculation for brightness scaling and sensitivity adjustment
public enum BrightnessSyncCalculator {

    /// Compute synchronized target brightness given built-in brightness and sensitivity factor
    public static func computeTargetBrightness(
        builtinBrightness: Double,
        sensitivity: Double = AutoBrightnessConstants.defaultSensitivity
    ) -> Double {
        let clampedBuiltin = min(max(builtinBrightness, AutoBrightnessConstants.minBrightness), AutoBrightnessConstants.maxBrightness)
        let clampedSensitivity = min(max(sensitivity, AutoBrightnessConstants.minSensitivity), AutoBrightnessConstants.maxSensitivity)
        let scaled = clampedBuiltin * clampedSensitivity
        return min(max(scaled, AutoBrightnessConstants.minBrightness), AutoBrightnessConstants.maxBrightness)
    }

    /// Check if brightness changed beyond threshold to prevent jitter
    public static func hasSignificantChange(
        oldValue: Double,
        newValue: Double,
        threshold: Double = AutoBrightnessConstants.changeThreshold
    ) -> Bool {
        return abs(oldValue - newValue) >= threshold
    }
}

#if os(macOS) && arch(arm64)
import CoreGraphics
import IOKit

/// Engine that synchronizes external display brightness with Apple Silicon built-in display auto-brightness
public final class AmbientBrightnessSyncEngine: @unchecked Sendable {
    private typealias GetUserBrightnessFunc = @convention(c) (CGDirectDisplayID) -> Double

    private let coreDisplayLib: DynamicLibrary?
    private let getUserBrightnessFn: GetUserBrightnessFunc?

    private var pollingTask: Task<Void, Never>?
    private let lock = NSLock()
    private var lastSyncedBrightness: Double = AutoBrightnessConstants.uninitializedBrightnessSentinel
    private var _sensitivity: Double = AutoBrightnessConstants.defaultSensitivity

    public var sensitivity: Double {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _sensitivity
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _sensitivity = newValue
        }
    }

    public static let shared = AmbientBrightnessSyncEngine()

    private init() {
        let path = "/System/Library/Frameworks/CoreDisplay.framework/CoreDisplay"
        let lib = DynamicLibrary(path: path)
        self.coreDisplayLib = lib
        self.getUserBrightnessFn = lib?.resolve("CoreDisplay_Display_GetUserBrightness", as: GetUserBrightnessFunc.self)
    }

    /// Read brightness of the MacBook built-in screen
    public func readBuiltinBrightness() -> Double? {
        var count: UInt32 = 0
        CGGetActiveDisplayList(0, nil, &count)
        guard count > 0 else { return nil }

        var displays = [CGDirectDisplayID](repeating: 0, count: Int(count))
        CGGetActiveDisplayList(count, &displays, &count)

        guard let builtinID = displays.first(where: { CGDisplayIsBuiltin($0) != 0 }) else {
            return nil
        }

        // Try CoreDisplay dynamic symbol
        if let getFn = getUserBrightnessFn {
            let val = getFn(builtinID)
            if val > AutoBrightnessConstants.minBrightness {
                return min(max(val, AutoBrightnessConstants.minBrightness), AutoBrightnessConstants.maxBrightness)
            }
        }

        // Fallback: IOKit IODisplayConnect parameter
        var iter: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IODisplayConnect"), &iter) == KERN_SUCCESS else {
            return nil
        }
        defer { IOObjectRelease(iter) }

        var service = IOIteratorNext(iter)
        while service != 0 {
            defer {
                IOObjectRelease(service)
                service = IOIteratorNext(iter)
            }
            var floatVal: Float = 0
            let kr = IODisplayGetFloatParameter(service, 0, kIODisplayBrightnessKey as CFString, &floatVal)
            if kr == KERN_SUCCESS && floatVal > Float(AutoBrightnessConstants.minBrightness) {
                return Double(floatVal)
            }
        }

        return nil
    }

    /// Start periodic polling and auto-synchronization
    public func startSync(onBrightnessChanged: @escaping @Sendable (Double) -> Void) {
        stopSync()

        lock.lock()
        defer { lock.unlock() }

        pollingTask = Task.detached { [weak self] in
            while !Task.isCancelled {
                guard let self else { break }

                if let builtin = self.readBuiltinBrightness() {
                    let currentSensitivity = self.sensitivity
                    let target = BrightnessSyncCalculator.computeTargetBrightness(
                        builtinBrightness: builtin,
                        sensitivity: currentSensitivity
                    )

                    self.lock.lock()
                    let changed = BrightnessSyncCalculator.hasSignificantChange(
                        oldValue: self.lastSyncedBrightness,
                        newValue: target
                    )
                    if changed {
                        self.lastSyncedBrightness = target
                    }
                    self.lock.unlock()

                    if changed {
                        onBrightnessChanged(target)
                    }
                }

                try? await Task.sleep(nanoseconds: UInt64(AutoBrightnessConstants.defaultPollingIntervalSeconds * Double(AutoBrightnessConstants.nanosecondsPerSecond)))
            }
        }
    }

    /// Stop auto-sync polling
    public func stopSync() {
        lock.lock()
        defer { lock.unlock() }
        pollingTask?.cancel()
        pollingTask = nil
    }

    deinit {
        stopSync()
    }
}
#endif
