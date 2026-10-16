#if os(macOS) && arch(arm64)
import AppKit
import SwiftUI
import Combine
import UniformTypeIdentifiers
import CoreGraphics

/// Identifiable chip descriptor of a live virtual display for UI lists
public struct VirtualDisplayChip: Identifiable, Equatable {
    public let id: CGDirectDisplayID
    public let name: String

    public init(id: CGDirectDisplayID, name: String) {
        self.id = id
        self.name = name
    }
}

/// Single UI-facing store: every mutation routes through DisplayCommandDispatcher (DRY)
@MainActor
public final class WorkspaceStore: ObservableObject {
    public static let shared = WorkspaceStore()

    @Published public private(set) var displays: [DisplayItemModel] = []
    @Published public internal(set) var presets: [DisplayPreset] = []
    @Published public private(set) var virtualDisplays: [VirtualDisplayChip] = []
    @Published public private(set) var isTrueToneSupported: Bool = false

    @Published public var selectedAspect: DisplayAspectPreset = .ratio16_9
    @Published public var selectedRefreshRate: Double = VirtualDisplayLimits.defaultRefreshRate
    @Published public var isHiDPIEnabled: Bool = true
    @Published public var isNightShiftOn: Bool = false
    @Published public var isTrueToneOn: Bool = false
    @Published public var isAmbientSyncOn: Bool = false
    @Published public var ambientSensitivity: Double = AutoBrightnessConstants.defaultSensitivity
    @Published public var isMediaKeysOn: Bool = false
    @Published public var isLaunchAtLoginOn: Bool = false
    @Published public var isPipOn: Bool = false
    @Published public var pipDisplayID: CGDirectDisplayID?
    @Published public var newPresetDraftName: String = ""
    @Published public var activeTooltipText: String?

    public let colorProfiles: [ICCProfileInfo]

    internal let dispatcher = DisplayCommandDispatcher.shared
    internal let mediaKeysListener = MediaKeysListener()

    // DDC I2C throttling tasks to prevent bus flooding during rapid slider motion
    private var brightnessDebounceTasks: [CGDirectDisplayID: Task<Void, Never>] = [:]
    private var volumeDebounceTasks: [CGDirectDisplayID: Task<Void, Never>] = [:]

    private init() {
        colorProfiles = dispatcher.availableColorProfiles()
        reloadPresets()
        isTrueToneSupported = NightShiftTrueToneBridge.shared.isTrueToneSupported
        isLaunchAtLoginOn = LaunchAtLoginController.shared.isEnabled
        mediaKeysListener.onAction = { [weak self] action in
            Task { @MainActor [weak self] in
                self?.handleMediaKey(action)
            }
        }
        refresh()
    }

    // MARK: - Refresh

    /// Re-enumerate displays and refresh live per-display state, preserving local slider values
    public func refresh() {
        var refreshed: [DisplayItemModel] = []
        for info in DisplayInventory.currentDisplays() {
            let model = displays.first(where: { $0.id == info.id }) ?? makeModel(from: info)
            model.isHDREnabled = dispatcher.isHDREnabled(displayID: info.id)
            model.is10BitActive = dispatcher.is10BitColorActive(displayID: info.id)
            model.isMirrored = DisplayMirrorController.isMirroring(info.id)
            model.isDisconnected = DisplayPowerStateController.shared.isDisconnected(displayID: info.id)
            model.capabilities = DisplayInventory.probeCapabilities(for: info.id)
            if !model.isBuiltin && !model.isVirtual {
                model.inputSource = dispatcher.getInputSource(displayID: info.id)
            }
            let modes = dispatcher.availableResolutions(for: info.id)
            model.availableResolutions = modes
            model.selectedResolutionId = modes.first(where: { $0.isCurrent })?.id

            // Group synchronization state
            if let group = DisplayGroupManager.shared.groupForMaster(displayID: info.id) {
                model.isGroupMaster = true
                model.syncGroupMasterID = nil
            } else if let group = DisplayGroupManager.shared.groupContaining(displayID: info.id) {
                model.isGroupMaster = false
                model.syncGroupMasterID = group.masterDisplayID
                model.syncBrightnessOffset = group.member(for: info.id)?.brightnessOffset ?? 0.0
            } else {
                model.isGroupMaster = false
                model.syncGroupMasterID = nil
                model.syncBrightnessOffset = 0.0
            }

            refreshed.append(model)
        }
        displays = refreshed
        virtualDisplays = dispatcher.virtualDisplayDescriptors().map { VirtualDisplayChip(id: $0.id, name: $0.name) }
        isPipOn = dispatcher.isPipActive()
    }

    private func makeModel(from info: DisplayInventoryInfo) -> DisplayItemModel {
        let brightness = dispatcher.getBrightness(displayID: info.id) ?? Float(DisplayItemModel.defaultBrightness)
        return DisplayItemModel(
            id: info.id,
            name: info.name,
            brightness: Double(brightness),
            isBuiltin: info.isBuiltin,
            isVirtual: dispatcher.isVirtual(displayID: info.id),
            isHiDPI: info.isHiDPI,
            pixelWidth: info.pixelWidth,
            pixelHeight: info.pixelHeight
        )
    }

    // MARK: - Per-Display Controls (Throttled for DDC/I2C Stability)

    public func setBrightness(_ item: DisplayItemModel, _ value: Double, immediate: Bool = false) {
        item.brightness = value

        // If this display is a group master, synchronously update linked slave models in UI
        if item.isGroupMaster, let group = DisplayGroupManager.shared.groupForMaster(displayID: item.id), group.isBrightnessSyncEnabled {
            for member in group.members {
                if let slaveModel = displays.first(where: { $0.id == member.displayID }) {
                    let target = DisplayGroup.calculateTargetLevel(masterLevel: value, offset: member.brightnessOffset)
                    slaveModel.brightness = target
                }
            }
        }

        if immediate {
            brightnessDebounceTasks[item.id]?.cancel()
            brightnessDebounceTasks.removeValue(forKey: item.id)
            _ = item.isGroupMaster
                ? dispatcher.setMasterBrightness(displayID: item.id, level: Float(value))
                : dispatcher.setBrightness(displayID: item.id, level: Float(value))
            return
        }

        brightnessDebounceTasks[item.id]?.cancel()
        brightnessDebounceTasks[item.id] = Task { @MainActor [weak self, id = item.id, isMaster = item.isGroupMaster] in
            try? await Task.sleep(nanoseconds: MediaKeyConstants.ddcDebounceNanoseconds)
            guard !Task.isCancelled, let self = self else { return }
            _ = isMaster
                ? self.dispatcher.setMasterBrightness(displayID: id, level: Float(value))
                : self.dispatcher.setBrightness(displayID: id, level: Float(value))
            self.brightnessDebounceTasks.removeValue(forKey: id)
        }
    }

    public func setVolume(_ item: DisplayItemModel, _ value: Double, immediate: Bool = false) {
        item.volume = value
        if item.isMuted && value > 0 {
            item.isMuted = false
            item.volumeBeforeMute = nil
        }

        // If this display is a group master, update slave models in UI
        if item.isGroupMaster, let group = DisplayGroupManager.shared.groupForMaster(displayID: item.id), group.varVolumeSyncEnabled {
            for member in group.members {
                if let slaveModel = displays.first(where: { $0.id == member.displayID }) {
                    let target = DisplayGroup.calculateTargetLevel(masterLevel: value, offset: member.volumeOffset)
                    slaveModel.volume = target
                }
            }
        }

        if immediate {
            volumeDebounceTasks[item.id]?.cancel()
            volumeDebounceTasks.removeValue(forKey: item.id)
            _ = item.isGroupMaster
                ? dispatcher.setMasterVolume(displayID: item.id, level: Float(value))
                : dispatcher.setVolume(displayID: item.id, level: Float(value))
            return
        }

        volumeDebounceTasks[item.id]?.cancel()
        volumeDebounceTasks[item.id] = Task { @MainActor [weak self, id = item.id, isMaster = item.isGroupMaster] in
            try? await Task.sleep(nanoseconds: MediaKeyConstants.ddcDebounceNanoseconds)
            guard !Task.isCancelled, let self = self else { return }
            _ = isMaster
                ? self.dispatcher.setMasterVolume(displayID: id, level: Float(value))
                : self.dispatcher.setVolume(displayID: id, level: Float(value))
            self.volumeDebounceTasks.removeValue(forKey: id)
        }
    }

    public func toggleMute(_ item: DisplayItemModel) {
        if item.isMuted {
            let restore = item.volumeBeforeMute ?? DisplayItemModel.defaultVolume
            item.isMuted = false
            item.volume = restore
            item.volumeBeforeMute = nil
            _ = dispatcher.setVolume(displayID: item.id, level: Float(restore))
        } else {
            item.volumeBeforeMute = item.volume
            item.isMuted = true
            item.volume = 0
            _ = dispatcher.setMuted(displayID: item.id, muted: true)
        }
    }

    public func toggleForceRGB(_ item: DisplayItemModel) {
        if item.isForceRGBActive {
            item.isForceRGBActive = false
            return
        }
        if dispatcher.forceRGB(service: io_service_t(item.id)) {
            item.isForceRGBActive = true
        }
    }

    public func toggleXDROverdrive(_ item: DisplayItemModel) {
        item.isXDROverdriveEnabled.toggle()
    }

    public func toggleHDR(_ item: DisplayItemModel) {
        let target = !item.isHDREnabled
        if dispatcher.setHDR(displayID: item.id, enabled: target) {
            item.isHDREnabled = target
        }
    }

    public func rotate(_ item: DisplayItemModel, to angle: DisplayRotationAngle) {
        if dispatcher.setRotation(displayID: item.id, angle: angle) {
            item.rotation = angle
        }
        refresh()
    }

    public func setMirror(_ item: DisplayItemModel, from source: CGDirectDisplayID?) {
        if let source {
            _ = dispatcher.setMirror(sourceID: source, targetID: item.id)
        } else {
            _ = dispatcher.disableMirror(displayID: item.id)
        }
        refresh()
    }

    public func togglePowerConnection(_ item: DisplayItemModel) {
        if item.isDisconnected {
            _ = dispatcher.reconnect(displayID: item.id)
        } else {
            _ = dispatcher.disconnect(displayID: item.id)
        }
        refresh()
    }

    public func applyColorProfile(_ item: DisplayItemModel, _ profile: ICCProfileInfo?) {
        guard let profile else {
            item.colorProfileName = nil
            return
        }
        if ColorProfileController.shared.setProfile(profile, for: item.id) {
            item.colorProfileName = profile.name
        }
    }

    public func setInputSource(_ item: DisplayItemModel, _ source: DDCInputSource) {
        if dispatcher.setInputSource(displayID: item.id, source: source) {
            item.inputSource = source
        }
    }

    public func setResolution(_ item: DisplayItemModel, mode: DisplayResolutionDescriptor) {
        if dispatcher.setResolution(displayID: item.id, width: mode.pointWidth, height: mode.pointHeight, isHiDPI: mode.isHiDPI) {
            item.selectedResolutionId = mode.id
            refresh()
        }
    }
}
#endif
