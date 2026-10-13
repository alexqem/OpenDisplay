import Foundation

/// Constants for Command-Line Interface and Automation
public enum AutomationConstants {
    // CLI Default Flags and Arguments
    public static let cliDefaultTargetAll: String = "all"
    public static let cliDefaultTargetActive: String = "active"
    public static let cliDefaultVirtualName: String = "OpenDisplay Virtual"
    public static let cliDefaultAspect: String = "16:9"
    public static let cliDefaultVirtualWidth: UInt32 = 3840
    public static let cliDefaultDegrees: Int32 = 0
    public static let cliDefaultBrightnessProperty: String = "brightness"
    public static let cliDefaultBrightnessValue: String = "100"

    // Flag prefixes
    public static let flagTarget: String = "target"
    public static let flagProperty: String = "property"
    public static let flagName: String = "name"
    public static let flagAspect: String = "aspect"
    public static let flagWidth: String = "width"
    public static let flagSource: String = "source"
    public static let flagDegrees: String = "degrees"
    public static let flagPreset: String = "preset"
}
