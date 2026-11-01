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
            // 0. Ultra Sharp Cast (virtual mirror master) for AirPlay destinations
            if item.isCast && !item.isVirtual {
                CastUltraSharpRow(item: item)
            }

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
                if let selected = item.selectedResolutionId,
                   let current = item.availableResolutions.first(where: { $0.id == selected }) {
                    return uniqueListMatching(current)?.id ?? selected
                }
                if let current = item.availableResolutions.first(where: { $0.isCurrent }) {
                    return uniqueListMatching(current)?.id ?? current.id
                }
                return item.hiDPIResolutions.first?.id ?? item.nativeAndStandardResolutions.first?.id
            },
            set: { newId in
                guard let id = newId, let mode = item.availableResolutions.first(where: { $0.id == id }) else {
                    return
                }
                store.setResolution(item, mode: mode)
            }
        )
    }

    private func uniqueListMatching(_ mode: DisplayResolutionDescriptor) -> DisplayResolutionDescriptor? {
        let pool = mode.isHiDPI ? item.hiDPIResolutions : item.nativeAndStandardResolutions
        return pool.first(where: { $0.pointWidth == mode.pointWidth && $0.pointHeight == mode.pointHeight })
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

/// Ultra Sharp Cast row: virtual mirror master so AirPlay streams above its default timing
public struct CastUltraSharpRow: View {
    @ObservedObject public var item: DisplayItemModel
    @ObservedObject private var store = WorkspaceStore.shared

    public init(item: DisplayItemModel) {
        self.item = item
    }

    public var body: some View {
        HStack(spacing: 8) {
            Label("Ultra Sharp", systemImage: "wand.and.stars")
                .font(.system(size: AtlasTheme.fontBodySmall, weight: .medium))
                .foregroundStyle(Color.primary)

            Spacer()

            ForEach(CastVirtualResolutionController.SharpnessTier.allCases, id: \.rawValue) { tier in
                let active = CastVirtualResolutionController.shared.isActive(for: item.id)
                    && CastVirtualResolutionController.shared.tier == tier
                Button {
                    store.toggleCastUltraSharp(for: item, tier: tier)
                } label: {
                    AtlasPillToggle(label: tier.label, isActive: active)
                }
                .buttonStyle(.plain)
                .help(active ? "Disable Ultra Sharp (restore AirPlay default)" : "Mirror through a virtual \(tier.rawValue) master - sharper stream, UI at \(tier.pixelWidth / 2)x\(tier.pixelHeight / 2)")
            }
        }
    }
}
#endif
