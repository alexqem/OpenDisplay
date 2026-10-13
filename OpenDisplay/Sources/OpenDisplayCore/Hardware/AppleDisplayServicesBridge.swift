#if os(macOS) && arch(arm64)
import Foundation
import CoreGraphics

/// Bridge to Apple DisplayServices private framework for native backlight and ambient light controls
public final class AppleDisplayServicesBridge: @unchecked Sendable {
    private typealias DSGetBrightnessFunc = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32
    private typealias DSSetBrightnessFunc = @convention(c) (CGDirectDisplayID, Float) -> Int32
    private typealias DSCanChangeBrightnessFunc = @convention(c) (CGDirectDisplayID) -> Bool
    private typealias DSEnableAmbientFunc = @convention(c) (CGDirectDisplayID, Bool) -> Int32
    private typealias DSAmbientEnabledFunc = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Bool>) -> Int32

    private let library: DynamicLibrary?
    private let getBrightnessFn: DSGetBrightnessFunc?
    private let setBrightnessFn: DSSetBrightnessFunc?
    private let canChangeFn: DSCanChangeBrightnessFunc?
    private let enableAmbientFn: DSEnableAmbientFunc?
    private let ambientEnabledFn: DSAmbientEnabledFunc?

    public static let shared = AppleDisplayServicesBridge()

    private init() {
        let path = "/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices"
        let lib = DynamicLibrary(path: path)
        self.library = lib

        self.getBrightnessFn = lib?.resolve("DisplayServicesGetBrightness", as: DSGetBrightnessFunc.self)
        self.setBrightnessFn = lib?.resolve("DisplayServicesSetBrightness", as: DSSetBrightnessFunc.self)
        self.canChangeFn = lib?.resolve("DisplayServicesCanChangeBrightness", as: DSCanChangeBrightnessFunc.self)
        self.enableAmbientFn = lib?.resolve("DisplayServicesEnableAmbientLightCompensation", as: DSEnableAmbientFunc.self)
        self.ambientEnabledFn = lib?.resolve("DisplayServicesAmbientLightCompensationEnabled", as: DSAmbientEnabledFunc.self)
    }

    /// Check if DisplayServices supports controlling this display
    public func canControlBrightness(displayID: CGDirectDisplayID) -> Bool {
        return canChangeFn?(displayID) ?? false
    }

    /// Read brightness level (0.0 ... 1.0)
    public func getBrightness(displayID: CGDirectDisplayID) -> Float? {
        guard let getFn = getBrightnessFn else { return nil }
        var value: Float = 0.0
        let status = getFn(displayID, &value)
        return status == 0 ? value : nil
    }

    /// Set brightness level (0.0 ... 1.0)
    public func setBrightness(displayID: CGDirectDisplayID, value: Float) -> Bool {
        guard let setFn = setBrightnessFn else { return false }
        let clamped = max(0.0, min(1.0, value))
        let status = setFn(displayID, clamped)
        return status == 0
    }

    /// Toggle ambient light sensor auto-brightness compensation
    public func setAmbientLightCompensation(displayID: CGDirectDisplayID, enabled: Bool) -> Bool {
        guard let enableFn = enableAmbientFn else { return false }
        return enableFn(displayID, enabled) == 0
    }

    /// Query ambient light compensation state
    public func isAmbientLightCompensationEnabled(displayID: CGDirectDisplayID) -> Bool? {
        guard let queryFn = ambientEnabledFn else { return nil }
        var enabled = false
        let status = queryFn(displayID, &enabled)
        return status == 0 ? enabled : nil
    }
}
#endif
