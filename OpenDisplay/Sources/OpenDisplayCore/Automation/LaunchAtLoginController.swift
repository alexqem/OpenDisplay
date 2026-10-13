#if os(macOS) && arch(arm64)
import Foundation
import ServiceManagement

/// Status of Login Item registration
public enum LaunchAtLoginStatus: Sendable {
    case enabled
    case disabled
    case requiresApproval
    case notFound
    case unsupported
}

/// Service managing application launch at user login via modern macOS 13+ SMAppService
@MainActor
public final class LaunchAtLoginController {
    public static let shared = LaunchAtLoginController()

    private init() {}

    /// Query current login status
    public var status: LaunchAtLoginStatus {
        if #available(macOS 13.0, *) {
            switch SMAppService.mainApp.status {
            case .enabled:
                return .enabled
            case .notRegistered:
                return .disabled
            case .requiresApproval:
                return .requiresApproval
            case .notFound:
                return .notFound
            @unknown default:
                return .disabled
            }
        } else {
            return .unsupported
        }
    }

    /// Check if launch at login is currently active
    public var isEnabled: Bool {
        return status == .enabled
    }

    /// Perform registration change with SMAppService
    private func updateRegistration(_ shouldRegister: Bool) -> Bool {
        if #available(macOS 13.0, *) {
            do {
                if shouldRegister {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
                return true
            } catch {
                return false
            }
        }
        return false
    }

    /// Register application to launch at user login
    @discardableResult
    public func enable() -> Bool {
        return updateRegistration(true)
    }

    /// Unregister application from login items
    @discardableResult
    public func disable() -> Bool {
        return updateRegistration(false)
    }

    /// Toggle launch at login state
    @discardableResult
    public func toggle() -> Bool {
        if isEnabled {
            disable()
            return false
        } else {
            enable()
            return true
        }
    }
}
#endif
