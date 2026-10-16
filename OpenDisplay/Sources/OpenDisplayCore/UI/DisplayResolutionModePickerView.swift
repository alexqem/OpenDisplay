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
        HStack(spacing: 8) {
            Label("Resolution", systemImage: "display")
                .font(.system(size: AtlasTheme.fontBodySmall, weight: .medium))
                .foregroundStyle(Color.primary)

            Spacer()

            Picker("", selection: resolutionBinding) {
                if item.availableResolutions.isEmpty {
                    Text("Probing modes...").tag("" as String?)
                } else {
                    if !item.recommendedResolutions.isEmpty {
                        Section(header: Text("Modes matching default filter:")) {
                            ForEach(item.recommendedResolutions) { mode in
                                Text(mode.userLabel).tag(mode.id as String?)
                            }
                        }
                    }

                    if !item.otherResolutions.isEmpty {
                        Section(header: Text("Other Modes")) {
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
            .frame(maxWidth: 160)
        }
        .padding(.vertical, 2)
    }

    private var resolutionBinding: Binding<String?> {
        Binding(
            get: {
                item.selectedResolutionId ?? item.availableResolutions.first(where: { $0.isCurrent })?.id ?? item.availableResolutions.first?.id
            },
            set: { newId in
                guard let id = newId, let mode = item.availableResolutions.first(where: { $0.id == id }) else {
                    return
                }
                store.setResolution(item, mode: mode)
            }
        )
    }
}
#endif
