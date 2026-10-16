#if os(macOS) && arch(arm64)
import SwiftUI
import AppKit

/// Native macOS Glassmorphism Main Popover Menu View for OpenDisplay
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
                .padding(14)
            }
            .frame(maxHeight: AtlasTheme.maxScrollHeight)

            footer
        }
        .frame(width: AtlasTheme.popoverWidth)
        .background(.ultraThinMaterial)
        .onAppear {
            store.refresh()
        }
    }

    // MARK: - Displays Section
    @ViewBuilder
    private var displaysSection: some View {
        AtlasEyebrow(title: "Displays", trailing: "\(store.displays.count)")

        if store.displays.isEmpty {
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "display.trianglebadge.exclamationmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.orange)

                    Text("No Displays Detected")
                        .font(.system(size: AtlasTheme.fontBodySmall, weight: .medium))
                        .foregroundStyle(Color.primary)
                }

                Text("Check your display connection or create a virtual screen below.")
                    .font(.system(size: AtlasTheme.fontCaptionSmall))
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)

                Button(action: {
                    store.refresh()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 11))
                        Text("Detect Displays")
                            .font(.system(size: AtlasTheme.fontCaptionMedium, weight: .medium))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Color.primary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.controlRadius, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.primary.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.cardRadius, style: .continuous))
        } else {
            ForEach(store.displays) { item in
                DisplayCardView(item: item)
            }
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "display.2")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.accentColor)

            Text("OpenDisplay")
                .font(.system(size: AtlasTheme.fontHeadline, weight: .semibold))
                .foregroundStyle(Color.primary)

            Spacer()

            Button(action: {
                store.refresh()
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.secondary)
                    .frame(width: 24, height: 24)
                    .background(Color.primary.opacity(0.05))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Refresh displays")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.primary.opacity(0.02))
        .overlay(
            Divider().opacity(0.4),
            alignment: .bottom
        )
    }

    // MARK: - Dynamic Status Footer
    private var footer: some View {
        HStack(spacing: 8) {
            if let tip = store.activeTooltipText {
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                    Text(tip)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.primary)
                        .lineLimit(1)
                }
                .transition(.opacity)
            } else {
                Text("OpenDisplay")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.secondary)
            }

            Spacer()

            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                Text("Quit")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.primary.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .frame(height: 38)
        .background(Color.primary.opacity(0.02))
        .overlay(
            Divider().opacity(0.4),
            alignment: .top
        )
    }
}
#endif
