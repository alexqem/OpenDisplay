#if os(macOS) && arch(arm64)
import Foundation
import AppKit

/// Borderless, floating PiP display panel
public final class PipWindowPanel: NSPanel {

    public init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.titled, .resizable, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        self.level = .floating
        self.isFloatingPanel = true
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.isMovableByWindowBackground = true
        self.backgroundColor = .black
        self.hasShadow = true
        self.isOpaque = false
    }

    /// Set panel opacity (0.1 ... 1.0)
    public func setOpacity(_ opacity: CGFloat) {
        self.alphaValue = max(0.1, min(1.0, opacity))
    }

    /// Set click-through behavior (pass mouse events to windows beneath)
    public func setClickThrough(_ enabled: Bool) {
        self.ignoresMouseEvents = enabled
    }
}
#endif
