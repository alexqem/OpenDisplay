import Foundation
#if os(macOS) && arch(arm64)
import AppKit
import OpenDisplayCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppLogger.shared.log("OpenDisplay launching...")
        AppLogger.shared.log("System version: \(ProcessInfo.processInfo.operatingSystemVersionString)")

        // Keep app alive as an accessory item in the status bar
        NSApp.setActivationPolicy(.accessory)
        menuBarController = MenuBarController()

        // Automatically display popover on first launch after small delay so user immediately sees UI
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            AppLogger.shared.log("Auto-opening popover on launch")
            self?.menuBarController?.showPopover()
        }

        AppLogger.shared.log("OpenDisplay initialization finished")
    }

    func applicationWillTerminate(_ notification: Notification) {
        AppLogger.shared.log("OpenDisplay terminating...")
    }
}

// Start NSApplication lifecycle
AppLogger.shared.log("Starting OpenDisplayApp executable...")
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
#else
print("OpenDisplay is engineered exclusively for Apple Silicon ARM64 on macOS.")
#endif
