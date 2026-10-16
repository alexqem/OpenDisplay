#if os(macOS) && arch(arm64)
import AppKit
import CoreGraphics

/// Controller managing black overlay windows to hide the MacBook camera notch
@MainActor
public final class NotchOverlayManager {
    public static let shared = NotchOverlayManager()

    private var activeOverlays: [CGDirectDisplayID: NSWindow] = [:]
    private var screenObserver: NSObjectProtocol?

    private init() {
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.repositionOverlays()
            }
        }
    }

    deinit {
        if let observer = screenObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    /// Resolve screen by displayID
    private static func findScreen(for displayID: CGDirectDisplayID) -> NSScreen? {
        return NSScreen.screens.first(where: {
            ($0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID) == displayID
        })
    }

    /// Calculate notch overlay geometry if safe area top inset is present
    private static func calculateNotchFrame(for screen: NSScreen) -> NSRect? {
        let notchHeight = screen.safeAreaInsets.top
        guard notchHeight > 0 else { return nil }

        return NSRect(
            x: screen.frame.minX,
            y: screen.frame.maxY - notchHeight,
            width: screen.frame.width,
            height: notchHeight
        )
    }

    /// Check if the display physically has a camera notch in safeAreaInsets
    public static func hasPhysicalNotch(for displayID: CGDirectDisplayID) -> Bool {
        guard let screen = findScreen(for: displayID) else { return false }
        return screen.safeAreaInsets.top > 0
    }

    /// Check if display is currently covered with an overlay
    public func isOverlayActive(for displayID: CGDirectDisplayID) -> Bool {
        return activeOverlays[displayID] != nil
    }

    /// Toggle display notch overlay (shows black bar across menu bar / top safe area)
    public func toggleNotchOverlay(for displayID: CGDirectDisplayID) -> Bool {
        if isOverlayActive(for: displayID) {
            hideOverlay(for: displayID)
            return false
        } else {
            showOverlay(for: displayID)
            return isOverlayActive(for: displayID)
        }
    }

    /// Display a notch black-out overlay bar across the top safe area
    public func showOverlay(for displayID: CGDirectDisplayID) {
        guard let screen = Self.findScreen(for: displayID),
              let frame = Self.calculateNotchFrame(for: screen) else {
            return
        }

        hideOverlay(for: displayID)

        let window = NSWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false,
            screen: screen
        )

        window.isReleasedWhenClosed = false
        window.backgroundColor = .black
        window.level = .screenSaver
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        window.isOpaque = true
        window.hasShadow = false
        window.orderFront(nil)

        activeOverlays[displayID] = window
    }

    /// Remove overlay for a specific display
    public func hideOverlay(for displayID: CGDirectDisplayID) {
        if let window = activeOverlays.removeValue(forKey: displayID) {
            window.close()
        }
    }

    /// Recalculate frame geometry on display reconfiguration
    private func repositionOverlays() {
        var staleIDs: [CGDirectDisplayID] = []

        for (displayID, window) in activeOverlays {
            guard let screen = Self.findScreen(for: displayID),
                  let frame = Self.calculateNotchFrame(for: screen) else {
                window.close()
                staleIDs.append(displayID)
                continue
            }

            window.setFrame(frame, display: true)
        }

        for id in staleIDs {
            activeOverlays.removeValue(forKey: id)
        }
    }
}
#endif
