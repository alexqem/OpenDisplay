#if os(macOS) && arch(arm64)
import AppKit
import CoreGraphics

/// Protocol matching macOS private OSDUIHelper XPC service interface
@objc private protocol OSDUIHelperProtocol {
    func showImage(
        _ img: Int,
        onDisplayID displayID: CGDirectDisplayID,
        priority: UInt32,
        msecUntilFade: UInt32,
        filledChiclets: UInt32,
        totalChiclets: UInt32,
        locked: Bool
    )
}

/// Controller for displaying native macOS On-Screen Display (OSD) HUD overlays
public final class NativeOSDController: @unchecked Sendable {
    public static let shared = NativeOSDController()

    private init() {}

    /// Display the native brightness OSD chiclet HUD on the specified display
    /// - Parameters:
    ///   - percentage: Brightness percentage 0...100
    ///   - displayID: Target CGDirectDisplayID
    public func showBrightnessHUD(percentage: Double, for displayID: CGDirectDisplayID) {
        let clamped = min(max(percentage, 0.0), 100.0)
        let total = OSDConstants.totalChiclets
        let filled = UInt32((clamped / 100.0 * Double(total)).rounded())

        let connection = NSXPCConnection(machServiceName: OSDConstants.serviceName, options: [])
        connection.remoteObjectInterface = NSXPCInterface(with: OSDUIHelperProtocol.self)
        connection.resume()

        let proxy = connection.remoteObjectProxyWithErrorHandler { _ in
            // Handle XPC delivery errors quietly
        }

        if let helper = proxy as? OSDUIHelperProtocol {
            helper.showImage(
                OSDConstants.imageBrightness,
                onDisplayID: displayID,
                priority: OSDConstants.defaultPriority,
                msecUntilFade: OSDConstants.defaultFadeMs,
                filledChiclets: filled,
                totalChiclets: total,
                locked: false
            )
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + OSDConstants.connectionInvalidateDelaySeconds) {
            connection.invalidate()
        }
    }
}
#endif
