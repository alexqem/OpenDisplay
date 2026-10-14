import Foundation
import CoreGraphics

/// All 15 supported Aspect Ratio Presets for Virtual Displays (Dummy Screens)
public enum DisplayAspectPreset: String, CaseIterable, Sendable {
    case ratio16_9       = "16:9"
    case ratio16_10      = "16:10"
    case ratio21_3_9     = "21.3:9"
    case ratio21_5_9     = "21.5:9"
    case ratio24_10      = "24:10"
    case ratio32_9       = "32:9"
    case ratio32_10      = "32:10"
    case ratio4_3        = "4:3"
    case ratio3_2        = "3:2"
    case ratio5_4        = "5:4"
    case ratio1_1        = "1:1"
    case ratio14_3_10    = "14.3:10"
    case ratio14_4_10    = "14.4:10"
    case ratio15_2_10    = "15.2:10"
    case ratio17_9       = "17:9"

    /// Height factor relative to width: height = width * heightMultiplier
    public var heightMultiplier: Double {
        switch self {
        case .ratio16_9:    return 9.0 / 16.0
        case .ratio16_10:   return 10.0 / 16.0
        case .ratio21_3_9:  return 9.0 / 21.3
        case .ratio21_5_9:  return 9.0 / 21.5
        case .ratio24_10:   return 10.0 / 24.0
        case .ratio32_9:    return 9.0 / 32.0
        case .ratio32_10:   return 10.0 / 32.0
        case .ratio4_3:     return 3.0 / 4.0
        case .ratio3_2:     return 2.0 / 3.0
        case .ratio5_4:     return 4.0 / 5.0
        case .ratio1_1:     return 1.0
        case .ratio14_3_10: return 10.0 / 14.3
        case .ratio14_4_10: return 10.0 / 14.4
        case .ratio15_2_10: return 10.0 / 15.2
        case .ratio17_9:    return 9.0 / 17.0
        }
    }

    /// Calculate integer dimensions without fractional truncation
    public func dimensions(forWidth width: UInt32) -> (width: UInt32, height: UInt32) {
        let h = UInt32((Double(width) * heightMultiplier).rounded())
        return (width, h)
    }
}

/// Boundary limits and default identifiers for CoreDisplay Virtual Displays
public enum VirtualDisplayLimits {
    public static let maxPixelsWide: UInt32 = 7680
    public static let maxPixelsHigh: UInt32 = 4320
    public static let defaultVendorID: UInt32 = 0xF0F0
    public static let defaultProductID: UInt32 = 0x0D0D
    public static let defaultRefreshRate: Double = 60.0
    public static let hiDPIScaleFactor: UInt32 = 2
    public static let standardRefreshRates: [Double] = [120.0, 75.0, 60.0, 50.0]
}

/// Constants for macOS OSD (On-Screen Display) brightness overlay via OSDUIHelper XPC
public enum OSDConstants {
    public static let serviceName: String = "com.apple.OSDUIHelper"
    public static let totalChiclets: UInt32 = 16
    public static let imageBrightness: Int = 1
    public static let defaultPriority: UInt32 = 500
    public static let defaultFadeMs: UInt32 = 1500
    public static let connectionInvalidateDelaySeconds: Double = 2.0
}

/// Constants for System Media Keys and NX Event Tap Handling
public enum MediaKeyConstants {
    public static let sysDefinedEventTypeRaw: UInt32 = 14
    public static let auxControlButtonsSubtype: Int16 = 8
    public static let keyTypeBrightnessUp: Int = 2
    public static let keyTypeBrightnessDown: Int = 3
    public static let keyCodeMask: Int = 0xFFFF0000
    public static let keyFlagsMask: Int = 0x0000FFFF
    public static let keyStateMask: Int = 0xFF00
    public static let keyStateDown: Int = 0x0A
    public static let keyCodeShift: Int = 16
    public static let keyStateShift: Int = 8
    public static let brightnessStep: Double = 0.05
}

/// Constants for Display Arrangement and Canvas Positioning
public enum ArrangementConstants {
    public static let defaultTimeoutSeconds: Double = 10.0
    public static let originX: Int32 = 0
    public static let originY: Int32 = 0
}

/// Constants for Display Mirroring
public enum MirrorConstants {
    public static let nullDirectDisplay: CGDirectDisplayID = 0
}

/// Constants for Display Presets and Automation
public enum PresetConstants {
    public static let defaultIconName: String = "display"
}

/// Constants for Ambient / Built-in Display Brightness Synchronization
public enum AutoBrightnessConstants {
    public static let defaultPollingIntervalSeconds: Double = 2.0
    public static let defaultSensitivity: Double = 1.0
    public static let minSensitivity: Double = 0.5
    public static let maxSensitivity: Double = 1.5
    public static let minBrightness: Double = 0.0
    public static let maxBrightness: Double = 1.0
    public static let changeThreshold: Double = 0.01
    public static let nanosecondsPerSecond: UInt64 = 1_000_000_000
    public static let uninitializedBrightnessSentinel: Double = -1.0
}

/// Supported Display Orientation Angles
public enum DisplayRotationAngle: Int32, CaseIterable, Sendable {
    case standard      = 0
    case rotate90      = 90
    case rotate180     = 180
    case rotate270     = 270
}
