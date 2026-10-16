import XCTest
@testable import OpenDisplayCore

final class Phase21Tests: XCTestCase {

    func testPipConstantsAndOptions() {
        XCTAssertEqual(PipConstants.defaultWidth, 1920)
        XCTAssertEqual(PipConstants.defaultHeight, 1080)
        XCTAssertEqual(PipConstants.defaultFrameRate, 60)
        XCTAssertEqual(PipPanelConstants.panelWidth, 360)
        XCTAssertEqual(PipPanelConstants.panelHeight, 203)

        let customOpts = PipStreamOptions(width: 1280, height: 720, frameRate: 30, showsCursor: false)
        XCTAssertEqual(customOpts.width, 1280)
        XCTAssertEqual(customOpts.height, 720)
        XCTAssertEqual(customOpts.frameRate, 30)
        XCTAssertFalse(customOpts.showsCursor)
    }

    func testPipPanelGeometryAndOpacityClamping() {
        let panel = PipWindowPanel(contentRect: NSRect(x: 100, y: 100, width: 300, height: 200))
        XCTAssertEqual(panel.level, .floating)
        XCTAssertTrue(panel.isFloatingPanel)

        // Test clamping below minimum
        panel.setOpacity(0.0)
        XCTAssertEqual(panel.alphaValue, 0.1, accuracy: 0.001)

        // Test clamping above maximum
        panel.setOpacity(2.0)
        XCTAssertEqual(panel.alphaValue, 1.0, accuracy: 0.001)

        // Test normal opacity
        panel.setOpacity(0.75)
        XCTAssertEqual(panel.alphaValue, 0.75, accuracy: 0.001)

        // Test click-through flag
        panel.setClickThrough(true)
        XCTAssertTrue(panel.ignoresMouseEvents)
        panel.setClickThrough(false)
        XCTAssertFalse(panel.ignoresMouseEvents)
    }

    func testDisplayItemModelNotchAndPipStates() {
        let item = DisplayItemModel(
            id: 1,
            name: "MacBook Built-in Liquid Retina",
            isBuiltin: true,
            isHiDPI: true,
            pixelWidth: 3024,
            pixelHeight: 1964
        )
        XCTAssertFalse(item.isNotchOverlayActive)
        XCTAssertFalse(item.hasPhysicalNotch)
        XCTAssertFalse(item.isDisconnected)

        item.hasPhysicalNotch = true
        item.isNotchOverlayActive = true
        XCTAssertTrue(item.hasPhysicalNotch)
        XCTAssertTrue(item.isNotchOverlayActive)

        item.isDisconnected = true
        XCTAssertTrue(item.isDisconnected)
    }
}
