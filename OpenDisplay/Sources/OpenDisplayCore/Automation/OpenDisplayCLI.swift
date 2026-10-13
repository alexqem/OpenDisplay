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

        default:
            return .unknown(verb)
        }
    }
}
