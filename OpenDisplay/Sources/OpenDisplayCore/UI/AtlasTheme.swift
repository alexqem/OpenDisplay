#if os(macOS) && arch(arm64)
import SwiftUI
import AppKit

/// Apple Native macOS Glassmorphism (Vibrancy & Material) Design System Tokens for OpenDisplay
public enum AtlasTheme {

    /// Helper creating adaptive NSColor resolving dynamically based on system appearance
    public static func dynamicColor(light: NSColor, dark: NSColor) -> Color {
        return Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            let match = appearance.bestMatch(from: [.darkAqua, .aqua])
            return match == .darkAqua ? dark : light
        }))
    }

    // MARK: - Native Apple Accent (Refined Blue)
    public static let cobalt = Color.accentColor

    // Secondary active/hover states
    public static let cobaltDark = dynamicColor(
        light: NSColor.controlAccentColor,
        dark: NSColor.controlAccentColor
    )

    public static let cobaltSoft = dynamicColor(
        light: NSColor(white: 0.0, alpha: 0.10),
        dark: NSColor(white: 1.0, alpha: 0.15)
    )

    public static let cobaltSofter = dynamicColor(
        light: NSColor(white: 0.0, alpha: 0.05),
        dark: NSColor(white: 1.0, alpha: 0.08)
    )

    // MARK: - Semantic Native macOS Typography
    public static let textPrimary = Color.primary

    public static let textBody = Color.secondary

    public static let textMuted = dynamicColor(
        light: NSColor.tertiaryLabelColor,
        dark: NSColor.tertiaryLabelColor
    )

    // MARK: - Accents & Status Badges
    public static let electricLime = Color.accentColor

    public static let successGreen = dynamicColor(
        light: NSColor.systemGreen,
        dark: NSColor.systemGreen
    )

    public static let successSoft = dynamicColor(
        light: NSColor.systemGreen.withAlphaComponent(0.12),
        dark: NSColor.systemGreen.withAlphaComponent(0.20)
    )

    public static let warningOrange = dynamicColor(
        light: NSColor.systemOrange,
        dark: NSColor.systemOrange
    )

    public static let warningSoft = dynamicColor(
        light: NSColor.systemOrange.withAlphaComponent(0.12),
        dark: NSColor.systemOrange.withAlphaComponent(0.20)
    )

    // MARK: - Translucent Glass Materials & Native Borders
    public static let surfaceCard = dynamicColor(
        light: NSColor(white: 1.0, alpha: 0.65),
        dark: NSColor(white: 0.18, alpha: 0.55)
    )

    public static let surfaceHeader = dynamicColor(
        light: NSColor(white: 1.0, alpha: 0.40),
        dark: NSColor(white: 0.12, alpha: 0.40)
    )

    public static let borderDefault = dynamicColor(
        light: NSColor(white: 0.0, alpha: 0.08),
        dark: NSColor(white: 1.0, alpha: 0.12)
    )

    public static let borderMedium = dynamicColor(
        light: NSColor(white: 0.0, alpha: 0.12),
        dark: NSColor(white: 1.0, alpha: 0.18)
    )

    // MARK: - Typography Scale Constants
    public static let fontCaptionSmall: CGFloat = 10.0
    public static let fontCaptionMedium: CGFloat = 11.0
    public static let fontBodySmall: CGFloat = 12.0
    public static let fontBodyMedium: CGFloat = 13.0
    public static let fontHeadline: CGFloat = 15.0
    public static let trackingTight: CGFloat = 0.0

    // MARK: - Geometry & Layout Constants (macOS Native Fluid Radii)
    public static let zeroRadius: CGFloat = 0.0
    public static let cardRadius: CGFloat = 10.0
    public static let controlRadius: CGFloat = 6.0
    public static let borderWidth: CGFloat = 0.5
    public static let popoverWidth: CGFloat = 360.0
    public static let popoverHeight: CGFloat = 580.0
    public static let maxScrollHeight: CGFloat = 500.0
    public static let pickerWidth: CGFloat = 110.0
    public static let pickerNarrowWidth: CGFloat = 72.0
    public static let pickerMirrorWidth: CGFloat = 110.0
    public static let drawerPadding: CGFloat = 10.0
    public static let fontChevronSmall: CGFloat = 10.0
    public static let sectionSpacing: CGFloat = 12.0
    public static let blueprintGridSpacing: CGFloat = 18.0
    public static let iconButtonSide: CGFloat = 24.0
    public static let pillCornerRadius: CGFloat = 9999.0
    public static let inlineSliderWidth: CGFloat = 90.0
    public static let percentLabelWidth: CGFloat = 36.0
    public static let switchWidth: CGFloat = 32.0
    public static let switchHeight: CGFloat = 18.0
    public static let switchThumbSize: CGFloat = 14.0
    public static let switchThumbPadding: CGFloat = 2.0
    public static let switchAnimationDuration: Double = 0.16
}
#endif
