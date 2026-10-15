#if os(macOS) && arch(arm64)
import SwiftUI

/// Primary luminance slider, steppers, and direct numeric input field
public struct DisplayLuminanceControlView: View {
    @ObservedObject public var item: DisplayItemModel
    @ObservedObject private var store = WorkspaceStore.shared

    @State private var isEditingBrightness: Bool = false
    @State private var brightnessInputText: String = ""

    public init(item: DisplayItemModel) {
        self.item = item
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("LUMINANCE")
                    .font(.system(size: AtlasTheme.fontCaptionSmall, weight: .bold, design: .monospaced))
                    .foregroundStyle(AtlasTheme.textBody)

                Spacer()

                if isEditingBrightness {
                    TextField("", text: $brightnessInputText, onCommit: commitBrightnessInput)
                        .textFieldStyle(.plain)
                        .font(.system(size: AtlasTheme.fontBodySmall, weight: .bold, design: .monospaced))
                        .foregroundStyle(AtlasTheme.cobalt)
                        .frame(width: 44)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(AtlasTheme.surfaceHeader)
                        .overlay(
                            Rectangle().stroke(AtlasTheme.cobalt, lineWidth: AtlasTheme.borderWidth)
                        )
                } else {
                    Button(action: {
                        brightnessInputText = "\(Int(item.brightness * 100))"
                        isEditingBrightness = true
                    }) {
                        Text("\(Int(item.brightness * 100))%")
                            .font(.system(size: AtlasTheme.fontBodySmall, weight: .bold, design: .monospaced))
                            .foregroundStyle(AtlasTheme.cobalt)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(AtlasTheme.cobaltSofter)
                    }
                    .buttonStyle(.plain)
                    .help("Click to enter exact percentage")
                }
            }

            HStack(spacing: 6) {
                AtlasIconButton(systemName: "minus") {
                    let next = max(0.0, item.brightness - MediaKeyConstants.brightnessStep)
                    store.setBrightness(item, next, immediate: true)
                }
                .disabled(item.isDisconnected)

                Slider(
                    value: Binding(
                        get: { item.brightness },
                        set: { store.setBrightness(item, $0, immediate: false) }
                    ),
                    in: 0...1
                )
                .tint(AtlasTheme.cobalt)
                .disabled(item.isDisconnected)

                AtlasIconButton(systemName: "plus") {
                    let next = min(1.0, item.brightness + MediaKeyConstants.brightnessStep)
                    store.setBrightness(item, next, immediate: true)
                }
                .disabled(item.isDisconnected)

                // Optional XDR Overdrive Pill
                if !item.isBuiltin && !item.isVirtual {
                    Button(action: { store.toggleXDROverdrive(item) }) {
                        Text("XDR")
                            .font(.system(size: AtlasTheme.fontCaptionSmall, weight: .bold, design: .monospaced))
                            .foregroundStyle(item.isXDROverdriveEnabled ? AtlasTheme.cobaltDark : AtlasTheme.textMuted)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(item.isXDROverdriveEnabled ? AtlasTheme.electricLime : AtlasTheme.surfaceCard)
                            .overlay(
                                Rectangle().stroke(
                                    item.isXDROverdriveEnabled ? AtlasTheme.electricLime : AtlasTheme.borderMedium,
                                    lineWidth: AtlasTheme.borderWidth
                                )
                            )
                    }
                    .buttonStyle(.plain)
                    .help("XDR / Hardware Brightness Overdrive (Boost peak nits)")
                }
            }
        }
    }

    private func commitBrightnessInput() {
        isEditingBrightness = false
        if let val = Double(brightnessInputText) {
            let clamped = max(0.0, min(100.0, val)) / 100.0
            store.setBrightness(item, clamped, immediate: true)
        }
    }
}
#endif
