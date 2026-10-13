import Foundation

/// Strongly typed errors for luminance, gamma, and XDR overdrive operations
public enum LuminanceError: Error, Sendable {
    case invalidTableSize(UInt32)
    case gammaApplicationFailed(Int32)
    case edrNotSupported
    case coreBrightnessClientUnavailable
    case operationFailed(reason: String)
}

extension LuminanceError: Equatable {
    public static func == (lhs: LuminanceError, rhs: LuminanceError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidTableSize(let a), .invalidTableSize(let b)): return a == b
        case (.gammaApplicationFailed(let a), .gammaApplicationFailed(let b)): return a == b
        case (.edrNotSupported, .edrNotSupported): return true
        case (.coreBrightnessClientUnavailable, .coreBrightnessClientUnavailable): return true
        case (.operationFailed(let a), .operationFailed(let b)): return a == b
        default: return false
        }
    }
}
