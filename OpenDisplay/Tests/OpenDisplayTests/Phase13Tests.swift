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

    func testHTTPRouterNewEndpoints() {
        // Mirror endpoint
        let mirrorReq = HTTPParsedRequest(method: "POST", path: "/api/v1/displays/mirror", body: "{\"source\":1,\"target\":2}")
        let mirrorRes = HTTPRouter.handleRequest(mirrorReq)
        XCTAssertEqual(mirrorRes.statusCode, 200)

        // Rotate endpoint
        let rotateReq = HTTPParsedRequest(method: "POST", path: "/api/v1/displays/rotate", body: "{\"display\":1,\"degrees\":90}")
        let rotateRes = HTTPRouter.handleRequest(rotateReq)
        XCTAssertEqual(rotateRes.statusCode, 200)

        // Power endpoint
        let powerReq = HTTPParsedRequest(method: "POST", path: "/api/v1/displays/power", body: "{\"display\":1,\"action\":\"disconnect\"}")
        let powerRes = HTTPRouter.handleRequest(powerReq)
        XCTAssertEqual(powerRes.statusCode, 200)

        // Presets list endpoint
        let presetsReq = HTTPParsedRequest(method: "GET", path: "/api/v1/presets", body: nil)
        let presetsRes = HTTPRouter.handleRequest(presetsReq)
        XCTAssertEqual(presetsRes.statusCode, 200)

        // Negative: Missing body yields 400 Bad Request
        let missingBodyReq = HTTPParsedRequest(method: "POST", path: "/api/v1/displays/mirror", body: nil)
        let missingBodyRes = HTTPRouter.handleRequest(missingBodyReq)
        XCTAssertEqual(missingBodyRes.statusCode, 400)

        // Negative: Empty whitespace body yields 400
        let emptyBodyReq = HTTPParsedRequest(method: "POST", path: "/api/v1/displays/rotate", body: "   ")
        let emptyBodyRes = HTTPRouter.handleRequest(emptyBodyReq)
        XCTAssertEqual(emptyBodyRes.statusCode, 400)
    }

    func testCLIParsingFallbackAndUnknown() {
        let emptyArgs: [String] = []
        XCTAssertEqual(OpenDisplayCLI.parse(arguments: emptyArgs), .help)

        let helpArgs = ["--help"]
        XCTAssertEqual(OpenDisplayCLI.parse(arguments: helpArgs), .help)

        let unknownArgs = ["foobar"]
        XCTAssertEqual(OpenDisplayCLI.parse(arguments: unknownArgs), .unknown("foobar"))
    }
}
