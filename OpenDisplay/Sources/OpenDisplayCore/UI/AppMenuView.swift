#if os(macOS) && arch(arm64)
import SwiftUI
import CoreGraphics

/// Observable UI state model representing a single connected or virtual display
public final class DisplayItemModel: ObservableObject, Identifiable {
    public let id: CGDirectDisplayID
    public let name: String
    @Published public var brightness: Double
    @Published public var volume: Double
    @Published public var isMuted: Bool
    @Published public var isXDROverdriveEnabled: Bool
    @Published public var isForceRGBActive: Bool
    @Published public var is10BitActive: Bool

    public init(
        id: CGDirectDisplayID,
        name: String,
        brightness: Double = 0.8,
        volume: Double = 0.5,
        isMuted: Bool = false,
        isXDROverdriveEnabled: Bool = false,
        isForceRGBActive: Bool = false,
        is10BitActive: Bool = false
    ) {
        self.id = id
        self.name = name
        self.brightness = brightness
        self.volume = volume
        self.isMuted = isMuted
        self.isXDROverdriveEnabled = isXDROverdriveEnabled
        self.isForceRGBActive = isForceRGBActive
        self.is10BitActive = is10BitActive
    }
}

/// SwiftUI Main Popover Menu View for OpenDisplay
public struct AppMenuView: View {
    @StateObject public var featureManager = AppFeatureManager.shared
    @State public var displays: [DisplayItemModel] = [
        DisplayItemModel(id: 1, name: "Built-in Liquid Retina XDR", brightness: 0.8),
        DisplayItemModel(id: 2, name: "Dell U2720Q (4K External)", brightness: 0.75)
    ]
    @State public var selectedAspectPreset: DisplayAspectPreset = .ratio16_9

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Text("OpenDisplay")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Text("ARM64 Native")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.15))
                    .cornerRadius(4)
            }
            .padding(.horizontal)
            .padding(.top, 10)

            Divider()

            // Display Cards
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(displays) { item in
                        displayCard(for: item)
                    }
                }
                .padding(.horizontal)
            }
            .frame(maxHeight: 380)

            Divider()

            // Footer / Quick Virtual Screen Generator
            HStack {
                Picker("Dummy Preset", selection: $selectedAspectPreset) {
                    ForEach(DisplayAspectPreset.allCases, id: \.self) { preset in
                        Text(preset.rawValue).tag(preset)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 140)

                Button(action: {
                    let config = VirtualDisplayConfig(name: "Virtual \(selectedAspectPreset.rawValue)", aspectPreset: selectedAspectPreset)
                    _ = DisplayCommandDispatcher.shared.createVirtual(config: config)
                }) {
                    Label("Create Dummy", systemImage: "plus.rectangle.on.rectangle")
                }
                .buttonStyle(.borderedProminent)

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
        }
        .frame(width: 380)
    }

    private func displayCard(for item: DisplayItemModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "display")
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
            }

            // Brightness Slider
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Image(systemName: "sun.max")
                    Slider(value: Binding(
                        get: { item.brightness },
                        set: { newVal in
                            item.brightness = newVal
                            _ = DisplayCommandDispatcher.shared.setBrightness(displayID: item.id, level: Float(newVal))
                        }
                    ), in: 0...1)
                    Text("\(Int(item.brightness * 100))%")
                        .font(.caption)
                        .frame(width: 36, alignment: .trailing)
                }
            }

            // Action Pills (RGB Fix, 10-bit, XDR)
            HStack(spacing: 8) {
                Toggle(isOn: Binding(
                    get: { item.isForceRGBActive },
                    set: { item.isForceRGBActive = $0 }
                )) {
                    Text("RGB 4:4:4")
                        .font(.caption2)
                }
                .toggleStyle(.button)

                Toggle(isOn: Binding(
                    get: { item.is10BitActive },
                    set: { item.is10BitActive = $0 }
                )) {
                    Text("10-Bit Color")
                        .font(.caption2)
                }
                .toggleStyle(.button)

                Toggle(isOn: Binding(
                    get: { item.isXDROverdriveEnabled },
                    set: { item.isXDROverdriveEnabled = $0 }
                )) {
                    Text("XDR 1600 Nits")
                        .font(.caption2)
                }
                .toggleStyle(.button)
            }
        }
        .padding(10)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}
#endif
