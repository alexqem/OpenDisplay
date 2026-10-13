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
    private typealias CGSConfigureDisplayModeFunc = @convention(c) (CGDisplayConfigRef, CGDirectDisplayID, Int32) -> CGError
    private typealias SLSIsDisplayModeVRRFunc = @convention(c) (CGDirectDisplayID, Int32) -> Bool
    private typealias SLSIsDisplayModeProMotionFunc = @convention(c) (CGDirectDisplayID, Int32) -> Bool
    private typealias SLSSetDisplayRotationFunc = @convention(c) (CGDisplayConfigRef, CGDirectDisplayID, Int32) -> CGError

    private let library: DynamicLibrary?
    private let getCurrentModeFn: CGSGetCurrentDisplayModeFunc?
    private let getModeCountFn: CGSGetNumberOfDisplayModesFunc?
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
}
#endif
