import XCTest
@testable import OpenDisplayCore

final class Phase6Tests: XCTestCase {

    func testPipStreamOptionsDefaults() {
        #if os(macOS) && arch(arm64)
        let options = PipStreamOptions()
        XCTAssertEqual(options.width, 1920)
        XCTAssertEqual(options.height, 1080)
        XCTAssertEqual(options.frameRate, 60)
        XCTAssertTrue(options.showsCursor)
        #endif
    }

    func testPipStreamOptionsCustom() {
        #if os(macOS) && arch(arm64)
        let custom = PipStreamOptions(width: 3840, height: 2160, frameRate: 120, showsCursor: false)
        XCTAssertEqual(custom.width, 3840)
        XCTAssertEqual(custom.height, 2160)
        XCTAssertEqual(custom.frameRate, 120)
        XCTAssertFalse(custom.showsCursor)
        #endif
    }

    func testPipConstantsAndState() {
        #if os(macOS) && arch(arm64)
        XCTAssertEqual(PipConstants.defaultWidth, 1920)
        XCTAssertEqual(PipConstants.defaultHeight, 1080)
        XCTAssertEqual(PipConstants.defaultFrameRate, 60)
        XCTAssertEqual(PipConstants.queueDepth, 5)

        XCTAssertEqual(PipStreamState.idle.rawValue, "idle")
        XCTAssertEqual(PipStreamState.capturing.rawValue, "capturing")
        XCTAssertEqual(PipStreamState.stopped.rawValue, "stopped")
        XCTAssertEqual(PipStreamState.failed.rawValue, "failed")
        #endif
    }
}
