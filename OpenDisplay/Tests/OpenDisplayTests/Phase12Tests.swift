import XCTest
import CoreGraphics
@testable import OpenDisplayCore

final class Phase12Tests: XCTestCase {

    func testDisplayRotationAngles() {
        XCTAssertEqual(DisplayRotationAngle.standard.rawValue, 0)
        XCTAssertEqual(DisplayRotationAngle.rotate90.rawValue, 90)
        XCTAssertEqual(DisplayRotationAngle.rotate180.rawValue, 180)
        XCTAssertEqual(DisplayRotationAngle.rotate270.rawValue, 270)
        XCTAssertEqual(DisplayRotationAngle.allCases.count, 4)
    }

    #if os(macOS) && arch(arm64)
    func testDisplayPowerStateControllerStateTracking() {
        let controller = DisplayPowerStateController.shared
        let testDisplayID: CGDirectDisplayID = 99999

        XCTAssertFalse(controller.isDisconnected(displayID: testDisplayID))
    }
    #endif
}
