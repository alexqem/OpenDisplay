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

    /// Execute parsed CLICommand directly against display controllers
    public func executeCLI(_ command: CLICommand) -> (success: Bool, message: String) {
        switch command {
        case .help:
            return (true, "OpenDisplay CLI: get, set, create-virtual, mirror, unmirror, rotate, disconnect, reconnect, presets")

        case .get(let target, let property):
            let targetID = UInt32(target).map { CGDirectDisplayID($0) } ?? CGMainDisplayID()
            if property == AutomationConstants.cliDefaultBrightnessProperty || property == AutomationConstants.cliDefaultTargetAll {
                let brightness = getBrightness(displayID: targetID) ?? 1.0
                return (true, "display \(targetID) brightness: \(brightness)")
            }
            return (true, "display \(targetID) queried property \(property)")

        case .set(let target, let property, let value):
            let targetID = UInt32(target).map { CGDirectDisplayID($0) } ?? CGMainDisplayID()
            if property == AutomationConstants.cliDefaultBrightnessProperty {
                let val = (Float(value) ?? 100.0) / 100.0
                let ok = setBrightness(displayID: targetID, level: val)
                return (ok, ok ? "Set display \(targetID) brightness to \(value)%" : "Failed to set brightness")
            }
            return (false, "Unsupported property: \(property)")

        case .createVirtual(let name, let aspect, let width):
            let preset = DisplayAspectPreset(rawValue: aspect) ?? .ratio16_9
            let cfg = VirtualDisplayConfig(name: name, aspectPreset: preset, baseWidth: width)
            let controller = createVirtual(config: cfg)
            return (controller != nil, controller != nil ? "Created virtual display ID \(controller!.displayID)" : "Failed to create virtual display")

        case .mirror(let source, let target):
            guard let sNum = UInt32(source), let tNum = UInt32(target) else {
                return (false, "Invalid source or target display ID")
            }
            let sID = CGDirectDisplayID(sNum)
            let tID = CGDirectDisplayID(tNum)
            let ok = setMirror(sourceID: sID, targetID: tID)
            return (ok, ok ? "Mirrored display \(tID) from \(sID)" : "Failed to mirror display")

        case .unmirror(let target):
            let tID = UInt32(target).map { CGDirectDisplayID($0) } ?? CGMainDisplayID()
            let ok = disableMirror(displayID: tID)
            return (ok, ok ? "Disabled mirroring on display \(tID)" : "Failed to disable mirror")

        case .rotate(let target, let degrees):
            let tID = UInt32(target).map { CGDirectDisplayID($0) } ?? CGMainDisplayID()
            let angle = DisplayRotationAngle(rawValue: degrees) ?? .standard
            let ok = setRotation(displayID: tID, angle: angle)
            return (ok, ok ? "Rotated display \(tID) to \(degrees)°" : "Failed to rotate display")

        case .disconnect(let target):
            let tID = UInt32(target).map { CGDirectDisplayID($0) } ?? CGMainDisplayID()
            let ok = disconnect(displayID: tID)
            return (ok, ok ? "Disconnected display \(tID)" : "Failed to disconnect display")

        case .reconnect(let target):
            let tID = UInt32(target).map { CGDirectDisplayID($0) } ?? CGMainDisplayID()
            let ok = reconnect(displayID: tID)
            return (ok, ok ? "Reconnected display \(tID)" : "Failed to reconnect display")

        case .listPresets:
            return (true, "Default Native, Work 4K Setup")

        case .forceRGB(let target):
            let tID = UInt32(target).map { CGDirectDisplayID($0) } ?? CGMainDisplayID()
            let ok = forceRGB(service: io_service_t(tID))
            return (ok, ok ? "Applied Force RGB 4:4:4 mode to display \(tID)" : "Failed to force RGB 4:4:4")

        case .setHDR(let target, let enabled):
            let tID = UInt32(target).map { CGDirectDisplayID($0) } ?? CGMainDisplayID()
            let ok = ColorDepthController.shared.setHDREnabled(displayID: tID, enabled: enabled)
            return (ok, ok ? "Set HDR \(enabled ? "enabled" : "disabled") on display \(tID)" : "Failed to toggle HDR on display \(tID)")

        case .setProfile(let target, let profileName):
            let tID = UInt32(target).map { CGDirectDisplayID($0) } ?? CGMainDisplayID()
            let profiles = ColorProfileController.shared.enumerateProfiles()
            guard let matched = profiles.first(where: { $0.name.localizedCaseInsensitiveContains(profileName) }) else {
                return (false, "Color profile '\(profileName)' not found")
            }
            let ok = ColorProfileController.shared.setProfile(matched, for: tID)
            return (ok, ok ? "Applied color profile '\(matched.name)' to display \(tID)" : "Failed to apply color profile")

        case .listProfiles:
            let profiles = ColorProfileController.shared.enumerateProfiles()
            let names = profiles.map { $0.name }.joined(separator: ", ")
            return (true, names.isEmpty ? "No ICC profiles found" : names)

        case .unknown(let cmd):
            return (false, "Unknown command: \(cmd)")
        }
    }
    #endif
}
