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
                    AtlasEyebrow(title: "Displays", trailing: "\(store.displays.count)")
                    ForEach(store.displays) { item in
                        DisplayCardView(item: item)
                    }

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

    private var header: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("WORKSPACE")
                    .font(.system(size: AtlasTheme.fontCaptionSmall, weight: .bold, design: .monospaced))
                    .foregroundColor(AtlasTheme.textMuted)
                    .tracking(AtlasTheme.trackingTight)
                Text("OpenDisplay")
                    .font(.system(size: AtlasTheme.fontHeadline, weight: .bold))
                    .foregroundColor(AtlasTheme.cobalt)
            }

            Spacer()

            Text("ARM64 NATIVE")
                .font(.system(size: AtlasTheme.fontCaptionMedium, weight: .bold))
                .foregroundColor(AtlasTheme.cobaltDark)
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
                .foregroundColor(AtlasTheme.borderDefault),
            alignment: .bottom
        )
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Text("V2 · 100% FREE · NO PORTS")
                .font(.system(size: AtlasTheme.fontCaptionSmall, weight: .bold, design: .monospaced))
                .foregroundColor(AtlasTheme.textMuted)
                .tracking(AtlasTheme.trackingTight)

            Spacer()

            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                Text("Quit")
                    .font(.system(size: AtlasTheme.fontBodySmall, weight: .medium))
                    .foregroundColor(AtlasTheme.textBody)
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
                .foregroundColor(AtlasTheme.borderDefault),
            alignment: .top
        )
    }
}
#endif
