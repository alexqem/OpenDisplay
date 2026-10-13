#if os(macOS) && arch(arm64)
import SwiftUI

/// Atlas / TypeUI Swiss High-Precision Design System Tokens for OpenDisplay
public enum AtlasTheme {
    // Brand & Foreground
    public static let cobalt = Color(red: 0x13 / 255.0, green: 0x13 / 255.0, blue: 0xBA / 255.0)       // #1313ba
    public static let cobaltDark = Color(red: 0x0E / 255.0, green: 0x0E / 255.0, blue: 0x8C / 255.0)   // #0e0e8c
    public static let cobaltSoft = Color(red: 0xCA / 255.0, green: 0xCA / 255.0, blue: 0xF0 / 255.0)   // #cacaf0
    public static let cobaltSofter = Color(red: 0xE8 / 255.0, green: 0xE8 / 255.0, blue: 0xF8 / 255.0) // #e8e8f8

    // Typography & Slate Indigo
    public static let textPrimary = Color(red: 0x13 / 255.0, green: 0x13 / 255.0, blue: 0xBA / 255.0)
    public static let textBody = Color(red: 0x63 / 255.0, green: 0x63 / 255.0, blue: 0xC6 / 255.0)      // #6363c6
    public static let textMuted = Color(red: 0x90 / 255.0, green: 0x90 / 255.0, blue: 0xCE / 255.0)     // #9090ce

    // Accents & Badges
    public static let electricLime = Color(red: 0xED / 255.0, green: 0xFF / 255.0, blue: 0x45 / 255.0)  // #edff45
    public static let successGreen = Color(red: 0x15 / 255.0, green: 0xA3 / 255.0, blue: 0x4A / 255.0)  // #15a34a

    // Neutral Surfaces & 1px Structural Borders
    public static let surfaceCard = Color(red: 0xFB / 255.0, green: 0xFB / 255.0, blue: 0xFE / 255.0)   // #fbfbfe
    public static let surfaceHeader = Color(red: 0xF4 / 255.0, green: 0xF4 / 255.0, blue: 0xFC / 255.0) // #f4f4fc
    public static let borderDefault = Color(red: 0xE8 / 255.0, green: 0xE8 / 255.0, blue: 0xF8 / 255.0) // #e8e8f8
    public static let borderMedium = Color(red: 0xE0 / 255.0, green: 0xE0 / 255.0, blue: 0xF2 / 255.0)  // #e0e0f2

    // Geometry Constants
    public static let zeroRadius: CGFloat = 0.0
    public static let pillRadius: CGFloat = 9999.0
    public static let borderWidth: CGFloat = 1.0
    public static let popoverWidth: CGFloat = 400.0
}
#endif
