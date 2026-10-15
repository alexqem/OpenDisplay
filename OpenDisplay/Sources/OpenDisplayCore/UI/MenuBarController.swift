#if os(macOS) && arch(arm64)
import AppKit
import SwiftUI

/// Status Bar Item Controller hosting SwiftUI App Menu Popover with robust fallback rendering
public final class MenuBarController: NSObject {
    private var statusItem: NSStatusItem?
    private let popover = NSPopover()

    public override init() {
        super.init()
        AppLogger.shared.log("MenuBarController initializing status item...")
        setupStatusItem()
        setupPopover()
    }

    private func setupStatusItem() {
        // Use variable length status item on system status bar
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.statusItem = item

        guard let button = item.button else {
            AppLogger.shared.log("ERROR: NSStatusItem button is nil!")
            return
        }

        // Try SF Symbol first; fallback to text if SF Symbols fail
        if let symbolImage = NSImage(systemSymbolName: "display.2", accessibilityDescription: "OpenDisplay") {
            symbolImage.isTemplate = true
            button.image = symbolImage
            button.imagePosition = .imageLeft
        } else {
            button.title = "OD"
        }

        // Set tool tip and action
        button.toolTip = "OpenDisplay - Display Manager"
        button.target = self
        button.action = #selector(togglePopover)

        AppLogger.shared.log("MenuBarController status item created successfully: frame=\(button.frame)")
    }

    private func setupPopover() {
        popover.contentSize = NSSize(width: AtlasTheme.popoverWidth, height: AtlasTheme.popoverHeight)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: AppMenuView())
        AppLogger.shared.log("MenuBarController popover configured")
    }

    @objc public func togglePopover() {
        guard let button = statusItem?.button else {
            AppLogger.shared.log("WARNING: togglePopover called but button is nil")
            return
        }
        if popover.isShown {
            AppLogger.shared.log("Closing popover")
            popover.performClose(nil)
        } else {
            AppLogger.shared.log("Showing popover at status item: \(button.bounds)")
            // Bring application to front when opening popover
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    /// Explicitly show the popover (useful on app launch so user immediately sees UI)
    public func showPopover() {
        guard let button = statusItem?.button else { return }
        if !popover.isShown {
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}
#endif
