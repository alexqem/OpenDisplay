#if os(macOS) && arch(arm64)
import AppKit
import CoreGraphics

// MARK: - WorkspaceStore Virtual Displays, System Automation & Display Sync Groups Extension (SRP)
extension WorkspaceStore {

    // MARK: - Virtual Displays
    public func createVirtualDisplay() {
        let name = "Virtual \(selectedAspect.rawValue) \(Int(selectedRefreshRate))Hz"
        let config = VirtualDisplayConfig(
            name: name,
            aspectPreset: selectedAspect,
            refreshRate: selectedRefreshRate,
            isHiDPI: isHiDPIEnabled
        )
        guard dispatcher.createVirtual(config: config) != nil else { return }
        refresh()
    }

    public func removeVirtualDisplay(id: CGDirectDisplayID) {
        dispatcher.removeVirtual(displayID: id)
        refresh()
    }

    // MARK: - System Toggles
    public func toggleNightShift() {
        let target = !isNightShiftOn
        if dispatcher.setNightShift(enabled: target) {
            isNightShiftOn = target
        }
    }

    public func toggleTrueTone() {
        let target = !isTrueToneOn
        if dispatcher.setTrueTone(enabled: target) {
            isTrueToneOn = target
        }
    }

    public func setAmbientSync(_ enabled: Bool) {
        isAmbientSyncOn = enabled
        if enabled {
            AmbientBrightnessSyncEngine.shared.sensitivity = ambientSensitivity
            AmbientBrightnessSyncEngine.shared.startSync { [weak self] builtin in
                Task { @MainActor [weak self] in
                    self?.propagateAmbientBrightness(builtin)
                }
            }
        } else {
            AmbientBrightnessSyncEngine.shared.stopSync()
        }
    }

    public func setAmbientSensitivity(_ value: Double) {
        ambientSensitivity = value
        AmbientBrightnessSyncEngine.shared.sensitivity = value
    }

    private func propagateAmbientBrightness(_ builtinBrightness: Double) {
        let target = BrightnessSyncCalculator.computeTargetBrightness(
            builtinBrightness: builtinBrightness,
            sensitivity: ambientSensitivity
        )
        for model in displays where !model.isBuiltin && !model.isVirtual {
            setBrightness(model, target)
        }
    }

    public func setMediaKeys(_ enabled: Bool) {
        isMediaKeysOn = enabled
        if enabled {
            mediaKeysListener.startListening()
        } else {
            mediaKeysListener.stopListening()
        }
    }

    internal func handleMediaKey(_ action: MediaKeyAction) {
        switch action {
        case .brightnessUp:
            nudgeBrightness(by: MediaKeyConstants.brightnessStep)
        case .brightnessDown:
            nudgeBrightness(by: -MediaKeyConstants.brightnessStep)
        case .volumeUp, .volumeDown, .mute:
            break
        }
    }

    private func nudgeBrightness(by delta: Double) {
        guard let model = displays.first(where: { $0.isBuiltin }) ?? displays.first else { return }
        setBrightness(model, min(1.0, max(0.0, model.brightness + delta)))
    }

    public func toggleLaunchAtLogin() {
        isLaunchAtLoginOn = LaunchAtLoginController.shared.toggle()
    }

    public func toggleNotch(for item: DisplayItemModel) {
        let active = NotchOverlayManager.shared.toggleNotchOverlay(for: item.id)
        item.isNotchOverlayActive = active
    }

    public func togglePip(for displayID: CGDirectDisplayID) {
        cyclePipStream(
            isTargetActive: pipDisplayID == displayID,
            startAction: { !self.dispatcher.isVirtual(displayID: displayID) && self.dispatcher.startPip(displayID: displayID) },
            onStarted: {
                self.pipDisplayID = displayID
                self.pipWindowID = nil
            }
        )
    }

    public func toggleWindowPip(for windowID: CGWindowID) {
        cyclePipStream(
            isTargetActive: pipWindowID == windowID,
            startAction: { self.dispatcher.startWindowPip(windowID: windowID) },
            onStarted: {
                self.pipWindowID = windowID
                self.pipDisplayID = nil
            }
        )
    }

    private func cyclePipStream(
        isTargetActive: Bool,
        startAction: () -> Bool,
        onStarted: () -> Void
    ) {
        if isPipOn {
            dispatcher.stopPip()
            isPipOn = false
            pipDisplayID = nil
            pipWindowID = nil
            if isTargetActive {
                return
            }
        }
        if startAction() {
            isPipOn = true
            onStarted()
            dispatcher.setPipOpacity(CGFloat(pipOpacity))
            dispatcher.setPipClickThrough(isPipClickThrough)
        }
    }

    public func setPipOpacityLevel(_ value: Double) {
        pipOpacity = Double(PipConstants.clampedOpacity(CGFloat(value)))
        dispatcher.setPipOpacity(CGFloat(pipOpacity))
    }

    public func togglePipClickThrough() {
        isPipClickThrough.toggle()
        dispatcher.setPipClickThrough(isPipClickThrough)
    }

    // MARK: - Display Sync Groups
    public func linkDisplayToGroup(masterID: CGDirectDisplayID, slaveID: CGDirectDisplayID, brightnessOffset: Double = 0.0) {
        DisplayGroupManager.shared.linkSlave(masterID: masterID, slaveID: slaveID, brightnessOffset: brightnessOffset)
        refresh()
    }

    public func unlinkDisplayFromGroup(slaveID: CGDirectDisplayID) {
        DisplayGroupManager.shared.unlinkSlave(slaveID: slaveID)
        refresh()
    }

    public func updateGroupOffset(_ item: DisplayItemModel, offset: Double) {
        guard let masterID = item.syncGroupMasterID else { return }
        DisplayGroupManager.shared.linkSlave(masterID: masterID, slaveID: item.id, brightnessOffset: offset)
        item.syncBrightnessOffset = offset
    }
}
#endif
