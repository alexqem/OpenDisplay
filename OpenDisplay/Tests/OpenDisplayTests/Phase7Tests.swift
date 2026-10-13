import XCTest
@testable import OpenDisplayCore

final class Phase7Tests: XCTestCase {

    func testHTTPRouterStatus() {
        let raw = "GET /api/v1/status HTTP/1.1\r\nHost: localhost\r\n\r\n"
        let parsed = HTTPRouter.parseRawRequest(raw)
        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed?.method, "GET")
        XCTAssertEqual(parsed?.path, "/api/v1/status")

        let resp = HTTPRouter.handleRequest(parsed!)
        XCTAssertEqual(resp.statusCode, 200)
        XCTAssertTrue(resp.bodyJson.contains("\"status\":\"running\""))
    }

    func testHTTPRouterNotFound() {
        let raw = "GET /api/unknown HTTP/1.1\r\nHost: localhost\r\n\r\n"
        let parsed = HTTPRouter.parseRawRequest(raw)
        XCTAssertNotNil(parsed)

        let resp = HTTPRouter.handleRequest(parsed!)
        XCTAssertEqual(resp.statusCode, 404)
    }

    func testHTTPRouterPostMissingBody() {
        let raw = "POST /api/v1/virtual/create HTTP/1.1\r\nHost: localhost\r\n\r\n"
        let parsed = HTTPRouter.parseRawRequest(raw)
        XCTAssertNotNil(parsed)

        let resp = HTTPRouter.handleRequest(parsed!)
        XCTAssertEqual(resp.statusCode, 400)
    }

    func testCLIParsingGet() {
        let cmd = OpenDisplayCLI.parse(arguments: ["get", "-target=1", "-brightness"])
        XCTAssertEqual(cmd, .get(target: "1", property: "brightness"))
    }

    func testCLIParsingSet() {
        let cmd = OpenDisplayCLI.parse(arguments: ["set", "-target=1", "-brightness=80"])
        XCTAssertEqual(cmd, .set(target: "1", property: "brightness", value: "80"))
    }

    func testCLIParsingCreateVirtual() {
        let cmd = OpenDisplayCLI.parse(arguments: ["create-virtual", "-name=Studio", "-aspect=16:10", "-width=2560"])
        XCTAssertEqual(cmd, .createVirtual(name: "Studio", aspect: "16:10", width: 2560))
    }
}
