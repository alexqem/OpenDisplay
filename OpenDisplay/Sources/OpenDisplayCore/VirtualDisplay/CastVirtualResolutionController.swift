#if os(macOS) && arch(arm64)
import Foundation
import CoreGraphics

/// Drives the "Ultra Sharp Cast" feature: a hidden virtual display acts as the
/// mirror-group master so AirPlay destinations stream at its framebuffer
/// resolution instead of AirPlay's low default timing.
///
/// Verified live on Apple Silicon (cast display, vendor 0x6161706c / model 0x61697270):
/// - 2560x1440@60 virtual master -> cast streams 2560x1440 while UI stays at 1280x720@2x
/// - 3840x2160@30 is accepted by AirPlay when forced via CGSConfigureDisplayMode
/// - CGConfigureDisplayWithDisplayMode silently refuses modes above 1440p, hence the
///   SkyLight mode-number path (BetterDisplay parity)
public final class CastVirtualResolutionController: @unchecked Sendable {
    public static let shared = CastVirtualResolutionController()

    /// Cast sharpness tiers offered by the feature
    public enum SharpnessTier: String, CaseIterable, Sendable {
        case quadHD = "2560x1440"
        case ultraHD = "3840x2160"

        public var pixelWidth: Int {
            switch self {
            case .quadHD: return 2560
            case .ultraHD: return 3840
            }
        }

        public var pixelHeight: Int {
            switch self {
            case .quadHD: return 1440
            case .ultraHD: return 2160
            }
        }

        public var refreshRate: Double { self == .ultraHD ? 30.0 : 60.0 }

        public var label: String {
            switch self {
            case .quadHD: return "1440p Sharp"
            case .ultraHD: return "4K Sharp"
            }
        }
    }

    private static let lock = NSLock()
    private var controller: VirtualDisplayController?
    private var activeCastID: CGDirectDisplayID = 0

    public private(set) var tier: SharpnessTier = .quadHD

    /// Whether the virtual resolution master is currently attached to the given cast display
    public func isActive(for castID: CGDirectDisplayID) -> Bool {
        Self.lock.lock()
        defer { Self.lock.unlock() }
        return controller != nil && activeCastID == castID
    }

    /// Create the virtual master, force its top mode, and mirror the cast display onto it
    @discardableResult
    public func enable(castID: CGDirectDisplayID, tier: SharpnessTier) -> Bool {
        Self.lock.lock()
        defer { Self.lock.unlock() }
        guard controller == nil else { return false }

        let config = VirtualDisplayConfig(
            name: "OpenDisplay CastSharp",
            aspectPreset: .ratio16_9,
            baseWidth: UInt32(tier.pixelWidth),
            refreshRate: tier.refreshRate,
            isHiDPI: true
        )
        guard let virtual = VirtualDisplayController(config: config), virtual.displayID != 0 else {
            return false
        }
        controller = virtual
        activeCastID = castID
        self.tier = tier

        // Let WindowServer settle the new display before configuration transactions
        Thread.sleep(forTimeInterval: 0.8)

        // Force the top native mode; the public CG path silently no-ops above 1440p
        let modes = SkyLightModeEngine.shared.availableModes(for: virtual.displayID)
        if let top = modes.max(by: { $0.pixelWidth * $0.pixelHeight < $1.pixelWidth * $1.pixelHeight }) {
            _ = SkyLightModeEngine.shared.setDisplayMode(displayID: virtual.displayID, modeNumber: top.modeNumber)
            Thread.sleep(forTimeInterval: 0.4)
        }

        // Cast display mirrors the virtual master and inherits its framebuffer timing
        let mirrored = DisplayMirrorController.enableMirror(sourceID: virtual.displayID, targetID: castID)
        if !mirrored {
            teardownLocked()
            return false
        }
        Thread.sleep(forTimeInterval: 0.4)
        return true
    }

    /// Tear down the virtual master and restore the cast display to standalone AirPlay timing
    @discardableResult
    public func disable() -> Bool {
        Self.lock.lock()
        defer { Self.lock.unlock() }
        guard controller != nil else { return false }
        teardownLocked()
        return true
    }

    /// Auto-cleanup path: cast display vanished (AirPlay ended) while the virtual master lives
    public func teardownIfOrphaned(onlineCastIDs: [CGDirectDisplayID]) {
        Self.lock.lock()
        defer { Self.lock.unlock() }
        guard controller != nil else { return }
        if !onlineCastIDs.contains(activeCastID) {
            teardownLocked()
        }
    }

    /// Must be called while holding Self.lock
    private func teardownLocked() {
        if activeCastID != 0 {
            _ = DisplayMirrorController.disableMirror(for: activeCastID)
        }
        // Releasing the CGVirtualDisplay instance destroys the virtual screen
        controller = nil
        activeCastID = 0
    }
}
#endif
