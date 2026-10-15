#if os(macOS) && arch(arm64)
import SwiftUI
import CoreGraphics

/// Header row displaying icon, display name, dynamic status pills, and numeric ID badge
public struct DisplayCardHeaderView: View {
    @ObservedObject public var item: DisplayItemModel

    public init(item: DisplayItemModel) {
        self.item = item
    }

    public var body: some View {
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
            if item.isGroupMaster {
                AtlasBadge("SYNC MASTER", style: .lime)
            } else if item.syncGroupMasterID != nil {
                AtlasBadge("SYNC SLAVE", style: .brand)
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
}
#endif
