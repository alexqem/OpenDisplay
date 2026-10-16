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
                HStack(spacing: 5) {
                    Image(systemName: item.isAdvancedDrawerExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Color.secondary)

                    Text("Advanced Controls")
                        .font(.system(size: AtlasTheme.fontCaptionMedium, weight: .medium))
                        .foregroundStyle(Color.secondary)

                    Spacer()
                }
                .padding(.vertical, 2)
            }
            .buttonStyle(.plain)

            if item.isAdvancedDrawerExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    DisplayColorModeSectionView(item: item)

                    colorPillsAndProfileRow

                    // External display hardware controls: rotation, input source & power
                    if !item.isBuiltin && !item.isVirtual {
                        geometryAndInputRow
                        syncGroupRow
                    }
                }
                .padding(10)
                .background(Color.primary.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.controlRadius, style: .continuous))
            }
        }
    }

    // MARK: - Sub-Row 1: Color Switches & ICC Profile
    private var colorPillsAndProfileRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Switches row (only visible when at least one switch is applicable)
            if !item.isBuiltin && !item.isVirtual {
                HStack(spacing: 12) {
                    // Force RGB Switch (only relevant for external displays connected via HDMI/DP)
                    Toggle("Force RGB", isOn: Binding(
                        get: { item.isForceRGBActive },
                        set: { _ in store.toggleForceRGB(item) }
                    ))
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .font(.system(size: AtlasTheme.fontCaptionMedium))
                    .onHover { hovered in
                        store.activeTooltipText = hovered ? "Forces RGB 4:4:4 output on external HDMI/DP monitors experiencing pink or washed-out YCbCr colors." : nil
                    }

                    // External display HDR Switch (if supported by hardware)
                    if item.capabilities.supportsHDR {
                        Toggle("HDR", isOn: Binding(
                            get: { item.isHDREnabled },
                            set: { _ in store.toggleHDR(item) }
                        ))
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                        .font(.system(size: AtlasTheme.fontCaptionMedium))
                        .onHover { hovered in
                            store.activeTooltipText = hovered ? "Toggles High Dynamic Range mode on supported external HDR monitors." : nil
                        }
                    }

                    Spacer()
                }
            } else if item.isBuiltin {
                // Built-in displays on modern MacBooks support HDR (XDR) natively by default
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.accentColor)
                    Text("Native Liquid Retina XDR / HDR Display")
                        .font(.system(size: AtlasTheme.fontCaptionMedium, weight: .medium))
                        .foregroundStyle(Color.secondary)
                    Spacer()
                }
            }

            // ICC Color Profile Row with explicit Label
            HStack(spacing: 8) {
                Text("Color Profile:")
                    .font(.system(size: AtlasTheme.fontCaptionMedium, weight: .medium))
                    .foregroundStyle(Color.secondary)

                Spacer()

                Picker("", selection: Binding(
                    get: { item.colorProfileName ?? "Default" },
                    set: { (name: String) in
                        let match = store.colorProfiles.first { $0.name == name }
                        if let prof = match {
                            store.applyColorProfile(item, prof)
                        }
                    }
                )) {
                    Text("Default").tag("Default")
                    ForEach(store.colorProfiles) { prof in
                        Text(prof.name).tag(prof.name)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .controlSize(.small)
                .frame(maxWidth: 160)
            }
            .onHover { hovered in
                store.activeTooltipText = hovered ? "Applies a ColorSync ICC display profile for calibrated color reproduction." : nil
            }
        }
    }

    // MARK: - Sub-Row 2: Rotation, Input Source & Hardware Standby
    private var geometryAndInputRow: some View {
        HStack(spacing: 8) {
            Text("Rotation:")
                .font(.system(size: AtlasTheme.fontCaptionMedium, weight: .medium))
                .foregroundStyle(Color.secondary)

            // Rotation Picker
            Picker("", selection: Binding(
                get: { item.rotation },
                set: { (rot: DisplayRotationAngle) in
                    store.rotate(item, to: rot)
                }
            )) {
                ForEach(DisplayRotationAngle.allCases, id: \.self) { rot in
                    Text("\(rot.rawValue)°").tag(rot)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .controlSize(.small)
            .frame(width: 68)

            // DDC Video Input Source Picker (external monitors only)
            if item.capabilities.supportsDDC {
                Picker("", selection: Binding(
                    get: { item.inputSource ?? .displayPort1 },
                    set: { (src: DDCInputSource) in
                        store.setInputSource(item, src)
                    }
                )) {
                    ForEach(DDCInputSource.allCases, id: \.self) { src in
                        Text(src.label).tag(src)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .controlSize(.small)
                .frame(width: 90)
            }

            Spacer()

            // Power Standby Button (external monitors only)
            Button(action: {
                store.togglePowerConnection(item)
            }) {
                Image(systemName: "power")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.secondary)
                    .frame(width: 24, height: 24)
                    .background(Color.primary.opacity(0.06))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Toggle monitor connection or sleep state")
        }
    }

    // MARK: - Sub-Row 3: Master-Slave Display Synchronization
    private var syncGroupRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "link")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.secondary)

            Text("Link:")
                .font(.system(size: AtlasTheme.fontCaptionMedium, weight: .medium))
                .foregroundStyle(Color.secondary)

            let otherDisplays = store.displays.filter { $0.id != item.id }

            Picker("", selection: Binding(
                get: { item.syncGroupMasterID },
                set: { (newMasterID: CGDirectDisplayID?) in
                    if let masterID = newMasterID {
                        store.linkDisplayToGroup(masterID: masterID, slaveID: item.id)
                    } else {
                        store.unlinkDisplayFromGroup(slaveID: item.id)
                    }
                }
            )) {
                Text("None").tag(nil as CGDirectDisplayID?)
                ForEach(otherDisplays) { other in
                    Text(other.name).tag(other.id as CGDirectDisplayID?)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .controlSize(.small)
            .frame(maxWidth: 120)

            if item.syncGroupMasterID != nil {
                Slider(
                    value: Binding(
                        get: { item.syncBrightnessOffset },
                        set: { (newOffset: Double) in
                            if let masterID = item.syncGroupMasterID {
                                store.linkDisplayToGroup(masterID: masterID, slaveID: item.id, brightnessOffset: newOffset)
                            }
                        }
                    ),
                    in: -0.5...0.5
                )
                .controlSize(.small)

                Text(String(format: "%+.0f%%", item.syncBrightnessOffset * 100))
                    .font(.system(size: AtlasTheme.fontCaptionSmall, weight: .medium))
                    .foregroundStyle(Color.secondary)
                    .frame(width: 34, alignment: .trailing)
            }
        }
    }
}
#endif
