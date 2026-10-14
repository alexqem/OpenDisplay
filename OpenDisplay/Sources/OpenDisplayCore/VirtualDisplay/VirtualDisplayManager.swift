#if os(macOS) && arch(arm64)
import Foundation
import CoreGraphics

/// Thread-safe lifecycle registry owning active Virtual Display instances so they stay alive after creation
public final class VirtualDisplayManager: @unchecked Sendable {
    public static let shared = VirtualDisplayManager()

    private var controllers: [VirtualDisplayController] = []
    private let lock = NSLock()

    private init() {}

    /// Take ownership of a created virtual display; duplicates by displayID are ignored
    public func register(_ controller: VirtualDisplayController) {
        lock.lock()
        defer { lock.unlock() }
        guard !controllers.contains(where: { $0.displayID == controller.displayID }) else { return }
        controllers.append(controller)
    }

    /// Tear down a virtual display by releasing its owning controller
    @discardableResult
    public func remove(displayID: CGDirectDisplayID) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard let index = controllers.firstIndex(where: { $0.displayID == displayID }) else {
            return false
        }
        controllers.remove(at: index)
        return true
    }

    /// Snapshot of all live virtual display controllers
    public func allControllers() -> [VirtualDisplayController] {
        lock.lock()
        defer { lock.unlock() }
        return controllers
    }

    /// Membership query by display ID
    public func contains(displayID: CGDirectDisplayID) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return controllers.contains(where: { $0.displayID == displayID })
    }
}
#endif
