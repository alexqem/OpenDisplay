import Foundation
#if os(macOS) && arch(arm64)
import AppKit
import OpenDisplayCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as a menu bar accessory application without showing in Dock
        NSApp.setActivationPolicy(.accessory)
        menuBarController = MenuBarController()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
#else
print("OpenDisplay is engineered exclusively for Apple Silicon ARM64 on macOS.")
#endif
