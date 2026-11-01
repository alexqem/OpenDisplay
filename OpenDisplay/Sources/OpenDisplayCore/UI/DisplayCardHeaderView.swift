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
                .foregroundStyle(Color.accentColor)

            Text(item.name)
                .font(.system(size: AtlasTheme.fontBodyMedium, weight: .semibold))
                .foregroundStyle(Color.primary)
                .lineLimit(1)

            if item.isVirtual {
                AtlasBadge("Virtual", style: .brand)
            }
            if item.isCast {
                AtlasBadge("Cast", style: .brand)
            }
            if item.isMirrored {
                AtlasBadge("Mirrored", style: .muted)
            }
            if item.isGroupMaster {
                AtlasBadge("Master", style: .brand)
            } else if item.syncGroupMasterID != nil {
                AtlasBadge("Linked", style: .muted)
            }

            Spacer()

            // HiDPI toggle (BetterDisplay "Hi Resolution" parity): visible when HiDPI
            // alternatives exist or the display currently renders in HiDPI
            if showsHiDPIToggle {
                Button {
                    WorkspaceStore.shared.toggleHiDPI(for: item)
                } label: {
                    AtlasPillToggle(label: "HiDPI", isActive: item.isHiDPI)
                }
                .buttonStyle(.plain)
                .help(item.isHiDPI ? "HiDPI rendering active - click to switch to 1x" : "Enable HiDPI rendering (sharper stream)")
            }

            if item.isBuiltin {
                Text("Built-in")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.secondary)
            } else if item.currentRefreshRate > 0 {
                Text("\(Int(item.currentRefreshRate.rounded()))Hz")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.secondary)
            }

            // Power / Soft Disconnect Toggle (BetterDisplay-style header toggle)
            Toggle("", isOn: Binding(
                get: { !item.isDisconnected },
                set: { _ in WorkspaceStore.shared.togglePowerConnection(item) }
            ))
            .toggleStyle(.switch)
            .controlSize(.mini)
            .labelsHidden()
            .help(item.isDisconnected ? "Connect display" : "Disconnect / Sleep display")
        }
    }

    private var headerIcon: String {
        if item.isVirtual { return "rectangle.on.rectangle" }
        if item.isCast { return "airplayaudio" }
        return item.isBuiltin ? "laptopcomputer" : "display"
    }

    private var showsHiDPIToggle: Bool {
        !item.isVirtual && (!item.hiDPIResolutions.isEmpty || item.isHiDPI)
    }
}
#endif
