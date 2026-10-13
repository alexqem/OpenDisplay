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

    func testCLIParsingColorCalibrationCommands() {
        // Force RGB
        let forceRGBArgs = ["force-rgb", "-target=2"]
        let forceRGBCmd = OpenDisplayCLI.parse(arguments: forceRGBArgs)
        XCTAssertEqual(forceRGBCmd, .forceRGB(target: "2"))

        // Set HDR enabled
        let hdrArgs = ["hdr", "-target=1", "-state=enable"]
        let hdrCmd = OpenDisplayCLI.parse(arguments: hdrArgs)
        XCTAssertEqual(hdrCmd, .setHDR(target: "1", enabled: true))

        // Set HDR disabled
        let hdrOffArgs = ["hdr", "-target=1", "-state=disable"]
        let hdrOffCmd = OpenDisplayCLI.parse(arguments: hdrOffArgs)
        XCTAssertEqual(hdrOffCmd, .setHDR(target: "1", enabled: false))

        // Set color profile
        let profileArgs = ["color-profile", "-target=1", "-profile=Display P3"]
        let profileCmd = OpenDisplayCLI.parse(arguments: profileArgs)
        XCTAssertEqual(profileCmd, .setProfile(target: "1", profileName: "Display P3"))

        // List color profiles
        let listProfilesCmd = OpenDisplayCLI.parse(arguments: ["profiles"])
        XCTAssertEqual(listProfilesCmd, .listProfiles)
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
