#if os(macOS) && arch(arm64)
import SwiftUI

/// Detailed Color Mode, Depth, Dithering and Appearance Section (BetterDisplay parity)
public struct DisplayColorModeSectionView: View {
    @ObservedObject public var item: DisplayItemModel
    @ObservedObject private var store = WorkspaceStore.shared

    public init(item: DisplayItemModel) {
        self.item = item
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Submenu Accordion Header
            Button(action: {
                withAnimation(.easeInOut(duration: AtlasTheme.switchAnimationDuration)) {
                    item.isColorModeExpanded.toggle()
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "paintpalette.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.accentColor)

                    Text("Color Mode")
                        .font(.system(size: AtlasTheme.fontBodySmall, weight: .medium))
                        .foregroundStyle(Color.primary)

                    Spacer()

                    Image(systemName: item.isColorModeExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Color.secondary)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color.primary.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.controlRadius, style: .continuous))
            }
            .buttonStyle(.plain)

            if item.isColorModeExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    colorDepthRows
                    Divider().opacity(0.5)
                    hdrSection
                    Divider().opacity(0.5)
                    gpuDitheringRow
                    Divider().opacity(0.5)
                    appearancePresetsSection
                }
                .padding(10)
                .background(Color.primary.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.controlRadius, style: .continuous))
            }
        }
    }

    // MARK: - 1. Color Depth & Subsampling Options
    private var colorDepthRows: some View {
        VStack(alignment: .leading, spacing: 5) {
            // Option 1: 8-bit SDR RGB Full Range (Standard RGB output)
            Button {
                item.isForceRGBActive = true
                store.activeTooltipText = "Active: 8-bit SDR RGB Full Range"
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: item.isForceRGBActive ? "circle.fill" : "circle")
                        .font(.system(size: 10))
                        .foregroundStyle(item.isForceRGBActive ? Color.accentColor : Color.secondary)

                    Text("8-bit")
                        .font(.system(size: AtlasTheme.fontCaptionMedium, weight: .semibold))
                        .foregroundStyle(Color.primary)

                    Spacer()

                    AtlasBadge("SDR", style: .success)
                    AtlasBadge("RGB", style: .success)
                    AtlasBadge("Full Range", style: .success)
                }
                .padding(6)
                .background(item.isForceRGBActive ? Color.accentColor.opacity(0.12) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .buttonStyle(.plain)

            // Option 2: 8-bit SDR YCbCr 4:4:4 Limited Range
            Button {
                item.isForceRGBActive = false
                store.activeTooltipText = "Active: 8-bit SDR YCbCr 4:4:4 Limited Range"
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: !item.isForceRGBActive ? "circle.fill" : "circle")
                        .font(.system(size: 10))
                        .foregroundStyle(!item.isForceRGBActive ? Color.accentColor : Color.secondary)

                    Text("8-bit")
                        .font(.system(size: AtlasTheme.fontCaptionMedium, weight: .semibold))
                        .foregroundStyle(Color.primary)

                    Spacer()

                    AtlasBadge("SDR", style: .success)
                    AtlasBadge("YCbCr", style: .warning)
                    AtlasBadge("4:4:4", style: .success)
                    AtlasBadge("Limited Range", style: .muted)
                }
                .padding(6)
                .background(!item.isForceRGBActive ? Color.accentColor.opacity(0.12) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .buttonStyle(.plain)

            HStack(spacing: 4) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 9))
                Text("Configuration Protection makes color mode changes persistent.")
                    .font(.system(size: 10))
            }
            .foregroundStyle(Color.secondary)
            .padding(.top, 2)
        }
    }

    // MARK: - 2. HDR Section
    private var hdrSection: some View {
        HStack(spacing: 6) {
            Image(systemName: "square.2.layers.3d.top.filled")
                .font(.system(size: 11))
                .foregroundStyle(Color.secondary)

            Text("Allow Forced HDR")
                .font(.system(size: AtlasTheme.fontCaptionMedium))
                .foregroundStyle(Color.primary)

            Spacer()

            Toggle("", isOn: Binding(
                get: { item.isHDREnabled },
                set: { _ in store.toggleHDR(item) }
            ))
            .toggleStyle(.switch)
            .controlSize(.mini)
            .labelsHidden()
        }
        .help("Force High Dynamic Range mode via SkyLight")
    }

    // MARK: - 3. GPU Dithering Section
    private var gpuDitheringRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "waveform.path")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(item.isGPUDitheringEnabled ? Color.accentColor : Color.secondary)

                Text("GPU Dithering")
                    .font(.system(size: AtlasTheme.fontCaptionMedium, weight: .medium))
                    .foregroundStyle(Color.primary)

                Spacer()

                Toggle("", isOn: $item.isGPUDitheringEnabled)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .labelsHidden()
            }

            HStack(alignment: .top, spacing: 4) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 9))
                    .foregroundStyle(Color.orange)

                Text("Connection color depth (8-bit) is lower than framebuffer (10-bit). Temporal dithering smooths gradients.")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.secondary)
                    .lineLimit(2)
            }
        }
    }

    // MARK: - 4. Appearance & Color Filter Presets
    private var appearancePresetsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Appearance")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.secondary)
                .textCase(.uppercase)

            ForEach(DisplayAppearancePreset.allCases) { preset in
                Button(action: {
                    item.appearancePreset = preset
                    store.activeTooltipText = "Applied: \(preset.rawValue)"
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: preset.icon)
                            .font(.system(size: 11))
                            .foregroundStyle(item.appearancePreset == preset ? Color.accentColor : Color.secondary)

                        Text(preset.rawValue)
                            .font(.system(size: AtlasTheme.fontCaptionMedium))
                            .foregroundStyle(item.appearancePreset == preset ? Color.accentColor : Color.primary)

                        Spacer()

                        if item.appearancePreset == preset {
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .padding(.vertical, 3)
                    .padding(.horizontal, 6)
                    .background(item.appearancePreset == preset ? Color.accentColor.opacity(0.08) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
#endif
