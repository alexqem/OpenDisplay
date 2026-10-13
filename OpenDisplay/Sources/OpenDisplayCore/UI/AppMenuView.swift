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

/// SwiftUI Main Popover Menu View for OpenDisplay styled with the Atlas / TypeUI Swiss neo-brutalist design system
public struct AppMenuView: View {
    @StateObject public var featureManager = AppFeatureManager.shared
    @State public var displays: [DisplayItemModel] = [
        DisplayItemModel(id: 1, name: "Built-in Liquid Retina XDR", brightness: 0.8),
        DisplayItemModel(id: 2, name: "External Studio Display (4K)", brightness: 0.75)
    ]
    @State public var selectedAspectPreset: DisplayAspectPreset = .ratio16_9

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: Sharp 0px border-bottom, Cobalt Title, Electric Lime Status Pill
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("WORKSPACE")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(AtlasTheme.textMuted)
                        .tracking(1.0)
                    Text("OpenDisplay")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AtlasTheme.cobalt)
                }

                Spacer()

                // High-voltage Neon Lime Pill Badge
                Text("ARM64 NATIVE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(AtlasTheme.cobaltDark)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AtlasTheme.electricLime)
                    .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.pillRadius))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AtlasTheme.surfaceHeader)
            .overlay(
                Rectangle()
                    .frame(height: AtlasTheme.borderWidth)
                    .foregroundColor(AtlasTheme.borderDefault),
                alignment: .bottom
            )

            // Display Cards ScrollView with 0px sharp technical borders
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(displays) { item in
                        displayCard(for: item)
                    }
                }
                .padding(16)
            }
            .frame(maxHeight: 400)

            // Footer: Sharp 0px border-top with technical dummy display generator & Quit action
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("PRESET GENERATOR")
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .foregroundColor(AtlasTheme.textMuted)
                        Picker("", selection: $selectedAspectPreset) {
                            ForEach(DisplayAspectPreset.allCases, id: \.self) { preset in
                                Text(preset.rawValue).tag(preset)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 120)
                    }

                    Spacer()

                    // Sharp 0px Cobalt CTA Button
                    Button(action: {
                        let config = VirtualDisplayConfig(name: "Virtual \(selectedAspectPreset.rawValue)", aspectPreset: selectedAspectPreset)
                        _ = DisplayCommandDispatcher.shared.createVirtual(config: config)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.rectangle.on.rectangle")
                                .font(.system(size: 11))
                            Text("Create Dummy")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .foregroundColor(.white)
                        .background(AtlasTheme.cobalt)
                        .overlay(
                            Rectangle().stroke(AtlasTheme.cobaltDark, lineWidth: AtlasTheme.borderWidth)
                        )
                    }
                    .buttonStyle(.plain)

                    // Sharp Outline Quit Button
                    Button(action: {
                        NSApplication.shared.terminate(nil)
                    }) {
                        Text("Quit")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AtlasTheme.textBody)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white)
                            .overlay(
                                Rectangle().stroke(AtlasTheme.borderMedium, lineWidth: AtlasTheme.borderWidth)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AtlasTheme.surfaceHeader)
            .overlay(
                Rectangle()
                    .frame(height: AtlasTheme.borderWidth)
                    .foregroundColor(AtlasTheme.borderDefault),
                alignment: .top
            )
        }
        .frame(width: AtlasTheme.popoverWidth)
        .background(Color.white)
    }

    private func displayCard(for item: DisplayItemModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Display Title & Identification
            HStack(spacing: 8) {
                Image(systemName: "display")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AtlasTheme.cobalt)

                Text(item.name)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AtlasTheme.textPrimary)

                Spacer()

                Text("ID: \(item.id)")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundColor(AtlasTheme.textMuted)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AtlasTheme.cobaltSofter)
                    .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.pillRadius))
            }

            // High-Precision Linear Brightness Slider
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("LUMINANCE")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(AtlasTheme.textBody)

                    Spacer()

                    Text("\(Int(item.brightness * 100))%")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(AtlasTheme.cobalt)
                }

                Slider(value: Binding(
                    get: { item.brightness },
                    set: { newVal in
                        item.brightness = newVal
                        _ = DisplayCommandDispatcher.shared.setBrightness(displayID: item.id, level: Float(newVal))
                    }
                ), in: 0...1)
                .accentColor(AtlasTheme.cobalt)
            }

            // Precision Action Pills (0px sharp buttons with active state)
            HStack(spacing: 6) {
                actionPill(
                    title: "RGB 4:4:4",
                    isActive: item.isForceRGBActive,
                    action: { item.isForceRGBActive.toggle() }
                )

                actionPill(
                    title: "10-Bit Color",
                    isActive: item.is10BitActive,
                    action: { item.is10BitActive.toggle() }
                )

                actionPill(
                    title: "XDR 1600 Nits",
                    isActive: item.isXDROverdriveEnabled,
                    action: { item.isXDROverdriveEnabled.toggle() }
                )
            }
        }
        .padding(14)
        .background(AtlasTheme.surfaceCard)
        .overlay(
            Rectangle().stroke(AtlasTheme.borderDefault, lineWidth: AtlasTheme.borderWidth)
        )
    }

    private func actionPill(title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(isActive ? .white : AtlasTheme.cobalt)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isActive ? AtlasTheme.cobalt : Color.white)
                .overlay(
                    Rectangle().stroke(isActive ? AtlasTheme.cobaltDark : AtlasTheme.borderMedium, lineWidth: AtlasTheme.borderWidth)
                )
        }
        .buttonStyle(.plain)
    }
}
#endif
