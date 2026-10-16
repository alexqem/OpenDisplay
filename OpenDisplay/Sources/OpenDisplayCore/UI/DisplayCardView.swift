#if os(macOS) && arch(arm64)
import SwiftUI
import AppKit
import CoreGraphics

/// Clean native macOS Card View with translucent glass background and subtle border
public struct DisplayCardView: View {
    @ObservedObject public var item: DisplayItemModel

    public init(item: DisplayItemModel) {
        self.item = item
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            DisplayCardHeaderView(item: item)
            DisplayCardStatusBadgeRow(item: item)
            DisplayLuminanceControlView(item: item)
            DisplayAudioControlView(item: item)

            AtlasDivider()

            DisplayResolutionModePickerView(item: item)

            // Progressive Disclosure Accordion: Advanced Hardware & Color Drawer
            DisplayAdvancedControlsDrawerView(item: item)

            if item.isDisconnected {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: AtlasTheme.fontCaptionMedium))
                    Text("Disconnected")
                        .font(.system(size: AtlasTheme.fontCaptionSmall, weight: .medium))
                }
                .foregroundStyle(Color.orange)
                .padding(.top, 2)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: AtlasTheme.cardRadius, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AtlasTheme.cardRadius, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
    }
}
#endif
