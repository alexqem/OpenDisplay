#if os(macOS) && arch(arm64)
import Foundation
import CoreGraphics

/// Controller managing software disconnection, blanking, sleep, and rotation of displays
public final class DisplayPowerStateController: @unchecked Sendable {
    public static let shared = DisplayPowerStateController()

    private var disconnectedDisplays = Set<CGDirectDisplayID>()
    private let lock = NSLock()

    private init() {}

    /// Check if display is currently software-disconnected
    public func isDisconnected(displayID: CGDirectDisplayID) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return disconnectedDisplays.contains(displayID)
    }

    /// Software disconnect / blank screen down to absolute black using gamma LUT
    public func disconnectDisplay(displayID: CGDirectDisplayID) -> Bool {
        do {
            try GammaDimmingEngine.applyGammaDimming(displayID: displayID, level: 0.0)
            lock.lock()
            disconnectedDisplays.insert(displayID)
            lock.unlock()
            return true
        } catch {
            return false
        }
    }

    /// Reconnect display (restore identity linear gamma)
    public func reconnectDisplay(displayID: CGDirectDisplayID) -> Bool {
        do {
            try GammaDimmingEngine.restoreGamma(displayID: displayID)
            lock.lock()
            disconnectedDisplays.remove(displayID)
            lock.unlock()
            return true
        } catch {
            return false
        }
    }

    /// Rotate display by explicit angle enum using SkyLight engine
    public func setDisplayOrientation(displayID: CGDirectDisplayID, angle: DisplayRotationAngle) -> Bool {
        return SkyLightModeEngine.shared.setRotation(displayID: displayID, degrees: angle.rawValue)
    }
}
#endif
