#if os(macOS) && arch(arm64)
import SwiftUI

/// Categorized resolution mode selector using pre-filtered collections (BetterDisplay parity)
public struct DisplayResolutionModePickerView: View {
    @ObservedObject public var item: DisplayItemModel
    @ObservedObject private var store = WorkspaceStore.shared

    public init(item: DisplayItemModel) {
        self.item = item
    }

    public var body: some View {
        VStack(spacing: 6) {
            // 1. Resolution Dropdown
            HStack(spacing: 8) {
                Label("Resolution", systemImage: "display")
                    .font(.system(size: AtlasTheme.fontBodySmall, weight: .medium))
                    .foregroundStyle(Color.primary)

                Spacer()

                Picker("", selection: resolutionBinding) {
                    if item.availableResolutions.isEmpty {
                        Text("Probing modes...").tag("" as String?)
                    } else {
                        // BetterDisplay Parity: Prioritize HiDPI section, then Native & Standard Low-res (1x)
                        if !item.hiDPIResolutions.isEmpty {
                            Section(header: Text("HiDPI Scaled Resolutions")) {
                                ForEach(item.hiDPIResolutions) { mode in
                                    Text(mode.resolutionOnlyLabel).tag(mode.id as String?)
                                }
                            }
                        }

                        if !item.nativeAndStandardResolutions.isEmpty {
                            Section(header: Text("Standard & Native Modes")) {
                                ForEach(item.nativeAndStandardResolutions) { mode in
                                    Text(mode.resolutionOnlyLabel).tag(mode.id as String?)
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

            // 2. Refresh Rate Dropdown (Independent selection as in BetterDisplay Structure #2)
            HStack(spacing: 8) {
                Label("Refresh Rate", systemImage: "speedometer")
                    .font(.system(size: AtlasTheme.fontBodySmall, weight: .medium))
                    .foregroundStyle(Color.primary)

                Spacer()

                Picker("", selection: refreshRateBinding) {
                    if item.availableRefreshRates.isEmpty {
                        Text("\(Int(item.currentRefreshRate.rounded()))Hz").tag(item.currentRefreshRate)
                    } else {
                        ForEach(item.availableRefreshRates, id: \.self) { rate in
                            let label = formatRate(rate)
                            Text(label).tag(rate)
                        }
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .controlSize(.small)
                .frame(maxWidth: 160)
            }
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

    private var refreshRateBinding: Binding<Double> {
        Binding(
            get: {
                item.currentRefreshRate
            },
            set: { newRate in
                store.setRefreshRate(item, rate: newRate)
            }
        )
    }

    private func formatRate(_ rate: Double) -> String {
        let rounded = rate.rounded()
        if abs(rate - rounded) < 0.05 {
            let intRate = Int(rounded)
            if intRate == 120 && item.isBuiltin {
                return "120Hz (ProMotion)"
            }
            return "\(intRate)Hz"
        } else {
            return String(format: "%.2fHz", rate)
        }
    }
}
#endif
