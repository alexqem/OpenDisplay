#if os(macOS) && arch(arm64)
import Foundation
import CoreGraphics

/// Mode description representation extracted from SkyLight
public struct DisplayModeInfo: Sendable {
    public let modeNumber: Int32
    public let isCurrent: Bool
    public let isVRR: Bool
    public let isProMotion: Bool
}

/// Dynamic interface to macOS SkyLight framework for native and virtual display mode control
public final class SkyLightModeEngine: @unchecked Sendable {
    private typealias CGSGetCurrentDisplayModeFunc = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Int32>) -> CGError
    private typealias CGSGetNumberOfDisplayModesFunc = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Int32>) -> CGError
    private typealias CGSGetDisplayModeDescriptionOfLengthFunc = @convention(c) (CGDirectDisplayID, Int32, UnsafeMutableRawPointer, Int) -> CGError
    private typealias CGSConfigureDisplayModeFunc = @convention(c) (CGDisplayConfigRef, CGDirectDisplayID, Int32) -> CGError
    private typealias SLSIsDisplayModeVRRFunc = @convention(c) (CGDirectDisplayID, Int32) -> Bool
    private typealias SLSIsDisplayModeProMotionFunc = @convention(c) (CGDirectDisplayID, Int32) -> Bool
    private typealias SLSSetDisplayRotationFunc = @convention(c) (CGDisplayConfigRef, CGDirectDisplayID, Int32) -> CGError

    private let library: DynamicLibrary?
    private let getCurrentModeFn: CGSGetCurrentDisplayModeFunc?
    private let getModeCountFn: CGSGetNumberOfDisplayModesFunc?
    private let getModeDescFn: CGSGetDisplayModeDescriptionOfLengthFunc?
    private let configureModeFn: CGSConfigureDisplayModeFunc?
    private let isVRRFn: SLSIsDisplayModeVRRFunc?
    private let isProMotionFn: SLSIsDisplayModeProMotionFunc?
    private let setRotationFn: SLSSetDisplayRotationFunc?

    public static let shared = SkyLightModeEngine()

    private init() {
        let path = "/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight"
        let lib = DynamicLibrary(path: path)
        self.library = lib

        self.getCurrentModeFn = lib?.resolve("CGSGetCurrentDisplayMode", as: CGSGetCurrentDisplayModeFunc.self)
        self.getModeCountFn = lib?.resolve("CGSGetNumberOfDisplayModes", as: CGSGetNumberOfDisplayModesFunc.self)
        self.getModeDescFn = lib?.resolve("CGSGetDisplayModeDescriptionOfLength", as: CGSGetDisplayModeDescriptionOfLengthFunc.self)
        self.configureModeFn = lib?.resolve("CGSConfigureDisplayMode", as: CGSConfigureDisplayModeFunc.self)
        self.isVRRFn = lib?.resolve("SLSIsDisplayModeVRR", as: SLSIsDisplayModeVRRFunc.self)
        self.isProMotionFn = lib?.resolve("SLSIsDisplayModeProMotion", as: SLSIsDisplayModeProMotionFunc.self)
        self.setRotationFn = lib?.resolve("SLSSetDisplayRotation", as: SLSSetDisplayRotationFunc.self)
    }

    /// Read active mode number
    public func getCurrentMode(displayID: CGDirectDisplayID) -> Int32? {
        guard let getMode = getCurrentModeFn else { return nil }
        var current: Int32 = 0
        let status = getMode(displayID, &current)
        return status == .success ? current : nil
    }

    /// Read total number of supported display modes
    public func getNumberOfModes(displayID: CGDirectDisplayID) -> Int32 {
        guard let getCount = getModeCountFn else { return 0 }
        var count: Int32 = 0
        let status = getCount(displayID, &count)
        return status == .success ? count : 0
    }

    /// Check if a mode is Variable Refresh Rate (VRR)
    public func isVRR(displayID: CGDirectDisplayID, modeNumber: Int32) -> Bool {
        return isVRRFn?(displayID, modeNumber) ?? false
    }

    /// Check if a mode is Apple ProMotion (up to 120Hz dynamic)
    public func isProMotion(displayID: CGDirectDisplayID, modeNumber: Int32) -> Bool {
        return isProMotionFn?(displayID, modeNumber) ?? false
    }

    /// Switch display resolution mode via CGBeginDisplayConfiguration
    public func setDisplayMode(displayID: CGDirectDisplayID, modeNumber: Int32) -> Bool {
        guard let configureFn = configureModeFn else { return false }

        var configRef: CGDisplayConfigRef?
        CGBeginDisplayConfiguration(&configRef)
        guard let config = configRef else { return false }

        let status = configureFn(config, displayID, modeNumber)
        if status == .success {
            CGCompleteDisplayConfiguration(config, .permanently)
            return true
        } else {
            CGCancelDisplayConfiguration(config)
            return false
        }
    }

    /// Rotate display (0, 90, 180, 270 degrees)
    public func setRotation(displayID: CGDirectDisplayID, degrees: Int32) -> Bool {
        guard let rotateFn = setRotationFn else { return false }

        var configRef: CGDisplayConfigRef?
        CGBeginDisplayConfiguration(&configRef)
        guard let config = configRef else { return false }

        let status = rotateFn(config, displayID, degrees)
        if status == .success {
            CGCompleteDisplayConfiguration(config, .permanently)
            return true
        } else {
            CGCancelDisplayConfiguration(config)
            return false
        }
    }

    /// Enumerate all available display modes with classification and recommendation metadata
    public func availableModes(for displayID: CGDirectDisplayID) -> [DisplayResolutionDescriptor] {
        let currentModeNumber = getCurrentMode(displayID: displayID) ?? -1
        let nativePixelWidth = CGDisplayPixelsWide(displayID)
        let nativePixelHeight = CGDisplayPixelsHigh(displayID)

        // Primary path: Enumerate via SkyLight CGSGetDisplayModeDescriptionOfLength
        if let descFn = getModeDescFn, let getCount = getModeCountFn {
            var count: Int32 = 0
            if getCount(displayID, &count) == .success, count > 0 {
                var descriptors: [DisplayResolutionDescriptor] = []
                var seenKeys = Set<String>()

                for m: Int32 in 0..<count {
                    var buf = [UInt8](repeating: 0, count: 512)
                    if descFn(displayID, m, &buf, buf.count) == .success {
                        buf.withUnsafeBytes { raw in
                            let u32 = raw.bindMemory(to: UInt32.self)
                            let modeNum = Int32(u32[0])
                            let pointW = Int(u32[2])
                            let pointH = Int(u32[3])
                            let rowBytes = Int(u32[5])
                            guard pointW > 0, pointH > 0 else { return }

                            let pixelW = rowBytes > 0 ? (rowBytes / 4) : pointW
                            let scale = Double(pixelW) / Double(pointW)
                            let pixelH = Int((Double(pointH) * scale).rounded())
                            let hz = Double(u32[9])
                            let isCurrent = (modeNum == currentModeNumber)

                            let dedupeKey = "\(pointW)x\(pointH)@\(Int(hz.rounded()))_\(pixelW)x\(pixelH)"
                            guard !seenKeys.contains(dedupeKey) else { return }
                            seenKeys.insert(dedupeKey)

                            let desc = ResolutionClassifier.classify(
                                modeNumber: modeNum,
                                pixelWidth: pixelW,
                                pixelHeight: pixelH,
                                pointWidth: pointW,
                                pointHeight: pointH,
                                refreshRate: hz > 0 ? hz : 60.0,
                                nativePixelWidth: nativePixelWidth,
                                nativePixelHeight: nativePixelHeight,
                                isCurrent: isCurrent
                            )
                            descriptors.append(desc)
                        }
                    }
                }

                if !descriptors.isEmpty {
                    // Sort descending by pointWidth, pointHeight, refreshRate
                    descriptors.sort { a, b in
                        if a.pointWidth != b.pointWidth { return a.pointWidth > b.pointWidth }
                        if a.pointHeight != b.pointHeight { return a.pointHeight > b.pointHeight }
                        return a.refreshRate > b.refreshRate
                    }
                    return descriptors
                }
            }
        }

        // Fallback path: CGDisplayCopyAllDisplayModes with duplicate modes enabled
        let options = [kCGDisplayShowDuplicateLowResolutionModes: kCFBooleanTrue] as CFDictionary
        guard let modeList = (CGDisplayCopyAllDisplayModes(displayID, options) as? [CGDisplayMode]) ??
                             (CGDisplayCopyAllDisplayModes(displayID, nil) as? [CGDisplayMode]) else {
            return []
        }

        let currentMode = CGDisplayCopyDisplayMode(displayID)

        var descriptors: [DisplayResolutionDescriptor] = []

        for (index, mode) in modeList.enumerated() {
            let pixelW = mode.pixelWidth
            let pixelH = mode.pixelHeight
            let pointW = mode.width
            let pointH = mode.height
            let rate = mode.refreshRate > 0 ? mode.refreshRate : VirtualDisplayLimits.defaultRefreshRate
            let modeNum = Int32(index)

            let isCurrent = (currentMode?.pixelWidth == pixelW &&
                             currentMode?.pixelHeight == pixelH &&
                             currentMode?.width == pointW &&
                             currentMode?.height == pointH &&
                             abs((currentMode?.refreshRate ?? 0) - rate) < ResolutionConstants.defaultRefreshRateThreshold) ||
                            (modeNum == currentModeNumber)

            let desc = ResolutionClassifier.classify(
                modeNumber: modeNum,
                pixelWidth: pixelW,
                pixelHeight: pixelH,
                pointWidth: pointW,
                pointHeight: pointH,
                refreshRate: rate,
                nativePixelWidth: nativePixelWidth,
                nativePixelHeight: nativePixelHeight,
                isCurrent: isCurrent
            )
            descriptors.append(desc)
        }

        return descriptors
    }

    /// Set display resolution directly using a CGDisplayMode match or fallback mode number
    public func setDisplayResolution(displayID: CGDirectDisplayID, pointWidth: Int, pointHeight: Int, isHiDPI: Bool, modeNumber: Int32? = nil) -> Bool {
        // If an explicit mode number was supplied, try setting it via CGSConfigureDisplayMode first
        if let modeNumber = modeNumber, modeNumber >= 0 {
            if setDisplayMode(displayID: displayID, modeNumber: modeNumber) {
                return true
            }
        }

        guard let modeList = CGDisplayCopyAllDisplayModes(displayID, nil) as? [CGDisplayMode] else {
            return false
        }

        // Find candidate mode matching requested point dimensions and scaling
        let matched = modeList.first { mode in
            let modeIsHiDPI = (mode.pixelWidth > mode.width)
            return mode.width == pointWidth &&
                   mode.height == pointHeight &&
                   (isHiDPI ? modeIsHiDPI : !modeIsHiDPI)
        } ?? modeList.first { mode in
            mode.width == pointWidth && mode.height == pointHeight
        }

        guard let targetMode = matched else { return false }

        var configRef: CGDisplayConfigRef?
        CGBeginDisplayConfiguration(&configRef)
        guard let config = configRef else { return false }

        let err = CGConfigureDisplayWithDisplayMode(config, displayID, targetMode, nil)
        if err == .success {
            CGCompleteDisplayConfiguration(config, .permanently)
            return true
        } else {
            CGCancelDisplayConfiguration(config)
            return false
        }
    }
}
#endif
