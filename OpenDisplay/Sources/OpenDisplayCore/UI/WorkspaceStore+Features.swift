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
        activeTooltipText = "Toggling Night Shift..."
        if dispatcher.setNightShift(enabled: target) {
            isNightShiftOn = target
            activeTooltipText = target ? "Night Shift enabled" : "Night Shift disabled"
        } else {
            activeTooltipText = "Failed to toggle Night Shift (CoreBrightness unavailable)"
        }
    }

    public func toggleTrueTone() {
        let target = !isTrueToneOn
        activeTooltipText = "Toggling True Tone..."
        if dispatcher.setTrueTone(enabled: target) {
            isTrueToneOn = target
            activeTooltipText = target ? "True Tone enabled" : "True Tone disabled"
        } else {
            activeTooltipText = "Failed to toggle True Tone"
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

    // MARK: - HiDPI Toggle (BetterDisplay "Hi Resolution" parity)

    /// Toggle HiDPI rendering: switches to the largest HiDPI buffer, or back to the
    /// matching 1x mode (cast displays: 1344x756@1x <-> 960x540@2x with 1080p stream)
    public func toggleHiDPI(for item: DisplayItemModel) {
        let modes = item.availableResolutions
        guard !modes.isEmpty else { return }

        let target: DisplayResolutionDescriptor?
        if item.isHiDPI {
            guard let current = modes.first(where: { $0.isCurrent }) ?? modes.first(where: { $0.id == item.selectedResolutionId }) else {
                return
            }
            target = ResolutionClassifier.bestLoDPIMode(current: current, in: modes)
        } else {
            target = ResolutionClassifier.bestHiDPIMode(in: modes)
        }

        guard let mode = target else {
            activeTooltipText = "No HiDPI alternative available for this display"
            return
        }
        setResolution(item, mode: mode)
    }

    // MARK: - Ultra Sharp Cast (Virtual Mirror Master)

    /// Toggle the virtual resolution master for a cast display
    public func toggleCastUltraSharp(for item: DisplayItemModel, tier: CastVirtualResolutionController.SharpnessTier) {
        let controller = CastVirtualResolutionController.shared
        if controller.isActive(for: item.id) {
            if controller.tier == tier {
                if controller.disable() {
                    activeTooltipText = "Ultra Sharp disabled - AirPlay returned to default timing"
                }
            } else {
                // Switching sharpness tiers: tear down existing master and bring up new tier
                _ = controller.disable()
                if controller.enable(castID: item.id, tier: tier) {
                    activeTooltipText = "Switched to Ultra Sharp \(tier.label)"
                } else {
                    activeTooltipText = "Failed to switch to Ultra Sharp \(tier.label)"
                }
            }
        } else {
            if controller.enable(castID: item.id, tier: tier) {
                activeTooltipText = "Ultra Sharp \(tier.label) active - UI runs at \(tier.pixelWidth / 2)x\(tier.pixelHeight / 2) points"
            } else {
                activeTooltipText = "Failed to enable Ultra Sharp for \(item.name)"
            }
        }
        refresh()
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
