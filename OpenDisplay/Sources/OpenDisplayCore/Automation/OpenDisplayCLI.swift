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
                if arg.starts(with: "-target=") {
                    target = String(arg.dropFirst("-target=".count))
                } else if arg.starts(with: "-property=") {
                    property = String(arg.dropFirst("-property=".count))
                } else if arg.starts(with: "-") {
                    property = String(arg.dropFirst())
                }
            }
            return .get(target: target, property: property)

        case "set":
            var target = AutomationConstants.cliDefaultTargetActive
            var property = "brightness"
            var value = "100"
            for arg in tail {
                if arg.starts(with: "-target=") {
                    target = String(arg.dropFirst("-target=".count))
                } else if let eqIdx = arg.firstIndex(of: "=") {
                    let prop = String(arg[arg.startIndex..<eqIdx]).trimmingCharacters(in: CharacterSet(charactersIn: "-"))
                    let val = String(arg[arg.index(after: eqIdx)...])
                    property = prop
                    value = val
                }
            }
            return .set(target: target, property: property, value: value)

        case "create-virtual":
            let name = parseFlag("name", arguments: tail, defaultValue: "OpenDisplay Virtual")
            let aspect = parseFlag("aspect", arguments: tail, defaultValue: "16:9")
            let widthStr = parseFlag("width", arguments: tail, defaultValue: "3840")
            let width = UInt32(widthStr) ?? 3840
            return .createVirtual(name: name, aspect: aspect, width: width)

        case "mirror":
            let source = parseFlag("source", arguments: tail)
            let target = parseFlag("target", arguments: tail)
            return .mirror(source: source, target: target)

        case "unmirror":
            let target = parseFlag("target", arguments: tail, defaultValue: AutomationConstants.cliDefaultTargetAll)
            return .unmirror(target: target)

        case "rotate":
            let target = parseFlag("target", arguments: tail, defaultValue: AutomationConstants.cliDefaultTargetActive)
            let degStr = parseFlag("degrees", arguments: tail, defaultValue: "0")
            let degrees = Int32(degStr) ?? AutomationConstants.cliDefaultDegrees
            return .rotate(target: target, degrees: degrees)

        case "disconnect":
            let target = parseFlag("target", arguments: tail, defaultValue: AutomationConstants.cliDefaultTargetActive)
            return .disconnect(target: target)

        case "reconnect":
            let target = parseFlag("target", arguments: tail, defaultValue: AutomationConstants.cliDefaultTargetActive)
            return .reconnect(target: target)

        default:
            return .unknown(verb)
        }
    }
}
