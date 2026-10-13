#if os(macOS) && arch(arm64)
import AppKit
import SwiftUI

/// Status Bar Item Controller hosting SwiftUI App Menu Popover
public final class MenuBarController: NSObject {
    private var statusItem: NSStatusItem?
    private let popover = NSPopover()

    public override init() {
        super.init()
        setupStatusItem()
        setupPopover()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "display.2", accessibilityDescription: "OpenDisplay")
            button.target = self
            button.action = #selector(togglePopover)
        }
    }

    private func setupPopover() {
        popover.contentSize = NSSize(width: 380, height: 480)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: AppMenuView())
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}
#endif
