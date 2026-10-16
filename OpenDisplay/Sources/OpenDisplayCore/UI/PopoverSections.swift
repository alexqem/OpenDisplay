#if os(macOS) && arch(arm64)
import SwiftUI
import CoreGraphics

/// Presets section: apply, snapshot, delete, import/export JSON
public struct PresetsSectionView: View {
    @ObservedObject public var store: WorkspaceStore

    public init(store: WorkspaceStore) {
        self.store = store
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(store.presets) { preset in
                presetRow(preset)
            }

            HStack(spacing: 6) {
                TextField(
                    "Snapshot name",
                    text: Binding(
                        get: { store.newPresetDraftName },
                        set: { store.newPresetDraftName = $0 }
                    )
                )
                .textFieldStyle(.roundedBorder)
                .font(.system(size: AtlasTheme.fontBodySmall))

                Button {
                    let name = store.newPresetDraftName.isEmpty
                        ? "Snapshot \(store.presets.count)"
                        : store.newPresetDraftName
                    store.saveCurrentStateAsPreset(named: name)
                    store.newPresetDraftName = ""
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .medium))
                }
                .controlSize(.small)
                .help("Save current state as preset")

                Button {
                    store.importPresets()
                } label: {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 11, weight: .medium))
                }
                .controlSize(.small)
                .help("Import presets")

                Button {
                    store.exportPresets()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 11, weight: .medium))
                }
                .controlSize(.small)
                .help("Export presets")
            }
        }
    }

    private func presetRow(_ preset: DisplayPreset) -> some View {
        HStack(spacing: 6) {
            Button {
                store.applyPreset(preset)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: preset.icon)
                        .font(.system(size: 11))
                    Text(preset.name)
                        .font(.system(size: AtlasTheme.fontCaptionMedium, weight: .medium))
                        .lineLimit(1)
                }
                .foregroundStyle(Color.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.primary.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.controlRadius, style: .continuous))
            }
            .buttonStyle(.plain)

            if !preset.isBuiltin {
                Button {
                    store.deletePreset(preset)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(Color.secondary)
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }
}

/// Virtual display section: generator (aspect / refresh / HiDPI) and live chips with teardown
public struct VirtualSectionView: View {
    @ObservedObject public var store: WorkspaceStore

    public init(store: WorkspaceStore) {
        self.store = store
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Picker("", selection: $store.selectedAspect) {
                    ForEach(DisplayAspectPreset.allCases, id: \.self) { preset in
                        Text(preset.rawValue).tag(preset)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .controlSize(.small)
                .frame(width: 90)

                Picker("", selection: $store.selectedRefreshRate) {
                    ForEach(VirtualDisplayLimits.standardRefreshRates, id: \.self) { rate in
                        Text("\(Int(rate)) Hz").tag(rate)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .controlSize(.small)
                .frame(width: 76)

                Toggle("HiDPI", isOn: $store.isHiDPIEnabled)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .font(.system(size: AtlasTheme.fontCaptionMedium))

                Spacer()

                Button {
                    store.createVirtualDisplay()
                } label: {
                    Text("Add")
                        .font(.system(size: 11, weight: .medium))
                }
                .controlSize(.small)
            }

            if !store.virtualDisplays.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(store.virtualDisplays) { chip in
                            HStack(spacing: 6) {
                                Text(chip.name)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(Color.primary)
                                    .lineLimit(1)
                                Button {
                                    store.removeVirtualDisplay(id: chip.id)
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundStyle(Color.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.primary.opacity(0.06))
                            .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }
}

/// System section: Night Shift, True Tone, Ambient Sync, Media Keys, Launch at Login, PiP
public struct SystemSectionView: View {
    @ObservedObject public var store: WorkspaceStore

    public init(store: WorkspaceStore) {
        self.store = store
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AtlasToggleRow(
                title: "Night Shift",
                helpText: "Shifts display colors to the warmer end of the spectrum after dark to reduce eye strain.",
                isOn: Binding(
                    get: { store.isNightShiftOn },
                    set: { _ in store.toggleNightShift() }
                )
            )

            if store.isTrueToneSupported {
                AtlasToggleRow(
                    title: "True Tone",
                    helpText: "Automatically adapts display color temperature based on ambient lighting conditions.",
                    isOn: Binding(
                        get: { store.isTrueToneOn },
                        set: { _ in store.toggleTrueTone() }
                    )
                )
            }

            AtlasToggleRow(
                title: "Ambient Sync",
                helpText: "Synchronizes brightness of connected external displays with the Mac built-in ambient light sensor.",
                isOn: Binding(
                    get: { store.isAmbientSyncOn },
                    set: { store.setAmbientSync($0) }
                )
            )

            AtlasToggleRow(
                title: "Keyboard Brightness Keys",
                helpText: "Allows controlling external monitor brightness using Apple keyboard F1/F2 keys.",
                isOn: Binding(
                    get: { store.isMediaKeysOn },
                    set: { store.setMediaKeys($0) }
                )
            )

            AtlasToggleRow(
                title: "Launch at Login",
                helpText: "Starts OpenDisplay automatically in background when logging into macOS.",
                isOn: Binding(
                    get: { store.isLaunchAtLoginOn },
                    set: { _ in store.toggleLaunchAtLogin() }
                )
            )

            // PiP Stream Toggle
            if #available(macOS 12.3, *) {
                AtlasToggleRow(
                    title: "Picture-in-Picture Stream",
                    helpText: "Mirrors a real-time floating preview window of a display via ScreenCaptureKit.",
                    isOn: Binding(
                        get: { store.isPipOn },
                        set: { _ in
                            if let first = store.displays.first {
                                store.togglePip(for: first.id)
                            }
                        }
                    )
                )
            }
        }
    }
}
#endif
