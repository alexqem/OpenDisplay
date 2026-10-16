#if os(macOS) && arch(arm64)
import Foundation
import CoreGraphics

/// Controls 10-Bit Deep Color (ARGB2101010) and HDR modes via SkyLight
public final class ColorDepthController: @unchecked Sendable {
    private typealias CGSConfigureDisplayModeFunc = @convention(c) (CGDisplayConfigRef, CGDirectDisplayID, Int32) -> CGError
    private typealias SLSDisplaySupportsHDRModeFunc = @convention(c) (CGDirectDisplayID) -> Bool
    private typealias SLSDisplayIsHDRModeEnabledFunc = @convention(c) (CGDirectDisplayID) -> Bool
    private typealias SLSDisplaySetHDRModeEnabledFunc = @convention(c) (CGDirectDisplayID, Bool, Int32, Int32) -> Int32

    private let skyLightLib: DynamicLibrary?
    private let configureDisplayModeFn: CGSConfigureDisplayModeFunc?
    private let supportsHDRFn: SLSDisplaySupportsHDRModeFunc?
    private let isHDREnabledFn: SLSDisplayIsHDRModeEnabledFunc?
    private let setHDREnabledFn: SLSDisplaySetHDRModeEnabledFunc?

    public static let shared = ColorDepthController()

    private init() {
        let path = "/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight"
        let lib = DynamicLibrary(path: path)
        self.skyLightLib = lib

        self.configureDisplayModeFn = lib?.resolve("CGSConfigureDisplayMode", as: CGSConfigureDisplayModeFunc.self)
        self.supportsHDRFn = lib?.resolve("SLSDisplaySupportsHDRMode", as: SLSDisplaySupportsHDRModeFunc.self)
        self.isHDREnabledFn = lib?.resolve("SLSDisplayIsHDRModeEnabled", as: SLSDisplayIsHDRModeEnabledFunc.self)
        self.setHDREnabledFn = lib?.resolve("SLSDisplaySetHDRModeEnabled", as: SLSDisplaySetHDRModeEnabledFunc.self)
    }

    /// Check if display supports HDR
    public func supportsHDR(displayID: CGDirectDisplayID) -> Bool {
        return supportsHDRFn?(displayID) ?? false
    }

    /// Query HDR state
    public func isHDREnabled(displayID: CGDirectDisplayID) -> Bool {
        return isHDREnabledFn?(displayID) ?? false
    }

    /// Toggle HDR mode (4 arguments on modern Apple Silicon macOS)
    public func setHDREnabled(displayID: CGDirectDisplayID, enabled: Bool) -> Bool {
        guard let setHDR = setHDREnabledFn else { return false }
        let status = setHDR(displayID, enabled, 0, 0)
        return status == 0
    }

    /// Inspect active display mode for 10-bit Deep Color encoding
    public func is10BitColorActive(displayID: CGDirectDisplayID) -> Bool {
        guard let mode = CGDisplayCopyDisplayMode(displayID),
              let pixelEncoding = mode.pixelEncoding else { return false }
        return CFStringCompare(pixelEncoding, ColorPixelFormat.argb2101010.rawValue as CFString, []) == .compareEqualTo
    }
}
#endif
