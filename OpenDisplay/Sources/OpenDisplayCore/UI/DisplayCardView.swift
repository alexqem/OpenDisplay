#if os(macOS) && arch(arm64)
import SwiftUI
import CoreGraphics

/// Per-display control card: luminance, volume, color pills, and geometry actions
public struct DisplayCardView: View {
    @ObservedObject public var item: DisplayItemModel
    @ObservedObject private var store = WorkspaceStore.shared

    public init(item: DisplayItemModel) {
        self.item = item
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            headerRow
            luminanceRow
            volumeRow
            colorPillRow
            actionRow
            if item.isDisconnected {
                Text("SOFTWARE DISCONNECTED")
                    .font(.system(size: AtlasTheme.fontCaptionSmall, weight: .bold, design: .monospaced))
                    .foregroundColor(AtlasTheme.warningOrange)
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

    private var luminanceRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("LUMINANCE")
                    .font(.system(size: AtlasTheme.fontCaptionSmall, weight: .bold, design: .monospaced))
                    .foregroundColor(AtlasTheme.textBody)
                Spacer()
                Text("\(Int(item.brightness * 100))%")
                    .font(.system(size: AtlasTheme.fontBodySmall, weight: .bold, design: .monospaced))
                    .foregroundColor(AtlasTheme.cobalt)
            }
            Slider(
                value: Binding(
                    get: { item.brightness },
                    set: { store.setBrightness(item, $0) }
                ),
                in: 0...1
            )
            .tint(AtlasTheme.cobalt)
            .disabled(item.isDisconnected)
        }
    }

    private var volumeRow: some View {
        HStack(spacing: 8) {
            Text("VOLUME")
                .font(.system(size: AtlasTheme.fontCaptionSmall, weight: .bold, design: .monospaced))
                .foregroundColor(AtlasTheme.textBody)

            Slider(
                value: Binding(
                    get: { item.volume },
                    set: { store.setVolume(item, $0) }
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

    private var colorPillRow: some View {
        HStack(spacing: 6) {
            AtlasPillButton(title: "RGB 4:4:4", isActive: item.isForceRGBActive) {
                store.toggleForceRGB(item)
            }

            AtlasPillButton(title: "HDR", isActive: item.isHDREnabled) {
                store.toggleHDR(item)
            }

            AtlasBadge("10-BIT", style: item.is10BitActive ? .success : .muted)
            Spacer()
        }
    }

    private var actionRow: some View {
        HStack(spacing: 6) {
            Picker("", selection: rotationBinding) {
                ForEach(DisplayRotationAngle.allCases, id: \.self) { angle in
                    Text("\(angle.rawValue)°").tag(angle)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .controlSize(.small)
            .frame(width: AtlasTheme.pickerNarrowWidth)

            Picker("", selection: mirrorBinding) {
                Text("Mirror: Off").tag(CGDirectDisplayID(0))
                ForEach(store.displays.filter { $0.id != item.id }) { other in
                    Text(other.name).tag(other.id)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .controlSize(.small)
            .frame(width: AtlasTheme.pickerWidth)

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

            Spacer()

            AtlasIconButton(
                systemName: item.isDisconnected ? "arrow.clockwise" : "bolt.slash",
                action: { store.togglePowerConnection(item) }
            )
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
