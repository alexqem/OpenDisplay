#if os(macOS) && arch(arm64)
import SwiftUI
import CoreGraphics

/// Presets section: apply, snapshot, delete, import/export JSON
public struct PresetsSectionView: View {
    @ObservedObject public var store: WorkspaceStore
    @State private var newPresetName: String = ""

    public init(store: WorkspaceStore) {
        self.store = store
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(store.presets) { preset in
                presetRow(preset)
            }

            HStack(spacing: 6) {
                TextField("Snapshot name", text: $newPresetName)
                    .textFieldStyle(.plain)
                    .font(.system(size: AtlasTheme.fontBodySmall, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(AtlasTheme.surfaceHeader)
                    .overlay(
                        Rectangle().stroke(AtlasTheme.borderMedium, lineWidth: AtlasTheme.borderWidth)
                    )

                AtlasIconButton(systemName: "plus.square.on.square") {
                    let name = newPresetName.isEmpty
                        ? "Snapshot \(store.presets.count)"
                        : newPresetName
                    store.saveCurrentStateAsPreset(named: name)
                    newPresetName = ""
                }

                AtlasIconButton(systemName: "tray.and.arrow.down") {
                    store.importPresets()
                }

                AtlasIconButton(systemName: "square.and.arrow.up") {
                    store.exportPresets()
                }
            }
        }
    }

    private func presetRow(_ preset: DisplayPreset) -> some View {
        HStack(spacing: 6) {
            Button {
                store.applyPreset(preset)
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: preset.icon)
                        .font(.system(size: AtlasTheme.fontCaptionMedium))
                    Text(preset.name)
                        .font(.system(size: AtlasTheme.fontCaptionMedium, weight: .semibold))
                        .lineLimit(1)
                }
                .foregroundColor(AtlasTheme.cobalt)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(AtlasTheme.surfaceCard)
                .overlay(
                    Rectangle().stroke(AtlasTheme.borderMedium, lineWidth: AtlasTheme.borderWidth)
                )
            }
            .buttonStyle(.plain)

            if !preset.isBuiltin {
                AtlasIconButton(systemName: "xmark") {
                    store.deletePreset(preset)
                }
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
            HStack(spacing: 6) {
                Picker("", selection: $store.selectedAspect) {
                    ForEach(DisplayAspectPreset.allCases, id: \.self) { preset in
                        Text(preset.rawValue).tag(preset)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .controlSize(.small)
                .frame(width: AtlasTheme.pickerWidth)

                Picker("", selection: $store.selectedRefreshRate) {
                    ForEach(VirtualDisplayLimits.standardRefreshRates, id: \.self) { rate in
                        Text("\(Int(rate)) Hz").tag(rate)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .controlSize(.small)
                .frame(width: AtlasTheme.pickerNarrowWidth)

                Text("HiDPI")
                    .font(.system(size: AtlasTheme.fontCaptionMedium, weight: .semibold))
                    .foregroundColor(AtlasTheme.textBody)
                Toggle("", isOn: $store.isHiDPIEnabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.mini)

                Spacer()

                Button {
                    store.createVirtualDisplay()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "plus.rectangle.on.rectangle")
                            .font(.system(size: AtlasTheme.fontCaptionMedium))
                        Text("Create")
                            .font(.system(size: AtlasTheme.fontCaptionMedium, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AtlasTheme.cobalt)
                    .overlay(
                        Rectangle().stroke(AtlasTheme.cobaltDark, lineWidth: AtlasTheme.borderWidth)
                    )
                }
                .buttonStyle(.plain)
            }

            if !store.virtualDisplays.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(store.virtualDisplays) { chip in
                            HStack(spacing: 4) {
                                Text(chip.name)
                                    .font(.system(size: AtlasTheme.fontCaptionMedium, weight: .semibold))
                                    .foregroundColor(AtlasTheme.cobalt)
                                    .lineLimit(1)
                                Button {
                                    store.removeVirtualDisplay(id: chip.id)
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(AtlasTheme.textMuted)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AtlasTheme.cobaltSofter)
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
        VStack(alignment: .leading, spacing: 10) {
            AtlasToggleRow(
                title: "Night Shift",
                isOn: Binding(
                    get: { store.isNightShiftOn },
                    set: { _ in store.toggleNightShift() }
                )
            )

            if store.isTrueToneSupported {
                AtlasToggleRow(
                    title: "True Tone",
                    isOn: Binding(
                        get: { store.isTrueToneOn },
                        set: { _ in store.toggleTrueTone() }
                    )
                )
            }

            AtlasToggleRow(
                title: "Ambient Sync",
                isOn: Binding(
                    get: { store.isAmbientSyncOn },
                    set: { store.setAmbientSync($0) }
                ),
                trailing: {
                    Slider(
                        value: Binding(
                            get: { store.ambientSensitivity },
                            set: { store.setAmbientSensitivity($0) }
                        ),
                        in: AutoBrightnessConstants.minSensitivity...AutoBrightnessConstants.maxSensitivity
                    )
                    .tint(AtlasTheme.cobaltSoft)
                    .frame(width: AtlasTheme.inlineSliderWidth)
                    .disabled(!store.isAmbientSyncOn)
                }
            )

            AtlasToggleRow(
                title: "Media Keys",
                isOn: Binding(
                    get: { store.isMediaKeysOn },
                    set: { store.setMediaKeys($0) }
                )
            )

            AtlasToggleRow(
                title: "Launch at Login",
                isOn: Binding(
                    get: { store.isLaunchAtLoginOn },
                    set: { _ in store.toggleLaunchAtLogin() }
                )
            )

            AtlasToggleRow(
                title: "PiP Stream",
                isOn: Binding(
                    get: { store.isPipOn },
                    set: { _ in
                        if let target = store.pipDisplayID ?? store.displays.first?.id {
                            store.togglePip(for: target)
                        }
                    }
                ),
                trailing: {
                    Picker("", selection: pipTargetBinding) {
                        ForEach(store.displays.filter { !$0.isVirtual }) { display in
                            Text(display.name).tag(display.id)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .controlSize(.small)
                    .frame(width: AtlasTheme.pickerWidth)
                }
            )
        }
    }

    private var pipTargetBinding: Binding<CGDirectDisplayID> {
        Binding(
            get: { store.pipDisplayID ?? store.displays.first(where: { !$0.isVirtual })?.id ?? 0 },
            set: { newTarget in
                if store.isPipOn {
                    store.togglePip(for: store.pipDisplayID ?? newTarget)
                    if !store.isPipOn {
                        store.togglePip(for: newTarget)
                    }
                } else if newTarget != 0 {
                    store.pipDisplayID = newTarget
                }
            }
        )
    }
}
#endif
