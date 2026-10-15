import Foundation
#if os(macOS) && arch(arm64)
import OpenDisplayCore

let args = Array(CommandLine.arguments.dropFirst())
let cmd = OpenDisplayCLI.parse(arguments: args)
let result = DisplayCommandDispatcher.shared.executeCLI(cmd)
print(result.message)
exit(result.success ? 0 : 1)
#else
print("OpenDisplayCLI is engineered exclusively for Apple Silicon ARM64 on macOS.")
exit(1)
#endif
