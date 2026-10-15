#if os(macOS) && arch(arm64)
import SwiftUI

/// Hardware status strip showing negotiated protocol capabilities (Apple DisplayServices, DDC, HDMI, 10-Bit, CEC)
public struct DisplayCardStatusBadgeRow: View {
    @ObservedObject public var item: DisplayItemModel

    public init(item: DisplayItemModel) {
        self.item = item
    }

    public var body: some View {
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
}
#endif
