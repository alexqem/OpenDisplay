#if os(macOS) && arch(arm64)
import SwiftUI

/// Primary luminance slider, steppers, and direct numeric input field
public struct DisplayLuminanceControlView: View {
    @ObservedObject public var item: DisplayItemModel
    @ObservedObject private var store = WorkspaceStore.shared

    public init(item: DisplayItemModel) {
        self.item = item
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("Brightness", systemImage: "sun.max.fill")
                    .font(.system(size: AtlasTheme.fontBodySmall, weight: .medium))
                    .foregroundStyle(Color.primary)

                Spacer()

                if item.isEditingBrightness {
                    TextField(
                        "",
                        text: Binding(
                            get: { item.brightnessInputText },
                            set: { item.brightnessInputText = $0 }
                        ),
                        onCommit: commitBrightnessInput
                    )
                    .textFieldStyle(.plain)
                    .font(.system(size: AtlasTheme.fontCaptionMedium, weight: .semibold))
                    .foregroundStyle(Color.primary)
                    .frame(width: 42)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.primary.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                } else {
                    Button(action: {
                        item.brightnessInputText = "\(Int(item.brightness * 100))"
                        item.isEditingBrightness = true
                    }) {
                        Text("\(Int(item.brightness * 100))%")
                            .font(.system(size: AtlasTheme.fontCaptionMedium, weight: .medium))
                            .foregroundStyle(Color.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.primary.opacity(0.06))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .help("Click to enter exact percentage")
                }
            }

            HStack(spacing: 8) {
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
                .controlSize(.small)
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
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(item.isXDROverdriveEnabled ? .white : Color.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(item.isXDROverdriveEnabled ? Color.accentColor : Color.primary.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .help("Boost peak hardware brightness")
                }
            }
        }
    }

    private func commitBrightnessInput() {
        item.isEditingBrightness = false
        if let val = Double(item.brightnessInputText) {
            let clamped = max(0.0, min(100.0, val)) / 100.0
            store.setBrightness(item, clamped, immediate: true)
        }
    }
}
#endif
