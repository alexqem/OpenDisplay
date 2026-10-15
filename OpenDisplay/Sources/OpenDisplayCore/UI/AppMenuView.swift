#if os(macOS) && arch(arm64)
import SwiftUI
import AppKit

/// SwiftUI Main Popover Menu View for OpenDisplay styled with the Atlas / TypeUI Swiss neo-brutalist design system
public struct AppMenuView: View {
    @ObservedObject private var store = WorkspaceStore.shared

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: AtlasTheme.sectionSpacing) {
                    displaysSection

                    AtlasDivider()
                    AtlasEyebrow(title: "Presets", trailing: "\(store.presets.count)")
                    PresetsSectionView(store: store)

                    AtlasDivider()
                    AtlasEyebrow(title: "Virtual Displays", trailing: "\(store.virtualDisplays.count)")
                    VirtualSectionView(store: store)

                    AtlasDivider()
                    AtlasEyebrow(title: "System")
                    SystemSectionView(store: store)
                }
                .padding(16)
            }
            .frame(maxHeight: AtlasTheme.maxScrollHeight)

            footer
        }
        .frame(width: AtlasTheme.popoverWidth)
        .background(AtlasTheme.surfaceCard)
        .onAppear {
            store.refresh()
        }
    }

    // MARK: - Displays Section with Rich Empty State
    @ViewBuilder
    private var displaysSection: some View {
        AtlasEyebrow(title: "Displays", trailing: "\(store.displays.count)")

        if store.displays.isEmpty {
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "display.trianglebadge.exclamationmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AtlasTheme.warningOrange)

                    Text("[NO MONITORS DETECTED ON IOKIT BUS]")
                        .font(.system(size: AtlasTheme.fontCaptionSmall, weight: .bold, design: .monospaced))
                        .foregroundStyle(AtlasTheme.warningOrange)
                }

                Text("Check Thunderbolt/HDMI cable or create a software dummy screen below.")
                    .font(.system(size: AtlasTheme.fontCaptionMedium))
                    .foregroundStyle(AtlasTheme.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)

                Button(action: {
                    store.refresh()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: AtlasTheme.fontCaptionMedium))
                        Text("Rescan Hardware Bus")
                            .font(.system(size: AtlasTheme.fontCaptionMedium, weight: .bold, design: .monospaced))
                    }
                    .foregroundStyle(AtlasTheme.cobalt)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AtlasTheme.surfaceCard)
                    .overlay(
                        Rectangle().stroke(AtlasTheme.cobalt, lineWidth: AtlasTheme.borderWidth)
                    )
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AtlasTheme.surfaceHeader)
            .overlay(
                Rectangle().stroke(AtlasTheme.borderMedium, lineWidth: AtlasTheme.borderWidth)
            )
        } else {
            ForEach(store.displays) { item in
                DisplayCardView(item: item)
            }
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("WORKSPACE")
                    .font(.system(size: AtlasTheme.fontCaptionSmall, weight: .bold, design: .monospaced))
                    .foregroundStyle(AtlasTheme.textMuted)
                    .tracking(AtlasTheme.trackingTight)
                Text("OpenDisplay")
                    .font(.system(size: AtlasTheme.fontHeadline, weight: .bold))
                    .foregroundStyle(AtlasTheme.cobalt)
            }

            Spacer()

            Text("ARM64 NATIVE")
                .font(.system(size: AtlasTheme.fontCaptionMedium, weight: .bold))
                .foregroundStyle(AtlasTheme.cobaltDark)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(AtlasTheme.electricLime)
                .clipShape(Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            ZStack {
                AtlasTheme.surfaceHeader
                AtlasBlueprintGrid()
            }
        )
        .overlay(
            Rectangle()
                .frame(height: AtlasTheme.borderWidth)
                .foregroundStyle(AtlasTheme.borderDefault),
            alignment: .bottom
        )
    }

    // MARK: - Footer
    private var footer: some View {
        HStack(spacing: 8) {
            Button(action: {
                store.refresh()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: AtlasTheme.fontCaptionSmall))
                    Text("RESCAN")
                        .font(.system(size: AtlasTheme.fontCaptionSmall, weight: .bold, design: .monospaced))
                }
                .foregroundStyle(AtlasTheme.textBody)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("V2 · 100% FREE · ZERO TELEMETRY")
                .font(.system(size: AtlasTheme.fontCaptionSmall, weight: .bold, design: .monospaced))
                .foregroundStyle(AtlasTheme.textMuted)
                .tracking(AtlasTheme.trackingTight)

            Spacer()

            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                Text("Quit")
                    .font(.system(size: AtlasTheme.fontBodySmall, weight: .medium))
                    .foregroundStyle(AtlasTheme.textBody)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AtlasTheme.surfaceCard)
                    .overlay(
                        Rectangle().stroke(AtlasTheme.borderMedium, lineWidth: AtlasTheme.borderWidth)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AtlasTheme.surfaceHeader)
        .overlay(
            Rectangle()
                .frame(height: AtlasTheme.borderWidth)
                .foregroundStyle(AtlasTheme.borderDefault),
            alignment: .top
        )
    }
}
#endif
