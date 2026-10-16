#if os(macOS) && arch(arm64)
import AppKit
import CoreImage
import CoreGraphics
import ScreenCaptureKit

/// Panel sizing and placement constants for the floating PiP window
public enum PipPanelConstants {
    public static let panelWidth: CGFloat = 360
    public static let panelHeight: CGFloat = 203
    public static let panelOriginX: CGFloat = 240
    public static let panelOriginY: CGFloat = 240
}

/// Coordinates a single ScreenCaptureKit stream into a floating always-on-top PiP panel
@available(macOS 12.3, *)
public final class PipStreamManager: @unchecked Sendable {
    public static let shared = PipStreamManager()

    private let engine = PipCaptureEngine()
    private let renderContext = CIContext()
    private let stateLock = NSLock()
    private var panel: PipWindowPanel?
    private var imageView: NSImageView?
    public private(set) var activeDisplayID: CGDirectDisplayID?
    public private(set) var activeWindowID: CGWindowID?
    private var currentOpacity: CGFloat = 1.0
    private var currentClickThrough: Bool = false

    private init() {}

    /// Whether a PiP stream is currently running
    public var isActive: Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        return activeDisplayID != nil || activeWindowID != nil
    }

    /// Start streaming a display into the floating PiP panel
    public func start(displayID: CGDirectDisplayID) {
        Task { await startStreamingDisplay(displayID: displayID) }
    }

    /// Start streaming a specific window into the floating PiP panel
    public func start(windowID: CGWindowID) {
        Task { await startStreamingWindow(windowID: windowID) }
    }

    /// Adjust opacity of the running floating panel (0.1 ... 1.0)
    public func setOpacity(_ opacity: CGFloat) {
        currentOpacity = opacity
        Task { @MainActor in
            self.panel?.setOpacity(opacity)
        }
    }

    /// Set click-through (pass-through mouse events)
    public func setClickThrough(_ enabled: Bool) {
        currentClickThrough = enabled
        Task { @MainActor in
            self.panel?.setClickThrough(enabled)
        }
    }

    /// Enumerate all shareable application windows for user selection
    public func getShareableWindows() async -> [PipWindowTarget] {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            return content.windows.compactMap { window in
                guard window.frame.width > 50, window.frame.height > 50 else { return nil }
                let title = window.title ?? ""
                let app = window.owningApplication?.applicationName ?? "Unknown"
                guard !title.isEmpty || !app.isEmpty else { return nil }
                return PipWindowTarget(id: window.windowID, title: title, appName: app)
            }
        } catch {
            return []
        }
    }

    /// Stop the active stream and close the panel
    public func stop() {
        Task { await stopStreaming() }
    }

    private func startStreamingDisplay(displayID: CGDirectDisplayID) async {
        stateLock.lock()
        if activeDisplayID != nil || activeWindowID != nil {
            stateLock.unlock()
            return
        }
        activeDisplayID = displayID
        stateLock.unlock()

        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            guard let target = content.displays.first(where: { $0.displayID == displayID }) else {
                await clearActiveState()
                return
            }
            engine.onFrame = { [weak self] buffer in self?.renderFrame(buffer) }
            try await engine.startCapture(display: target)
            await showPanel()
        } catch {
            await clearActiveState()
        }
    }

    private func startStreamingWindow(windowID: CGWindowID) async {
        stateLock.lock()
        if activeDisplayID != nil || activeWindowID != nil {
            stateLock.unlock()
            return
        }
        activeWindowID = windowID
        stateLock.unlock()

        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            guard let target = content.windows.first(where: { $0.windowID == windowID }) else {
                await clearActiveState()
                return
            }
            engine.onFrame = { [weak self] buffer in self?.renderFrame(buffer) }
            try await engine.startCapture(window: target)
            await showPanel()
        } catch {
            await clearActiveState()
        }
    }

    private func stopStreaming() async {
        try? await engine.stopCapture()
        engine.onFrame = nil
        await MainActor.run {
            imageView?.image = nil
            panel?.orderOut(nil)
            panel = nil
            imageView = nil
        }
        await clearActiveState()
    }

    private func clearActiveState() async {
        stateLock.lock()
        activeDisplayID = nil
        activeWindowID = nil
        stateLock.unlock()
    }

    @MainActor
    private func showPanel() {
        guard panel == nil else { return }
        let newPanel = PipWindowPanel(contentRect: NSRect(
            x: PipPanelConstants.panelOriginX,
            y: PipPanelConstants.panelOriginY,
            width: PipPanelConstants.panelWidth,
            height: PipPanelConstants.panelHeight
        ))
        newPanel.setOpacity(currentOpacity)
        newPanel.setClickThrough(currentClickThrough)
        let newView = NSImageView(frame: NSRect(origin: .zero, size: newPanel.contentView?.frame.size ?? .zero))
        newView.autoresizingMask = [.width, .height]
        newView.imageScaling = .scaleProportionallyUpOrDown
        newPanel.contentView?.addSubview(newView)
        newPanel.makeKeyAndOrderFront(nil)
        panel = newPanel
        imageView = newView
    }

    private func renderFrame(_ buffer: CVImageBuffer) {
        let image = CIImage(cvImageBuffer: buffer)
        guard let cgImage = renderContext.createCGImage(image, from: image.extent) else { return }
        let size = image.extent.size
        Task { @MainActor [weak self] in
            self?.imageView?.image = NSImage(cgImage: cgImage, size: size)
        }
    }
}
#endif
