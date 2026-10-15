#if os(macOS) && arch(arm64)
import SwiftUI
import AppKit
import CoreGraphics

/// Clean, progressive-disclosure Display Card View following Atlas / TypeUI and SwiftUI Pro rules
public struct DisplayCardView: View {
    @ObservedObject public var item: DisplayItemModel
    @ObservedObject private var store = WorkspaceStore.shared

    @State private var isEditingBrightness: Bool = false
    @State private var brightnessInputText: String = ""

    public init(item: DisplayItemModel) {
        self.item = item
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            headerRow
            hardwareStatusBadgeRow
            luminanceRow
            volumeRow

            AtlasDivider()

            resolutionModeRow

            // Progressive Disclosure Accordion: Advanced Hardware & Color Drawer
            advancedDrawerSection

            if item.isDisconnected {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: AtlasTheme.fontCaptionMedium))
                    Text("SOFTWARE DISCONNECTED (BLANKED)")
                        .font(.system(size: AtlasTheme.fontCaptionSmall, weight: .bold, design: .monospaced))
                }
                .foregroundStyle(AtlasTheme.warningOrange)
                .padding(.top, 2)
            }
        }
        .padding(14)
        .background(AtlasTheme.surfaceCard)
        .overlay(
            Rectangle().stroke(
                item.isDisconnected ? AtlasTheme.warningOrange : AtlasTheme.borderDefault,
                lineWidth: AtlasTheme.borderWidth
            )
        )
    }

    // MARK: - Header
    private var headerRow: some View {
        HStack(spacing: 8) {
            Image(systemName: headerIcon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AtlasTheme.cobalt)

            Text(item.name)
                .font(.system(size: AtlasTheme.fontBodyMedium, weight: .bold))
                .foregroundStyle(AtlasTheme.textPrimary)
                .lineLimit(1)

            if item.isVirtual {
                AtlasBadge("VIRTUAL", style: .lime)
            }
            if item.isMirrored {
                AtlasBadge("MIRRORED", style: .brand)
            }
            if item.isHiDPI {
                AtlasBadge("HiDPI", style: .muted)
            }

            Spacer()

            Text("ID: \(item.id)")
                .font(.system(size: AtlasTheme.fontCaptionSmall, weight: .semibold, design: .monospaced))
                .foregroundStyle(AtlasTheme.textMuted)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(AtlasTheme.cobaltSofter)
                .clipShape(Capsule())
        }
    }

    private var headerIcon: String {
        if item.isVirtual { return "rectangle.on.rectangle" }
        return item.isBuiltin ? "laptopcomputer" : "display"
    }

    // MARK: - Hardware Status Strip
    private var hardwareStatusBadgeRow: some View {
        HStack(spacing: 6) {
            if item.isBuiltin {
                AtlasBadge("APPLE DISPLAYSERVICES", style: .brand)
            } else if item.isVirtual {
                AtlasBadge("COREDISPLAY VIRTUAL", style: .lime)
            } else if item.capabilities.isHDMI {
                AtlasBadge("HDMI-SINK", style: .success)
            } else if item.capabilities.supportsDDC {
                AtlasBadge("DDC READY", style: .success)
            } else {
                AtlasBadge("GAMMA LUT ONLY", style: .warning)
            }

            if item.capabilities.supports10BitDeepColor {
                AtlasBadge("10-BIT", style: .brand)
            }

            if let addr = item.capabilities.physicalAddress {
                AtlasBadge("CEC: \(addr)", style: .muted)
            }

            Spacer()
        }
    }

    // MARK: - Luminance Slider & Steppers
    private var luminanceRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("LUMINANCE")
                    .font(.system(size: AtlasTheme.fontCaptionSmall, weight: .bold, design: .monospaced))
                    .foregroundStyle(AtlasTheme.textBody)

                Spacer()

                if isEditingBrightness {
                    TextField("", text: $brightnessInputText, onCommit: commitBrightnessInput)
                        .textFieldStyle(.plain)
                        .font(.system(size: AtlasTheme.fontBodySmall, weight: .bold, design: .monospaced))
                        .foregroundStyle(AtlasTheme.cobalt)
                        .frame(width: 44)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(AtlasTheme.surfaceHeader)
                        .overlay(
                            Rectangle().stroke(AtlasTheme.cobalt, lineWidth: AtlasTheme.borderWidth)
                        )
                } else {
                    Button(action: {
                        brightnessInputText = "\(Int(item.brightness * 100))"
                        isEditingBrightness = true
                    }) {
                        Text("\(Int(item.brightness * 100))%")
                            .font(.system(size: AtlasTheme.fontBodySmall, weight: .bold, design: .monospaced))
                            .foregroundStyle(AtlasTheme.cobalt)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(AtlasTheme.cobaltSofter)
                    }
                    .buttonStyle(.plain)
                    .help("Click to enter exact percentage")
                }
            }

            HStack(spacing: 6) {
                AtlasIconButton(systemName: "minus") {
                    let next = max(0.0, item.brightness - MediaKeyConstants.brightnessStep)
                    store.setBrightness(item, next, immediate: true)
                }
                .disabled(item.isDisconnected)

                Slider(
                    value: Binding(
                        get: { item.brightness },
                        set: { store.setBrightness(item, $0, immediate: false) }
                    ),
                    in: 0...1
                )
                .tint(AtlasTheme.cobalt)
                .disabled(item.isDisconnected)

                AtlasIconButton(systemName: "plus") {
                    let next = min(1.0, item.brightness + MediaKeyConstants.brightnessStep)
                    store.setBrightness(item, next, immediate: true)
                }
                .disabled(item.isDisconnected)

                // Optional XDR Overdrive Pill
                if !item.isBuiltin && !item.isVirtual {
                    Button(action: { store.toggleXDROverdrive(item) }) {
                        Text("XDR")
                            .font(.system(size: AtlasTheme.fontCaptionSmall, weight: .bold, design: .monospaced))
                            .foregroundStyle(item.isXDROverdriveEnabled ? AtlasTheme.cobaltDark : AtlasTheme.textMuted)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(item.isXDROverdriveEnabled ? AtlasTheme.electricLime : AtlasTheme.surfaceCard)
                            .overlay(
                                Rectangle().stroke(item.isXDROverdriveEnabled ? AtlasTheme.electricLime : AtlasTheme.borderMedium, lineWidth: AtlasTheme.borderWidth)
                            )
                    }
                    .buttonStyle(.plain)
                    .help("XDR / Hardware Brightness Overdrive (Boost peak nits)")
                }
            }
        }
    }

    private func commitBrightnessInput() {
        isEditingBrightness = false
        if let val = Double(brightnessInputText) {
            let clamped = max(0.0, min(100.0, val)) / 100.0
            store.setBrightness(item, clamped, immediate: true)
        }
    }

    // MARK: - Audio Volume & Mute Row
    @ViewBuilder
    private var volumeRow: some View {
        if !item.isBuiltin && !item.isVirtual && item.capabilities.supportsBasicAudio {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("AUDIO (DDC 0x62)")
                        .font(.system(size: AtlasTheme.fontCaptionSmall, weight: .bold, design: .monospaced))
                        .foregroundStyle(AtlasTheme.textBody)

                    Spacer()

                    Text(item.isMuted ? "MUTED" : "\(Int(item.volume * 100))%")
                        .font(.system(size: AtlasTheme.fontCaptionSmall, weight: .bold, design: .monospaced))
                        .foregroundStyle(item.isMuted ? AtlasTheme.warningOrange : AtlasTheme.textMuted)
                }

                HStack(spacing: 6) {
                    AtlasIconButton(systemName: item.isMuted ? "speaker.slash.fill" : "speaker.wave.2") {
                        store.toggleMute(item)
                    }
                    .disabled(item.isDisconnected)

                    Slider(
                        value: Binding(
                            get: { item.volume },
                            set: { store.setVolume(item, $0, immediate: false) }
                        ),
                        in: 0...1
                    )
                    .tint(AtlasTheme.cobalt)
                    .disabled(item.isDisconnected || item.isMuted)
                }
            }
        }
    }

    // MARK: - Resolution & HiDPI Selector (Uses Cached Sub-Collections)
    private var resolutionModeRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "aspectratio")
                .font(.system(size: AtlasTheme.fontCaptionMedium))
                .foregroundStyle(AtlasTheme.cobalt)

            Text("Mode:")
                .font(.system(size: AtlasTheme.fontCaptionMedium, weight: .bold))
                .foregroundStyle(AtlasTheme.textPrimary)

            Picker("", selection: resolutionBinding) {
                if item.availableResolutions.isEmpty {
                    Text("System Default").tag("" as String?)
                } else {
                    if !item.recommendedResolutions.isEmpty {
                        Section(header: Text("RECOMMENDED")) {
                            ForEach(item.recommendedResolutions) { mode in
                                Text("★ \(mode.userLabel)").tag(mode.id as String?)
                            }
                        }
                    }

                    if !item.otherResolutions.isEmpty {
                        Section(header: Text("SCALED / LOW RES")) {
                            ForEach(item.otherResolutions) { mode in
                                Text("\(mode.userLabel) (\(mode.tier.rawValue))").tag(mode.id as String?)
                            }
                        }
                    }
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .controlSize(.small)
            .frame(maxWidth: .infinity)

            if let cur = item.availableResolutions.first(where: { $0.id == item.selectedResolutionId }) {
                if cur.isRecommended {
                    AtlasBadge("RECOMMENDED", style: .lime)
                } else if cur.isHiDPI {
                    AtlasBadge("HiDPI", style: .brand)
                } else {
                    AtlasBadge("LOW-RES", style: .muted)
                }
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Progressive Disclosure: Advanced Drawer
    private var advancedDrawerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                withAnimation(.easeInOut(duration: AtlasTheme.switchAnimationDuration)) {
                    item.isAdvancedDrawerExpanded.toggle()
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: item.isAdvancedDrawerExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9, weight: .bold))
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
                }
                .padding(10)
                .background(AtlasTheme.surfaceHeader)
                .overlay(
                    Rectangle().stroke(AtlasTheme.borderMedium, lineWidth: AtlasTheme.borderWidth)
                )
            }
        }
    }

    // MARK: - Advanced Drawer Sub-Row 1: Color Switches & ICC Profile
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

    // MARK: - Advanced Drawer Sub-Row 2: Geometry, Input Source & Power
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
                .frame(width: 110)
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

    private var resolutionBinding: Binding<String?> {
        Binding(
            get: { item.selectedResolutionId },
            set: { modeId in
                guard let modeId,
                      let mode = item.availableResolutions.first(where: { $0.id == modeId }) else { return }
                store.setResolution(item, mode: mode)
            }
        )
    }
}
#endif
