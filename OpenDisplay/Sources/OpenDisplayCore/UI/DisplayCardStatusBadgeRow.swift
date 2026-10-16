#if os(macOS) && arch(arm64)
import SwiftUI

/// Hardware status strip showing negotiated protocol capabilities and quick action toggles
public struct DisplayCardStatusBadgeRow: View {
    @ObservedObject public var item: DisplayItemModel

    public init(item: DisplayItemModel) {
        self.item = item
    }

    public var body: some View {
        HStack(spacing: 5) {
            if item.isBuiltin {
                AtlasBadge("Liquid Retina", style: .brand)
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

            // Display Notch toggle (if physical notch present on MacBook)
            if item.isBuiltin && item.hasPhysicalNotch {
                Button(action: {
                    WorkspaceStore.shared.toggleNotch(for: item)
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: item.isNotchOverlayActive ? "eye.slash.fill" : "eye.fill")
                            .font(.system(size: 8))
                        Text("Notch")
                            .font(.system(size: AtlasTheme.fontCaptionSmall, weight: .medium))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(item.isNotchOverlayActive ? Color.accentColor.opacity(0.2) : Color.primary.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                }
                .buttonStyle(.plain)
                .help("Toggle camera notch black-out overlay")
            }

            // XDR Overdrive Badge
            if item.isBuiltin && item.capabilities.supportsXDR {
                AtlasBadge(item.isXDROverdriveEnabled ? "XDR Boost" : "XDR Normal", style: item.isXDROverdriveEnabled ? .brand : .muted)
            }

            Spacer()
        }
    }
}
#endif
