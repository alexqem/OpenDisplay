import Foundation
import CoreGraphics

/// Unified Command Dispatcher: Single source of truth for CLI, HTTP, Menu Bar, and Hotkey commands
public final class DisplayCommandDispatcher: @unchecked Sendable {
    public static let shared = DisplayCommandDispatcher()

    private init() {}

    #if os(macOS) && arch(arm64)
    /// Adjust brightness for a target display (seamlessly routes between Apple DisplayServices, DDC, and Gamma Dimming)
    public func setBrightness(displayID: CGDirectDisplayID, level: Float) -> Bool {
        let clamped = max(0.0, min(1.0, level))

        // 1. If Apple native display, use DisplayServices
        if AppleDisplayServicesBridge.shared.canControlBrightness(displayID: displayID) {
            return AppleDisplayServicesBridge.shared.setBrightness(displayID: displayID, value: clamped)
        }

        // 2. Otherwise apply hardware or software gamma dimming
        do {
            try GammaDimmingEngine.applyGammaDimming(displayID: displayID, level: clamped)
            return true
        } catch {
            return false
        }
    }

    /// Read brightness for a target display
    public func getBrightness(displayID: CGDirectDisplayID) -> Float? {
        if let val = AppleDisplayServicesBridge.shared.getBrightness(displayID: displayID) {
            return val
        }
        return nil
    }

    /// Create Virtual Display
    public func createVirtual(config: VirtualDisplayConfig) -> VirtualDisplayController? {
        return VirtualDisplayController(config: config)
    }

    /// Force RGB color mode
    public func forceRGB(service: io_service_t) -> Bool {
        return RGBForcingEngine.applyLiveVirtualEDID(service: service, patchedEDID: [])
    }

    /// Set display mirror target
    public func setMirror(sourceID: CGDirectDisplayID, targetID: CGDirectDisplayID) -> Bool {
        return DisplayMirrorController.enableMirror(sourceID: sourceID, targetID: targetID)
    }

    /// Disable mirroring on display
    public func disableMirror(displayID: CGDirectDisplayID) -> Bool {
        return DisplayMirrorController.disableMirror(for: displayID)
    }

    /// Set display orientation angle
    public func setRotation(displayID: CGDirectDisplayID, angle: DisplayRotationAngle) -> Bool {
        return DisplayPowerStateController.shared.setDisplayOrientation(displayID: displayID, angle: angle)
    }

    /// Software disconnect / blank display
    public func disconnect(displayID: CGDirectDisplayID) -> Bool {
        return DisplayPowerStateController.shared.disconnectDisplay(displayID: displayID)
    }

    /// Reconnect display
    public func reconnect(displayID: CGDirectDisplayID) -> Bool {
        return DisplayPowerStateController.shared.reconnectDisplay(displayID: displayID)
    }
    #endif
}
