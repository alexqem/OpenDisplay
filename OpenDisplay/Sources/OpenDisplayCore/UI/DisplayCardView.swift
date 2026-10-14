#if os(macOS) && arch(arm64)
import SwiftUI
import AppKit
import CoreGraphics

/// Per-display control card: luminance, volume, color pills, detected HDMI capabilities, and geometry actions
/// Styled with Swiss Neo-Brutalist rigor (Atlas/TypeUI)
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
            detectedHdmiCapabilitiesRow
            luminanceRow
            volumeRow

            AtlasDivider()

            colorPillsAndProfileRow
            geometryActionRow

            if item.isDisconnected {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: AtlasTheme.fontCaptionMedium))
                    Text("SOFTWARE DISCONNECTED (BLANKED)")
                        .font(.system(size: AtlasTheme.fontCaptionSmall, weight: .bold, design: .monospaced))
                }
                .foregroundColor(AtlasTheme.warningOrange)
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
                .foregroundColor(AtlasTheme.cobalt)

            Text(item.name)
                .font(.system(size: AtlasTheme.fontBodyMedium, weight: .bold))
                .foregroundColor(AtlasTheme.textPrimary)
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
                .foregroundColor(AtlasTheme.textMuted)
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

    // MARK: - Channel / Protocol Status
    private var hardwareStatusBadgeRow: some View {
        HStack(spacing: 6) {
            if item.isBuiltin {
                AtlasBadge("APPLE DISPLAYSERVICES", style: .brand)
            } else if item.isVirtual {
                AtlasBadge("COREDISPLAY VIRTUAL", style: .lime)
            } else if item.capabilities.isHDMI {
                AtlasBadge("HDMI-SINK DETECTED", style: .success)
            } else if IOAVServiceMatcher.service(for: item.id) != nil {
                AtlasBadge("DISPLAYPORT / DDC READY", style: .success)
            } else {
                AtlasBadge("GAMMA LUT ONLY", style: .warning)
            }

            if let addr = item.capabilities.physicalAddress {
                AtlasBadge("CEC: \(addr)", style: .muted)
            }

            Spacer()
        }
    }

    // MARK: - Autodetected HDMI / EDID Capabilities Strip
    @ViewBuilder
    private var detectedHdmiCapabilitiesRow: some View {
        if !item.isBuiltin && !item.isVirtual {
            HStack(spacing: 6) {
                Text("CAPS:")
                    .font(.system(size: AtlasTheme.fontCaptionSmall, weight: .bold, design: .monospaced))
                    .foregroundColor(AtlasTheme.textMuted)

                if item.capabilities.supportsYCbCr444 || item.capabilities.supportsYCbCr422 {
                    AtlasBadge("YUV/YCbCr", style: .brand)
                }
                if item.capabilities.supportsBasicAudio {
                    AtlasBadge("AUDIO", style: .muted)
                }
                if item.capabilities.supports10BitDeepColor {
                    AtlasBadge("10-BIT", style: .success)
                }
                if item.capabilities.supportsHDR {
                    AtlasBadge("HDR10", style: .lime)
                }
                Spacer()
            }
            .padding(.vertical, 2)
        }
    }

    // MARK: - Luminance Slider & Direct Numeric Input
    private var luminanceRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("LUMINANCE")
                    .font(.system(size: AtlasTheme.fontCaptionSmall, weight: .bold, design: .monospaced))
                    .foregroundColor(AtlasTheme.textBody)

                Spacer()

                if isEditingBrightness {
                    TextField("", text: $brightnessInputText, onCommit: commitBrightnessInput)
                        .textFieldStyle(.plain)
                        .font(.system(size: AtlasTheme.fontBodySmall, weight: .bold, design: .monospaced))
                        .foregroundColor(AtlasTheme.cobalt)
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
                            .foregroundColor(AtlasTheme.cobalt)
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
            }
        }
    }

    private func commitBrightnessInput() {
        if let val = Double(brightnessInputText.replacingOccurrences(of: "%", with: "")) {
            let clamped = max(0.0, min(100.0, val)) / 100.0
            store.setBrightness(item, clamped, immediate: true)
        }
        isEditingBrightness = false
    }

    // MARK: - Volume Slider
    private var volumeRow: some View {
        HStack(spacing: 8) {
            Text("VOLUME")
                .font(.system(size: AtlasTheme.fontCaptionSmall, weight: .bold, design: .monospaced))
                .foregroundColor(AtlasTheme.textBody)

            Slider(
                value: Binding(
                    get: { item.volume },
                    set: { store.setVolume(item, $0, immediate: false) }
                ),
                in: 0...1
            )
            .tint(AtlasTheme.cobaltSoft)
            .disabled(item.isVirtual)

            Text("\(Int(item.volume * 100))%")
                .font(.system(size: AtlasTheme.fontCaptionMedium, weight: .bold, design: .monospaced))
                .foregroundColor(AtlasTheme.textBody)
                .frame(width: AtlasTheme.percentLabelWidth, alignment: .trailing)

            AtlasIconButton(
                systemName: item.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                action: { store.toggleMute(item) }
            )
            .disabled(item.isVirtual)
        }
    }

    // MARK: - Row 1: Smooth Switches for RGB 4:4:4 & HDR + ICC Menu
    private var colorPillsAndProfileRow: some View {
        HStack(spacing: 12) {
            // RGB 4:4:4 Forcing Switch
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
                    .foregroundColor(item.isForceRGBActive ? AtlasTheme.textPrimary : AtlasTheme.textMuted)
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
                    .foregroundColor(item.isHDREnabled ? AtlasTheme.textPrimary : AtlasTheme.textMuted)
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

    // MARK: - Row 2: Geometry & Power Control
    private var geometryActionRow: some View {
        HStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "rotate.right")
                    .font(.system(size: AtlasTheme.fontCaptionMedium))
                    .foregroundColor(AtlasTheme.textMuted)

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
                    .foregroundColor(AtlasTheme.textMuted)

                Picker("", selection: mirrorBinding) {
                    Text("Mirror: Off").tag(CGDirectDisplayID(0))
                    ForEach(store.displays.filter { $0.id != item.id }) { other in
                        Text(other.name).tag(other.id)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .controlSize(.small)
                .frame(width: 140)
            }

            Spacer()

            AtlasIconButton(
                systemName: item.isDisconnected ? "arrow.clockwise" : "bolt.slash",
                action: { store.togglePowerConnection(item) }
            )
            .help(item.isDisconnected ? "Reconnect display" : "Blank/disconnect display")
        }
    }

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
}
#endif
