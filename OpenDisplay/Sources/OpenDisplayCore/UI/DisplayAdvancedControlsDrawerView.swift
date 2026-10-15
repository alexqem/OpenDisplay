#if os(macOS) && arch(arm64)
import SwiftUI
import CoreGraphics

/// Progressive disclosure drawer containing color adjustments, geometry, input selector, power control, and group sync
public struct DisplayAdvancedControlsDrawerView: View {
    @ObservedObject public var item: DisplayItemModel
    @ObservedObject private var store = WorkspaceStore.shared

    public init(item: DisplayItemModel) {
        self.item = item
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                withAnimation(.easeInOut(duration: AtlasTheme.switchAnimationDuration)) {
                    item.isAdvancedDrawerExpanded.toggle()
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: item.isAdvancedDrawerExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: AtlasTheme.fontChevronSmall, weight: .bold))
                        .foregroundStyle(AtlasTheme.cobalt)

                    Text(item.isAdvancedDrawerExpanded ? "HIDE DETAILS" : "HARDWARE & COLOR CONTROLS")
                        .font(.system(size: AtlasTheme.fontCaptionSmall, weight: .bold, design: .monospaced))
                        .foregroundStyle(AtlasTheme.cobalt)

                    Spacer()
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)

            if item.isAdvancedDrawerExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    colorPillsAndProfileRow
                    geometryAndInputRow
                    syncGroupRow
                }
                .padding(AtlasTheme.drawerPadding)
                .background(AtlasTheme.surfaceHeader)
                .overlay(
                    Rectangle().stroke(AtlasTheme.borderMedium, lineWidth: AtlasTheme.borderWidth)
                )
            }
        }
    }

    // MARK: - Sub-Row 1: Color Switches & ICC Profile
    private var colorPillsAndProfileRow: some View {
        HStack(spacing: 8) {
            // Force RGB Switch
            HStack(spacing: 5) {
                AtlasSwitch(
                    isOn: Binding(
                        get: { item.isForceRGBActive },
                        set: { _ in store.toggleForceRGB(item) }
                    ),
                    activeColor: AtlasTheme.cobalt
                )
                Text("RGB 4:4:4")
                    .font(.system(size: AtlasTheme.fontCaptionMedium, weight: .semibold))
                    .foregroundStyle(item.isForceRGBActive ? AtlasTheme.textPrimary : AtlasTheme.textMuted)
            }

            // HDR Switch
            HStack(spacing: 5) {
                AtlasSwitch(
                    isOn: Binding(
                        get: { item.isHDREnabled },
                        set: { _ in store.toggleHDR(item) }
                    ),
                    activeColor: AtlasTheme.successGreen
                )
                Text("HDR")
                    .font(.system(size: AtlasTheme.fontCaptionMedium, weight: .semibold))
                    .foregroundStyle(item.isHDREnabled ? AtlasTheme.textPrimary : AtlasTheme.textMuted)
            }

            Spacer()

            Picker("", selection: profileBinding) {
                Text("ICC: Auto").tag("")
                ForEach(store.colorProfiles) { profile in
                    Text(profile.name).tag(profile.name)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .controlSize(.small)
            .frame(width: AtlasTheme.pickerWidth)
        }
    }

    // MARK: - Sub-Row 2: Geometry, Input Source & Power
    private var geometryAndInputRow: some View {
        HStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "rotate.right")
                    .font(.system(size: AtlasTheme.fontCaptionMedium))
                    .foregroundStyle(AtlasTheme.textMuted)

                Picker("", selection: rotationBinding) {
                    ForEach(DisplayRotationAngle.allCases, id: \.self) { angle in
                        Text("\(angle.rawValue)°").tag(angle)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .controlSize(.small)
                .frame(width: AtlasTheme.pickerNarrowWidth)
            }

            HStack(spacing: 4) {
                Image(systemName: "rectangle.2.swap")
                    .font(.system(size: AtlasTheme.fontCaptionMedium))
                    .foregroundStyle(AtlasTheme.textMuted)

                Picker("", selection: mirrorBinding) {
                    Text("Mirror: Off").tag(CGDirectDisplayID(0))
                    ForEach(store.displays.filter { $0.id != item.id }) { other in
                        Text(other.name).tag(other.id)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .controlSize(.small)
                .frame(width: AtlasTheme.pickerMirrorWidth)
            }

            if !item.isBuiltin && !item.isVirtual {
                HStack(spacing: 4) {
                    Image(systemName: "cable.connector")
                        .font(.system(size: AtlasTheme.fontCaptionMedium))
                        .foregroundStyle(AtlasTheme.textMuted)

                    Picker("", selection: inputSourceBinding) {
                        Text("Input: Auto").tag(nil as DDCInputSource?)
                        ForEach(DDCInputSource.allCases) { src in
                            Text(src.label).tag(src as DDCInputSource?)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .controlSize(.small)
                    .frame(width: AtlasTheme.pickerNarrowWidth)
                }
            }

            Spacer()

            AtlasIconButton(
                systemName: item.isDisconnected ? "arrow.clockwise" : "bolt.slash",
                action: { store.togglePowerConnection(item) }
            )
            .help(item.isDisconnected ? "Reconnect display" : "Blank/disconnect display")
        }
    }

    // MARK: - Sub-Row 3: Display Sync Group & Calibration Offset
    private var syncGroupRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "link")
                .font(.system(size: AtlasTheme.fontCaptionMedium))
                .foregroundStyle(AtlasTheme.textMuted)

            Picker("", selection: groupMasterBinding) {
                Text("Sync: Independent").tag(CGDirectDisplayID(0))
                ForEach(store.displays.filter { $0.id != item.id }) { potentialMaster in
                    Text("Follow: \(potentialMaster.name)").tag(potentialMaster.id)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .controlSize(.small)
            .frame(width: AtlasTheme.pickerMirrorWidth)

            if item.syncGroupMasterID != nil {
                HStack(spacing: 4) {
                    Text("Offset:")
                        .font(.system(size: AtlasTheme.fontCaptionSmall, design: .monospaced))
                        .foregroundStyle(AtlasTheme.textMuted)

                    Picker("", selection: groupOffsetBinding) {
                        Text("-20%").tag(-0.20)
                        Text("-10%").tag(-0.10)
                        Text("0%").tag(0.0)
                        Text("+10%").tag(0.10)
                        Text("+20%").tag(0.20)
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .controlSize(.small)
                    .frame(width: AtlasTheme.pickerNarrowWidth)
                }
            }

            Spacer()
        }
    }

    // MARK: - Bindings
    private var rotationBinding: Binding<DisplayRotationAngle> {
        Binding(
            get: { item.rotation },
            set: { store.rotate(item, to: $0) }
        )
    }

    private var mirrorBinding: Binding<CGDirectDisplayID> {
        Binding(
            get: { DisplayMirrorController.mirrorSource(for: item.id) ?? MirrorConstants.nullDirectDisplay },
            set: { store.setMirror(item, from: $0 == MirrorConstants.nullDirectDisplay ? nil : $0) }
        )
    }

    private var profileBinding: Binding<String> {
        Binding(
            get: { item.colorProfileName ?? "" },
            set: { name in
                store.applyColorProfile(item, store.colorProfiles.first(where: { $0.name == name }))
            }
        )
    }

    private var inputSourceBinding: Binding<DDCInputSource?> {
        Binding(
            get: { item.inputSource },
            set: { source in
                if let source {
                    store.setInputSource(item, source)
                }
            }
        )
    }

    private var groupMasterBinding: Binding<CGDirectDisplayID> {
        Binding(
            get: { item.syncGroupMasterID ?? CGDirectDisplayID(0) },
            set: { newMasterID in
                if newMasterID == 0 {
                    store.unlinkDisplayFromGroup(slaveID: item.id)
                } else {
                    store.linkDisplayToGroup(masterID: newMasterID, slaveID: item.id, brightnessOffset: item.syncBrightnessOffset)
                }
            }
        )
    }

    private var groupOffsetBinding: Binding<Double> {
        Binding(
            get: { item.syncBrightnessOffset },
            set: { newOffset in
                store.updateGroupOffset(item, offset: newOffset)
            }
        )
    }
}
#endif
