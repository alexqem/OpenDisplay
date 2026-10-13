import XCTest
@testable import OpenDisplayCore

final class Phase13Tests: XCTestCase {

    func testCLIParsingMirrorCommands() {
        let args = ["mirror", "-source=1", "-target=2"]
        let cmd = OpenDisplayCLI.parse(arguments: args)
        XCTAssertEqual(cmd, .mirror(source: "1", target: "2"))

        let unmirrorArgs = ["unmirror", "-target=2"]
        let unmirrorCmd = OpenDisplayCLI.parse(arguments: unmirrorArgs)
        XCTAssertEqual(unmirrorCmd, .unmirror(target: "2"))
    }

    func testCLIParsingRotateAndPowerCommands() {
        let rotateArgs = ["rotate", "-target=1", "-degrees=90"]
        let rotateCmd = OpenDisplayCLI.parse(arguments: rotateArgs)
        XCTAssertEqual(rotateCmd, .rotate(target: "1", degrees: 90))

        let disconnectArgs = ["disconnect", "-target=1"]
        let disconnectCmd = OpenDisplayCLI.parse(arguments: disconnectArgs)
        XCTAssertEqual(disconnectCmd, .disconnect(target: "1"))

        let reconnectArgs = ["reconnect", "-target=1"]
        let reconnectCmd = OpenDisplayCLI.parse(arguments: reconnectArgs)
        XCTAssertEqual(reconnectCmd, .reconnect(target: "1"))
    }

    func testCLIParsingFallbackAndUnknown() {
        let emptyArgs: [String] = []
        XCTAssertEqual(OpenDisplayCLI.parse(arguments: emptyArgs), .help)

        let helpArgs = ["--help"]
        XCTAssertEqual(OpenDisplayCLI.parse(arguments: helpArgs), .help)

        let unknownArgs = ["foobar"]
        XCTAssertEqual(OpenDisplayCLI.parse(arguments: unknownArgs), .unknown("foobar"))
    }

    #if os(macOS) && arch(arm64)
    func testDisplayCommandDispatcherCLIHelpAndUnknown() {
        let (okHelp, msgHelp) = DisplayCommandDispatcher.shared.executeCLI(.help)
        XCTAssertTrue(okHelp)
        XCTAssertTrue(msgHelp.contains("OpenDisplay CLI"))

        let (okUnknown, msgUnknown) = DisplayCommandDispatcher.shared.executeCLI(.unknown("bad_cmd"))
        XCTAssertFalse(okUnknown)
        XCTAssertTrue(msgUnknown.contains("Unknown command"))

        let (okPresets, msgPresets) = DisplayCommandDispatcher.shared.executeCLI(.listPresets)
        XCTAssertTrue(okPresets)
        XCTAssertTrue(msgPresets.contains("Default Native"))
    }
    #endif
}
