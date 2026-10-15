#if os(macOS) && arch(arm64)
import SwiftUI
import AppKit
import CoreGraphics

/// Clean, modular progressive-disclosure Display Card View following Atlas / TypeUI and SwiftUI Pro rules
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
}
#endif
