import XCTest
@testable import OpenDisplayCore

final class Phase4Tests: XCTestCase {

    func testVirtualDisplayConfigInitialization() {
        let config16_9 = VirtualDisplayConfig(name: "Test 4K", aspectPreset: .ratio16_9, baseWidth: 3840)
        XCTAssertEqual(config16_9.name, "Test 4K")
        XCTAssertEqual(config16_9.aspectPreset, .ratio16_9)
        XCTAssertEqual(config16_9.baseWidth, 3840)
        XCTAssertEqual(config16_9.refreshRate, VirtualDisplayLimits.defaultRefreshRate)
        XCTAssertTrue(config16_9.isHiDPI)

        let (w, h) = config16_9.aspectPreset.dimensions(forWidth: config16_9.baseWidth)
        XCTAssertEqual(w, 3840)
        XCTAssertEqual(h, 2160)

        // 16:10 configuration
        let config16_10 = VirtualDisplayConfig(name: "Test 16:10", aspectPreset: .ratio16_10, baseWidth: 2560)
        let (w10, h10) = config16_10.aspectPreset.dimensions(forWidth: config16_10.baseWidth)
        XCTAssertEqual(w10, 2560)
        XCTAssertEqual(h10, 1600)
    }

    func testDisplayModeInfoData() {
        let mode = DisplayModeInfo(modeNumber: 42, isCurrent: true, isVRR: true, isProMotion: true)
        XCTAssertEqual(mode.modeNumber, 42)
        XCTAssertTrue(mode.isCurrent)
        XCTAssertTrue(mode.isVRR)
        XCTAssertTrue(mode.isProMotion)
    }
}
