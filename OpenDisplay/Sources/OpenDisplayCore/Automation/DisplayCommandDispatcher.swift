import Foundation
import CoreGraphics

/// Unified Command Dispatcher: Single source of truth for CLI, UI, Menu Bar, and Hotkey commands
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
        return AppleDisplayServicesBridge.shared.getBrightness(displayID: displayID)
    }

    /// Set speaker volume on an external display via DDC/CI VCP 0x62
    public func setVolume(displayID: CGDirectDisplayID, level: Float) -> Bool {
        let clamped = max(0.0, min(1.0, level))
        let rawValue = UInt16((clamped * Float(DDCProtocolLimits.vcpPercentScale)).rounded())
        guard let service = IOAVServiceMatcher.service(for: displayID),
              let ddc = IOAVServiceDDC(service: service) else {
            return false
        }
        return ddc.setVCP(code: .audioSpeakerVolume, value: rawValue)
    }

    /// Engage or release hardware audio mute via DDC/CI VCP 0x8D
    public func setMuted(displayID: CGDirectDisplayID, muted: Bool) -> Bool {
        let rawValue = muted ? DDCProtocolLimits.audioMuteEngaged : DDCProtocolLimits.audioMuteReleased
        guard let service = IOAVServiceMatcher.service(for: displayID),
              let ddc = IOAVServiceDDC(service: service) else {
            return false
        }
        return ddc.setVCP(code: .audioMute, value: rawValue)
    }

    /// Switch active video input source on an external display via DDC/CI VCP 0x60
    public func setInputSource(displayID: CGDirectDisplayID, source: DDCInputSource) -> Bool {
        guard let service = IOAVServiceMatcher.service(for: displayID),
              let ddc = IOAVServiceDDC(service: service) else {
            return false
        }
        return ddc.setInputSource(source)
    }

    /// Read current active video input source from an external display via DDC/CI VCP 0x60
    public func getInputSource(displayID: CGDirectDisplayID) -> DDCInputSource? {
        guard let service = IOAVServiceMatcher.service(for: displayID),
              let ddc = IOAVServiceDDC(service: service) else {
            return nil
        }
        return ddc.getInputSource()
    }

    /// Enumerate all supported resolution modes for a display
    public func availableResolutions(for displayID: CGDirectDisplayID) -> [DisplayResolutionDescriptor] {
        return SkyLightModeEngine.shared.availableModes(for: displayID)
    }

    /// Switch resolution on a display with mode number fallback
    public func setResolution(displayID: CGDirectDisplayID, width: Int, height: Int, isHiDPI: Bool, modeNumber: Int32? = nil) -> Bool {
        return SkyLightModeEngine.shared.setDisplayResolution(
            displayID: displayID,
            pointWidth: width,
            pointHeight: height,
            isHiDPI: isHiDPI,
            modeNumber: modeNumber
        )
    }

    /// Create a Virtual Display and register it in the lifecycle manager
    public func createVirtual(config: VirtualDisplayConfig) -> VirtualDisplayController? {
        guard let controller = VirtualDisplayController(config: config) else { return nil }
        VirtualDisplayManager.shared.register(controller)
        return controller
    }

    /// Tear down a registered Virtual Display
    @discardableResult
    public func removeVirtual(displayID: CGDirectDisplayID) -> Bool {
        return VirtualDisplayManager.shared.remove(displayID: displayID)
    }

    /// Whether a display ID belongs to a registered Virtual Display
    public func isVirtual(displayID: CGDirectDisplayID) -> Bool {
        return VirtualDisplayManager.shared.contains(displayID: displayID)
    }

    /// Compact descriptor list of active virtual displays for UI chips
    public func virtualDisplayDescriptors() -> [(id: CGDirectDisplayID, name: String)] {
        return VirtualDisplayManager.shared.allControllers().map { ($0.displayID, $0.config.name) }
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

    // MARK: - Display Group Synchronization (Master-Slave)

    /// Adjust brightness on a master display and automatically propagate calibrated offsets to linked slaves
    public func setMasterBrightness(displayID: CGDirectDisplayID, level: Float) -> Bool {
        let masterSuccess = setBrightness(displayID: displayID, level: level)
        guard let group = DisplayGroupManager.shared.groupForMaster(displayID: displayID),
              group.isBrightnessSyncEnabled else {
            return masterSuccess
        }

        for member in group.members {
            let target = DisplayGroup.calculateTargetLevel(
                masterLevel: Double(level),
                offset: member.brightnessOffset
            )
            _ = setBrightness(displayID: member.displayID, level: Float(target))
        }
        return masterSuccess
    }

    /// Adjust volume on a master display and automatically propagate calibrated offsets to linked slaves
    public func setMasterVolume(displayID: CGDirectDisplayID, level: Float) -> Bool {
        let masterSuccess = setVolume(displayID: displayID, level: level)
        guard let group = DisplayGroupManager.shared.groupForMaster(displayID: displayID),
              group.varVolumeSyncEnabled else {
            return masterSuccess
        }

        for member in group.members {
            let target = DisplayGroup.calculateTargetLevel(
                masterLevel: Double(level),
                offset: member.volumeOffset
            )
            _ = setVolume(displayID: member.displayID, level: Float(target))
        }
        return masterSuccess
    }

    /// Software disconnect / blank display
    public func disconnect(displayID: CGDirectDisplayID) -> Bool {
        return DisplayPowerStateController.shared.disconnectDisplay(displayID: displayID)
    }

    /// Reconnect display
    public func reconnect(displayID: CGDirectDisplayID) -> Bool {
        return DisplayPowerStateController.shared.reconnectDisplay(displayID: displayID)
    }

    /// Toggle HDR mode on a display
    public func setHDR(displayID: CGDirectDisplayID, enabled: Bool) -> Bool {
        return ColorDepthController.shared.setHDREnabled(displayID: displayID, enabled: enabled)
    }

    /// Query live HDR state of a display
    public func isHDREnabled(displayID: CGDirectDisplayID) -> Bool {
        return ColorDepthController.shared.isHDREnabled(displayID: displayID)
    }

    /// Query whether the active pixel encoding is 10-Bit Deep Color
    public func is10BitColorActive(displayID: CGDirectDisplayID) -> Bool {
        return ColorDepthController.shared.is10BitColorActive(displayID: displayID)
    }

    /// Enumerate all system ICC color profiles
    public func availableColorProfiles() -> [ICCProfileInfo] {
        return ColorProfileController.shared.enumerateProfiles()
    }

    /// Apply an ICC color profile by case-insensitive name substring
    public func setColorProfile(named profileName: String, for displayID: CGDirectDisplayID) -> Bool {
        let profiles = availableColorProfiles()
        guard let matched = profiles.first(where: { $0.name.localizedCaseInsensitiveContains(profileName) }) else {
            return false
        }
        return ColorProfileController.shared.setProfile(matched, for: displayID)
    }

    /// Apply a preset snapshot: restores arrangement origins and brightness for every resolvable entry
    @discardableResult
    public func applyPreset(_ preset: DisplayPreset) -> Int {
        var appliedCount = 0
        for entry in preset.displays {
            guard let displayID = DisplayInventory.displayID(forUUIDString: entry.displayUUID) else { continue }
            if let x = entry.arrangementX, let y = entry.arrangementY {
                _ = DisplayArrangementController.setDisplayOrigin(displayID: displayID, x: x, y: y)
            }
            if let brightness = entry.brightness {
                _ = setBrightness(displayID: displayID, level: Float(brightness))
            }
            appliedCount += 1
        }
        return appliedCount
    }

    /// Toggle Night Shift via CoreBrightness bridge
    public func setNightShift(enabled: Bool) -> Bool {
        do {
            try NightShiftTrueToneBridge.shared.setNightShift(enabled: enabled)
            return true
        } catch {
            return false
        }
    }

    /// Toggle True Tone via CoreBrightness bridge (supported Macs only)
    public func setTrueTone(enabled: Bool) -> Bool {
        do {
            try NightShiftTrueToneBridge.shared.setTrueTone(enabled: enabled)
            return true
        } catch {
            return false
        }
    }

    /// Start floating Picture-in-Picture streaming for a display
    public func startPip(displayID: CGDirectDisplayID) -> Bool {
        guard #available(macOS 12.3, *) else { return false }
        guard !PipStreamManager.shared.isActive else { return false }
        PipStreamManager.shared.start(displayID: displayID)
        return true
    }

    /// Start floating Picture-in-Picture streaming for an application window
    public func startWindowPip(windowID: CGWindowID) -> Bool {
        guard #available(macOS 12.3, *) else { return false }
        guard !PipStreamManager.shared.isActive else { return false }
        PipStreamManager.shared.start(windowID: windowID)
        return true
    }

    /// Set PiP panel opacity
    public func setPipOpacity(_ opacity: CGFloat) {
        guard #available(macOS 12.3, *) else { return }
        PipStreamManager.shared.setOpacity(opacity)
    }

    /// Set PiP click-through pass-through
    public func setPipClickThrough(_ enabled: Bool) {
        guard #available(macOS 12.3, *) else { return }
        PipStreamManager.shared.setClickThrough(enabled)
    }

    /// Stop the active Picture-in-Picture stream
    public func stopPip() {
        guard #available(macOS 12.3, *) else { return }
        PipStreamManager.shared.stop()
    }

    /// Whether a PiP stream is currently active
    public func isPipActive() -> Bool {
        guard #available(macOS 12.3, *) else { return false }
        return PipStreamManager.shared.isActive
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
            let names = DisplayPresetManager.shared.getAllPresets().map { $0.name }
            return (true, names.isEmpty ? "No presets" : names.joined(separator: ", "))

        case .forceRGB(let target):
            let tID = UInt32(target).map { CGDirectDisplayID($0) } ?? CGMainDisplayID()
            let ok = forceRGB(service: io_service_t(tID))
            return (ok, ok ? "Applied Force RGB 4:4:4 mode to display \(tID)" : "Failed to force RGB 4:4:4")

        case .setHDR(let target, let enabled):
            let tID = UInt32(target).map { CGDirectDisplayID($0) } ?? CGMainDisplayID()
            let ok = setHDR(displayID: tID, enabled: enabled)
            return (ok, ok ? "Set HDR \(enabled ? "enabled" : "disabled") on display \(tID)" : "Failed to toggle HDR on display \(tID)")

        case .setProfile(let target, let profileName):
            let targetID = UInt32(target).map { CGDirectDisplayID($0) } ?? CGMainDisplayID()
            let ok = setColorProfile(named: profileName, for: targetID)
            return (ok, ok ? "Applied color profile '\(profileName)' to display \(targetID)" : "Failed to apply color profile")

        case .setInputSource(let target, let sourceStr):
            guard let source = DDCInputSource.from(cliString: sourceStr) else {
                return (false, "Invalid input source: '\(sourceStr)'. Supported: dp1, dp2, hdmi1, hdmi2, usbc")
            }
            let targetID = UInt32(target).map { CGDirectDisplayID($0) } ?? CGMainDisplayID()
            let ok = setInputSource(displayID: targetID, source: source)
            return (ok, ok ? "Switched display \(targetID) input to \(source.label)" : "Failed to switch input source on display \(targetID)")

        case .setResolution(let target, let width, let height, let isHiDPI):
            let targetID = UInt32(target).map { CGDirectDisplayID($0) } ?? CGMainDisplayID()
            let ok = setResolution(displayID: targetID, width: width, height: height, isHiDPI: isHiDPI)
            return (ok, ok ? "Changed display \(targetID) resolution to \(width)x\(height) (\(isHiDPI ? "HiDPI" : "1x"))" : "Failed to change resolution on display \(targetID)")

        case .listResolutions(let target):
            let targetID = UInt32(target).map { CGDirectDisplayID($0) } ?? CGMainDisplayID()
            let modes = availableResolutions(for: targetID)
            let formatted = modes.map { "\($0.userLabel) [\($0.isRecommended ? "RECOMMENDED" : $0.tier.rawValue)]" }.joined(separator: "\n")
            return (true, formatted.isEmpty ? "No modes reported" : formatted)

        case .listProfiles:
            let profiles = availableColorProfiles()
            let names = profiles.map { $0.name }.joined(separator: ", ")
            return (true, names.isEmpty ? "No ICC profiles found" : names)

        case .linkGroup(let master, let slave, let offset):
            guard let mNum = UInt32(master), let sNum = UInt32(slave) else {
                return (false, "Invalid master or slave display ID")
            }
            let mID = CGDirectDisplayID(mNum)
            let sID = CGDirectDisplayID(sNum)
            DisplayGroupManager.shared.linkSlave(masterID: mID, slaveID: sID, brightnessOffset: offset)
            return (true, "Linked slave display \(sID) to master \(mID) with offset \(offset)")

        case .unlinkGroup(let slave):
            guard let sNum = UInt32(slave) else {
                return (false, "Invalid slave display ID")
            }
            let sID = CGDirectDisplayID(sNum)
            DisplayGroupManager.shared.unlinkSlave(slaveID: sID)
            return (true, "Unlinked display \(sID) from sync groups")

        case .listGroups:
            let groups = DisplayGroupManager.shared.getAllGroups()
            if groups.isEmpty {
                return (true, "No display sync groups configured")
            }
            let desc = groups.map { g in
                let membersDesc = g.members.map { "Display \($0.displayID) (offset: \($0.brightnessOffset))" }.joined(separator: ", ")
                return "Group '\(g.name)' [Master: \(g.masterDisplayID)] -> Slaves: [\(membersDesc)]"
            }.joined(separator: "\n")
            return (true, desc)

        case .unknown(let cmd):
            return (false, "Unknown command: \(cmd)")
        }
    }
    #endif
}
