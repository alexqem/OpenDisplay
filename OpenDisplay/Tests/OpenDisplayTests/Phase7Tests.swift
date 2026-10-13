import XCTest
@testable import OpenDisplayCore

final class Phase7Tests: XCTestCase {

    func testAutomationConstants() {
        XCTAssertEqual(AutomationConstants.cliDefaultTargetAll, "all")
        XCTAssertEqual(AutomationConstants.cliDefaultTargetActive, "active")
        XCTAssertEqual(AutomationConstants.cliDefaultVirtualName, "OpenDisplay Virtual")
        XCTAssertEqual(AutomationConstants.cliDefaultAspect, "16:9")
        XCTAssertEqual(AutomationConstants.cliDefaultVirtualWidth, 3840)
        XCTAssertEqual(AutomationConstants.cliDefaultDegrees, 0)
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

    func testCLIParsingPresets() {
        let cmd = OpenDisplayCLI.parse(arguments: ["presets"])
        XCTAssertEqual(cmd, .listPresets)

        let cmdAlt = OpenDisplayCLI.parse(arguments: ["list-presets"])
        XCTAssertEqual(cmdAlt, .listPresets)
    }
}
