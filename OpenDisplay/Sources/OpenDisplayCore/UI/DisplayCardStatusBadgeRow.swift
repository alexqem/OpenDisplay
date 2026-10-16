#if os(macOS) && arch(arm64)
import SwiftUI

/// Hardware status strip showing negotiated protocol capabilities
public struct DisplayCardStatusBadgeRow: View {
    @ObservedObject public var item: DisplayItemModel

    public init(item: DisplayItemModel) {
        self.item = item
    }

    public var body: some View {
        HStack(spacing: 5) {
            if item.isBuiltin {
                AtlasBadge("DisplayServices", style: .brand)
            } else if item.isVirtual {
                AtlasBadge("Virtual", style: .brand)
            } else if item.capabilities.supportsDDC {
                AtlasBadge("DDC/CI", style: .success)
            } else {
                AtlasBadge("Gamma LUT", style: .warning)
            }

            if item.capabilities.supports10BitDeepColor {
                AtlasBadge("10-Bit", style: .muted)
            }

            Spacer()
        }
    }
}
#endif
