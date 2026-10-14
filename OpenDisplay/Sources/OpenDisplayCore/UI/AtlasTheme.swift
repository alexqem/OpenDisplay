#if os(macOS) && arch(arm64)
import SwiftUI
import AppKit

/// Atlas / TypeUI Swiss High-Precision Design System Tokens for OpenDisplay
/// Supports adaptive dynamic switching between Blueprint Light and Blueprint Dark Terminal
public enum AtlasTheme {

    /// Helper creating adaptive NSColor resolving dynamically based on system appearance
    public static func dynamicColor(light: NSColor, dark: NSColor) -> Color {
        return Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            let match = appearance.bestMatch(from: [.darkAqua, .aqua])
            return match == .darkAqua ? dark : light
        }))
    }

    // MARK: - Brand & Foreground (Adaptive)
    // Light: Electric Cobalt #1313ba | Dark: High-contrast Electric Blue #4f75ff
    public static let cobalt = dynamicColor(
        light: NSColor(red: 0x13 / 255.0, green: 0x13 / 255.0, blue: 0xBA / 255.0, alpha: 1.0),
        dark: NSColor(red: 0x4F / 255.0, green: 0x75 / 255.0, blue: 0xFF / 255.0, alpha: 1.0)
    )

    // Deep hover cobalt / dark terminal ink
    public static let cobaltDark = dynamicColor(
        light: NSColor(red: 0x0E / 255.0, green: 0x0E / 255.0, blue: 0x8C / 255.0, alpha: 1.0),
        dark: NSColor(red: 0x08 / 255.0, green: 0x08 / 255.0, blue: 0x20 / 255.0, alpha: 1.0)
    )

    // Secondary brand border and grid lines
    public static let cobaltSoft = dynamicColor(
        light: NSColor(red: 0xCA / 255.0, green: 0xCA / 255.0, blue: 0xF0 / 255.0, alpha: 1.0),
        dark: NSColor(red: 0x24 / 255.0, green: 0x2E / 255.0, blue: 0x66 / 255.0, alpha: 1.0)
    )

    // Soft brand background pill / chip
    public static let cobaltSofter = dynamicColor(
        light: NSColor(red: 0xE8 / 255.0, green: 0xE8 / 255.0, blue: 0xF8 / 255.0, alpha: 1.0),
        dark: NSColor(red: 0x16 / 255.0, green: 0x1C / 255.0, blue: 0x48 / 255.0, alpha: 1.0)
    )

    // MARK: - Semantic Typography Tokens
    public static let textPrimary = cobalt

    public static let textBody = dynamicColor(
        light: NSColor(red: 0x63 / 255.0, green: 0x63 / 255.0, blue: 0xC6 / 255.0, alpha: 1.0),
        dark: NSColor(red: 0xA5 / 255.0, green: 0xB4 / 255.0, blue: 0xFC / 255.0, alpha: 1.0)
    )

    public static let textMuted = dynamicColor(
        light: NSColor(red: 0x90 / 255.0, green: 0x90 / 255.0, blue: 0xCE / 255.0, alpha: 1.0),
        dark: NSColor(red: 0x6B / 255.0, green: 0x72 / 255.0, blue: 0xAF / 255.0, alpha: 1.0)
    )

    // MARK: - Accents & Status Badges
    public static let electricLime = Color(red: 0xED / 255.0, green: 0xFF / 255.0, blue: 0x45 / 255.0)  // #edff45

    public static let successGreen = dynamicColor(
        light: NSColor(red: 0x15 / 255.0, green: 0xA3 / 255.0, blue: 0x4A / 255.0, alpha: 1.0),
        dark: NSColor(red: 0x22 / 255.0, green: 0xC5 / 255.0, blue: 0x5E / 255.0, alpha: 1.0)
    )

    public static let successSoft = dynamicColor(
        light: NSColor(red: 0xEC / 255.0, green: 0xFD / 255.0, blue: 0xF3 / 255.0, alpha: 1.0),
        dark: NSColor(red: 0x05 / 255.0, green: 0x2E / 255.0, blue: 0x16 / 255.0, alpha: 1.0)
    )

    public static let warningOrange = dynamicColor(
        light: NSColor(red: 0xF9 / 255.0, green: 0x73 / 255.0, blue: 0x16 / 255.0, alpha: 1.0),
        dark: NSColor(red: 0xFB / 255.0, green: 0x92 / 255.0, blue: 0x3C / 255.0, alpha: 1.0)
    )

    public static let warningSoft = dynamicColor(
        light: NSColor(red: 0xFF / 255.0, green: 0xFA / 255.0, blue: 0xEB / 255.0, alpha: 1.0),
        dark: NSColor(red: 0x43 / 255.0, green: 0x14 / 255.0, blue: 0x07 / 255.0, alpha: 1.0)
    )

    // MARK: - Neutral Surfaces & 1px Structural Borders (Adaptive)
    public static let surfaceCard = dynamicColor(
        light: NSColor(red: 0xFB / 255.0, green: 0xFB / 255.0, blue: 0xFE / 255.0, alpha: 1.0),
        dark: NSColor(red: 0x0D / 255.0, green: 0x10 / 255.0, blue: 0x24 / 255.0, alpha: 1.0)
    )

    public static let surfaceHeader = dynamicColor(
        light: NSColor(red: 0xF4 / 255.0, green: 0xF4 / 255.0, blue: 0xFC / 255.0, alpha: 1.0),
        dark: NSColor(red: 0x08 / 255.0, green: 0x0A / 255.0, blue: 0x18 / 255.0, alpha: 1.0)
    )

    public static let borderDefault = cobaltSofter

    public static let borderMedium = dynamicColor(
        light: NSColor(red: 0xE0 / 255.0, green: 0xE0 / 255.0, blue: 0xF2 / 255.0, alpha: 1.0),
        dark: NSColor(red: 0x22 / 255.0, green: 0x2A / 255.0, blue: 0x54 / 255.0, alpha: 1.0)
    )

    // MARK: - Typography Scale Constants
    public static let fontCaptionSmall: CGFloat = 9.0
    public static let fontCaptionMedium: CGFloat = 10.0
    public static let fontBodySmall: CGFloat = 11.0
    public static let fontBodyMedium: CGFloat = 12.0
    public static let fontHeadline: CGFloat = 16.0
    public static let trackingTight: CGFloat = 1.0

    // MARK: - Geometry & Layout Constants
    public static let zeroRadius: CGFloat = 0.0
    public static let borderWidth: CGFloat = 1.0
    public static let popoverWidth: CGFloat = 420.0
    public static let popoverHeight: CGFloat = 660.0
    public static let maxScrollHeight: CGFloat = 520.0
    public static let pickerWidth: CGFloat = 120.0
    public static let pickerNarrowWidth: CGFloat = 72.0
    public static let sectionSpacing: CGFloat = 16.0
    public static let blueprintGridSpacing: CGFloat = 18.0
    public static let iconButtonSide: CGFloat = 22.0
    public static let pillCornerRadius: CGFloat = 9999.0
    public static let inlineSliderWidth: CGFloat = 90.0
    public static let percentLabelWidth: CGFloat = 34.0
    public static let switchWidth: CGFloat = 32.0
    public static let switchHeight: CGFloat = 18.0
    public static let switchThumbSize: CGFloat = 14.0
    public static let switchThumbPadding: CGFloat = 2.0
    public static let switchAnimationDuration: Double = 0.16
}
#endif
