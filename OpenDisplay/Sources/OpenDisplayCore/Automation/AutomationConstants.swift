import Foundation

/// Constants for embedded local HTTP automation server and CLI
public enum AutomationConstants {
    public static let defaultHttpPort: UInt16 = 18080
    public static let maxRequestBodyLength: Int = 8192
    public static let contentTypeJson: String = "application/json"
    public static let serverName: String = "OpenDisplay-Engine/1.0"

    // HTTP Status Codes
    public static let statusOk: Int = 200
    public static let statusCreated: Int = 201
    public static let statusBadRequest: Int = 400
    public static let statusNotFound: Int = 404

    // CLI Default Targets
    public static let cliDefaultTargetAll: String = "all"
    public static let cliDefaultTargetActive: String = "active"
    public static let cliDefaultDegrees: Int32 = 0
}
