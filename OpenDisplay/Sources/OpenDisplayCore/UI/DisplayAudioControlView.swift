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
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("AUDIO VOLUME")
                        .font(.system(size: AtlasTheme.fontCaptionSmall, weight: .bold, design: .monospaced))
                        .foregroundStyle(AtlasTheme.textBody)

                    Spacer()

                    Text(item.isMuted ? "MUTED" : "\(Int(item.volume * 100))%")
                        .font(.system(size: AtlasTheme.fontCaptionSmall, weight: .bold, design: .monospaced))
                        .foregroundStyle(item.isMuted ? AtlasTheme.warningOrange : AtlasTheme.textMuted)
                }

                HStack(spacing: 6) {
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
                    .tint(AtlasTheme.cobalt)
                    .disabled(item.isDisconnected || item.isMuted)
                }
            }
        }
    }
}
#endif
