import Foundation

/// Supported CLI Commands
public enum CLICommand: Equatable, Sendable {
    case get(target: String, property: String)
    case set(target: String, property: String, value: String)
    case createVirtual(name: String, aspect: String, width: UInt32)
    case mirror(source: String, target: String)
    case unmirror(target: String)
    case rotate(target: String, degrees: Int32)
    case disconnect(target: String)
    case reconnect(target: String)
    case listPresets
    case forceRGB(target: String)
    case setHDR(target: String, enabled: Bool)
    case setProfile(target: String, profileName: String)
    case setInputSource(target: String, source: String)
    case setResolution(target: String, width: Int, height: Int, isHiDPI: Bool)
    case listResolutions(target: String)
    case listProfiles
    case linkGroup(master: String, slave: String, offset: Double)
    case unlinkGroup(slave: String)
    case listGroups
    case help
    case unknown(String)
}

/// Pure functional Command Line Interface parser
public enum OpenDisplayCLI {

    /// Helper to extract string flag parameter (e.g. -target=value)
    public static func parseFlag(_ flag: String, arguments: [String], defaultValue: String = "") -> String {
        let prefix = "-\(flag)="
        for arg in arguments {
            if arg.starts(with: prefix) {
                return String(arg.dropFirst(prefix.count))
            }
        }
        return defaultValue
    }

    /// Parse array of CLI arguments (excluding executable name)
    public static func parse(arguments: [String]) -> CLICommand {
        guard let verb = arguments.first?.lowercased() else {
            return .help
        }

        let tail = Array(arguments.dropFirst())

        switch verb {
        case "help", "-h", "--help":
            return .help

        case "get":
            var target = AutomationConstants.cliDefaultTargetAll
            var property = AutomationConstants.cliDefaultTargetAll
            for arg in tail {
                if arg.starts(with: "-\(AutomationConstants.flagTarget)=") {
                    target = String(arg.dropFirst("-\(AutomationConstants.flagTarget)=".count))
                } else if arg.starts(with: "-\(AutomationConstants.flagProperty)=") {
                    property = String(arg.dropFirst("-\(AutomationConstants.flagProperty)=".count))
                } else if arg.starts(with: "-") {
                    property = String(arg.dropFirst())
                }
            }
            return .get(target: target, property: property)

        case "set":
            var target = AutomationConstants.cliDefaultTargetActive
            var property = AutomationConstants.cliDefaultBrightnessProperty
            var value = AutomationConstants.cliDefaultBrightnessValue
            for arg in tail {
                if arg.starts(with: "-\(AutomationConstants.flagTarget)=") {
                    target = String(arg.dropFirst("-\(AutomationConstants.flagTarget)=".count))
                } else if let eqIdx = arg.firstIndex(of: "=") {
                    let prop = String(arg[arg.startIndex..<eqIdx]).trimmingCharacters(in: CharacterSet(charactersIn: "-"))
                    let val = String(arg[arg.index(after: eqIdx)...])
                    property = prop
                    value = val
                }
            }
            return .set(target: target, property: property, value: value)

        case "create-virtual":
            let name = parseFlag(AutomationConstants.flagName, arguments: tail, defaultValue: AutomationConstants.cliDefaultVirtualName)
            let aspect = parseFlag(AutomationConstants.flagAspect, arguments: tail, defaultValue: AutomationConstants.cliDefaultAspect)
            let widthStr = parseFlag(AutomationConstants.flagWidth, arguments: tail, defaultValue: String(AutomationConstants.cliDefaultVirtualWidth))
            let width = UInt32(widthStr) ?? AutomationConstants.cliDefaultVirtualWidth
            return .createVirtual(name: name, aspect: aspect, width: width)

        case "mirror":
            let source = parseFlag(AutomationConstants.flagSource, arguments: tail)
            let target = parseFlag(AutomationConstants.flagTarget, arguments: tail)
            return .mirror(source: source, target: target)

        case "unmirror":
            let target = parseFlag(AutomationConstants.flagTarget, arguments: tail, defaultValue: AutomationConstants.cliDefaultTargetAll)
            return .unmirror(target: target)

        case "rotate":
            let target = parseFlag(AutomationConstants.flagTarget, arguments: tail, defaultValue: AutomationConstants.cliDefaultTargetActive)
            let degStr = parseFlag(AutomationConstants.flagDegrees, arguments: tail, defaultValue: String(AutomationConstants.cliDefaultDegrees))
            let degrees = Int32(degStr) ?? AutomationConstants.cliDefaultDegrees
            return .rotate(target: target, degrees: degrees)

        case "disconnect":
            let target = parseFlag(AutomationConstants.flagTarget, arguments: tail, defaultValue: AutomationConstants.cliDefaultTargetActive)
            return .disconnect(target: target)

        case "reconnect":
            let target = parseFlag(AutomationConstants.flagTarget, arguments: tail, defaultValue: AutomationConstants.cliDefaultTargetActive)
            return .reconnect(target: target)

        case "presets", "list-presets":
            return .listPresets

        case "force-rgb":
            let target = parseFlag(AutomationConstants.flagTarget, arguments: tail, defaultValue: AutomationConstants.cliDefaultTargetActive)
            return .forceRGB(target: target)

        case "hdr":
            let target = parseFlag(AutomationConstants.flagTarget, arguments: tail, defaultValue: AutomationConstants.cliDefaultTargetActive)
            let state = parseFlag(AutomationConstants.flagState, arguments: tail, defaultValue: AutomationConstants.flagEnable)
            let enabled = (state.lowercased() == AutomationConstants.flagEnable || state == "1" || state.lowercased() == "true")
            return .setHDR(target: target, enabled: enabled)

        case "color-profile", "set-profile":
            let target = parseFlag(AutomationConstants.flagTarget, arguments: tail, defaultValue: AutomationConstants.cliDefaultTargetActive)
            let profile = parseFlag(AutomationConstants.flagProfile, arguments: tail)
            return .setProfile(target: target, profileName: profile)

        case "input", "set-input":
            let target = parseFlag(AutomationConstants.flagTarget, arguments: tail, defaultValue: AutomationConstants.cliDefaultTargetActive)
            let input = parseFlag(AutomationConstants.flagInput, arguments: tail)
            return .setInputSource(target: target, source: input)

        case "resolution", "set-resolution":
            let target = parseFlag(AutomationConstants.flagTarget, arguments: tail, defaultValue: AutomationConstants.cliDefaultTargetActive)
            let widthStr = parseFlag(AutomationConstants.flagWidth, arguments: tail, defaultValue: "0")
            let heightStr = parseFlag(AutomationConstants.flagHeight, arguments: tail, defaultValue: "0")
            let hidpiStr = parseFlag(AutomationConstants.flagHiDPI, arguments: tail, defaultValue: "true")
            let width = Int(widthStr) ?? 0
            let height = Int(heightStr) ?? 0
            let isHiDPI = (hidpiStr.lowercased() == "true" || hidpiStr == "1" || hidpiStr.lowercased() == "yes")
            return .setResolution(target: target, width: width, height: height, isHiDPI: isHiDPI)

        case "resolutions", "list-resolutions":
            let target = parseFlag(AutomationConstants.flagTarget, arguments: tail, defaultValue: AutomationConstants.cliDefaultTargetActive)
            return .listResolutions(target: target)

        case "profiles", "list-profiles":
            return .listProfiles

        case "link-group", "group-link":
            let master = parseFlag(AutomationConstants.flagMaster, arguments: tail)
            let slave = parseFlag(AutomationConstants.flagSlave, arguments: tail)
            let offsetStr = parseFlag(AutomationConstants.flagOffset, arguments: tail, defaultValue: "0.0")
            let offset = Double(offsetStr) ?? 0.0
            return .linkGroup(master: master, slave: slave, offset: offset)

        case "unlink-group", "group-unlink":
            let slave = parseFlag(AutomationConstants.flagSlave, arguments: tail)
            return .unlinkGroup(slave: slave)

        case "groups", "list-groups":
            return .listGroups

        default:
            return .unknown(verb)
        }
    }
}
