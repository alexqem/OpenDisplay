#if os(macOS) && arch(arm64)
import SwiftUI

/// Audio volume slider, mute toggle, and status readout for DDC-capable external monitors
public struct DisplayAudioControlView: View {
    @ObservedObject public var item: DisplayItemModel
    @ObservedObject private var store = WorkspaceStore.shared

    public init(item: DisplayItemModel) {
        self.item = item
    }

    public var body: some View {
        if !item.isBuiltin && !item.isVirtual && item.capabilities.supportsBasicAudio {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label("Volume", systemImage: item.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: AtlasTheme.fontBodySmall, weight: .medium))
                        .foregroundStyle(Color.primary)

                    Spacer()

                    Text(item.isMuted ? "Muted" : "\(Int(item.volume * 100))%")
                        .font(.system(size: AtlasTheme.fontCaptionMedium, weight: .medium))
                        .foregroundStyle(item.isMuted ? Color.orange : Color.secondary)
                }

                HStack(spacing: 8) {
                    AtlasIconButton(systemName: item.isMuted ? "speaker.slash.fill" : "speaker.wave.2") {
                        store.toggleMute(item)
                    }
                    .disabled(item.isDisconnected)

                    Slider(
                        value: Binding(
                            get: { item.volume },
                            set: { store.setVolume(item, $0, immediate: false) }
                        ),
                        in: 0...1
                    )
                    .controlSize(.small)
                    .disabled(item.isDisconnected || item.isMuted)
                }
            }
        }
    }
}
#endif
