#if os(macOS) && arch(arm64)
import SwiftUI

/// Categorized resolution mode selector using pre-filtered collections
public struct DisplayResolutionModePickerView: View {
    @ObservedObject public var item: DisplayItemModel
    @ObservedObject private var store = WorkspaceStore.shared

    public init(item: DisplayItemModel) {
        self.item = item
    }

    public var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "aspectratio")
                .font(.system(size: AtlasTheme.fontCaptionMedium))
                .foregroundStyle(AtlasTheme.cobalt)

            Text("Mode:")
                .font(.system(size: AtlasTheme.fontCaptionMedium, weight: .bold))
                .foregroundStyle(AtlasTheme.textPrimary)

            Picker("", selection: resolutionBinding) {
                if item.availableResolutions.isEmpty {
                    Text("System Default").tag("" as String?)
                } else {
                    if !item.recommendedResolutions.isEmpty {
                        Section(header: Text("RECOMMENDED")) {
                            ForEach(item.recommendedResolutions) { mode in
                                Text("★ \(mode.userLabel)").tag(mode.id as String?)
                            }
                        }
                    }

                    if !item.otherResolutions.isEmpty {
                        Section(header: Text("SCALED / LOW RES")) {
                            ForEach(item.otherResolutions) { mode in
                                Text("\(mode.userLabel) (\(mode.tier.rawValue))").tag(mode.id as String?)
                            }
                        }
                    }
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .controlSize(.small)
            .frame(maxWidth: .infinity)

            if let cur = item.availableResolutions.first(where: { $0.id == item.selectedResolutionId }) {
                if cur.isRecommended {
                    AtlasBadge("RECOMMENDED", style: .lime)
                } else if cur.isHiDPI {
                    AtlasBadge("HiDPI", style: .brand)
                } else {
                    AtlasBadge("LOW-RES", style: .muted)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var resolutionBinding: Binding<String?> {
        Binding(
            get: { item.selectedResolutionId },
            set: { modeId in
                guard let modeId,
                      let mode = item.availableResolutions.first(where: { $0.id == modeId }) else { return }
                store.setResolution(item, mode: mode)
            }
        )
    }
}
#endif
