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

                if item.isMirrored {
                    Text("Managed by Master")
                        .font(.system(size: AtlasTheme.fontCaptionSmall))
                        .foregroundStyle(Color.secondary)
                } else {
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

                            if item.showAllResolutions && !item.lowResLegacyResolutions.isEmpty {
                                Section(header: Text("Legacy Low-Res Modes (<\(ResolutionClassifier.standardMinimumPointHeight)p)")) {
                                    ForEach(item.lowResLegacyResolutions) { mode in
                                        Text(mode.resolutionOnlyLabel).tag(mode.id as String?)
                                    }
                                }
                            }
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .controlSize(.small)
                    .frame(maxWidth: AtlasTheme.pickerMaxWidth)
                }
            }

            // Quick toggle to show/hide legacy low-resolution modes (<540p)
            if !item.isMirrored && !item.lowResLegacyResolutions.isEmpty {
                HStack {
                    Spacer()
                    Button {
                        item.showAllResolutions.toggle()
                    } label: {
                        Text(item.showAllResolutions ? "Hide low-res modes" : "Show all resolutions (\(item.lowResLegacyResolutions.count) low-res hidden)")
                            .font(.system(size: AtlasTheme.fontCaptionMicro, weight: .medium))
                            .foregroundStyle(Color.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            // 2. Refresh Rate Dropdown (Independent selection as in BetterDisplay Structure #2)
            HStack(spacing: 8) {
                Label("Refresh Rate", systemImage: "speedometer")
                    .font(.system(size: AtlasTheme.fontBodySmall, weight: .medium))
                    .foregroundStyle(Color.primary)

                Spacer()

                if item.isMirrored {
                    Text("\(ResolutionClassifier.formatRefreshRate(item.currentRefreshRate, isBuiltin: item.isBuiltin)) (Slave)")
                        .font(.system(size: AtlasTheme.fontCaptionSmall))
                        .foregroundStyle(Color.secondary)
                } else {
                    Picker("", selection: refreshRateBinding) {
                        if item.availableRefreshRates.isEmpty {
                            Text(ResolutionClassifier.formatRefreshRate(item.currentRefreshRate, isBuiltin: item.isBuiltin)).tag(item.currentRefreshRate)
                        } else {
                            ForEach(item.availableRefreshRates, id: \.self) { rate in
                                let label = ResolutionClassifier.formatRefreshRate(rate, isBuiltin: item.isBuiltin)
                                Text(label).tag(rate)
                            }
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .controlSize(.small)
                    .frame(maxWidth: AtlasTheme.pickerMaxWidth)
                }
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
