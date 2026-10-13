import XCTest
@testable import OpenDisplayCore

final class Phase9Tests: XCTestCase {

    func testOSDConstants() {
        XCTAssertEqual(OSDConstants.serviceName, "com.apple.OSDUIHelper")
        XCTAssertEqual(OSDConstants.totalChiclets, 16)
        XCTAssertEqual(OSDConstants.imageBrightness, 1)
        XCTAssertEqual(OSDConstants.defaultPriority, 500)
        XCTAssertEqual(OSDConstants.defaultFadeMs, 1500)
    }

    func testArrangementConstants() {
        XCTAssertEqual(ArrangementConstants.defaultTimeoutSeconds, 10.0)
        XCTAssertEqual(ArrangementConstants.originX, 0)
        XCTAssertEqual(ArrangementConstants.originY, 0)
    }

    func testStandardRefreshRatesConstant() {
        XCTAssertTrue(VirtualDisplayLimits.standardRefreshRates.contains(60.0))
        XCTAssertTrue(VirtualDisplayLimits.standardRefreshRates.contains(120.0))
        XCTAssertEqual(VirtualDisplayLimits.standardRefreshRates.count, 4)
    }

    func testDiscoveredAVServiceInitialization() {
        let service = DiscoveredAVService(
            service: 100,
            location: "Embedded",
            serviceClass: "AppleCLCD2",
            vendorID: 0x0610,
            productID: 0xA032
        )
        XCTAssertEqual(service.service, 100)
        XCTAssertEqual(service.location, "Embedded")
        XCTAssertEqual(service.serviceClass, "AppleCLCD2")
        XCTAssertEqual(service.vendorID, 0x0610)
        XCTAssertEqual(service.productID, 0xA032)
    }

    func testVirtualDisplayAspectPresetDimensionRounding() {
        let (w16_9, h16_9) = DisplayAspectPreset.ratio16_9.dimensions(forWidth: 3840)
        XCTAssertEqual(w16_9, 3840)
        XCTAssertEqual(h16_9, 2160)

        let (w16_10, h16_10) = DisplayAspectPreset.ratio16_10.dimensions(forWidth: 2560)
        XCTAssertEqual(w16_10, 2560)
        XCTAssertEqual(h16_10, 1600)
    }

    #if os(macOS) && arch(arm64)
    func testMediaKeyData1Parsing() {
        // Construct simulated data1 for NX_KEYTYPE_BRIGHTNESS_UP with key-down state (0x0A)
        // keyCode: 2 << 16 = 0x00020000
        // keyState: 0x0A << 8 = 0x0A00
        let upData1 = (MediaKeyConstants.keyTypeBrightnessUp << MediaKeyConstants.keyCodeShift) |
                      (MediaKeyConstants.keyStateDown << MediaKeyConstants.keyStateShift)
        XCTAssertEqual(MediaKeysListener.parseMediaKeyAction(data1: upData1), .brightnessUp)

        // Construct simulated data1 for NX_KEYTYPE_BRIGHTNESS_DOWN
        let downData1 = (MediaKeyConstants.keyTypeBrightnessDown << MediaKeyConstants.keyCodeShift) |
                        (MediaKeyConstants.keyStateDown << MediaKeyConstants.keyStateShift)
        XCTAssertEqual(MediaKeysListener.parseMediaKeyAction(data1: downData1), .brightnessDown)

        // Key-up event (state != 0x0A) should produce nil
        let keyUpData1 = (MediaKeyConstants.keyTypeBrightnessUp << MediaKeyConstants.keyCodeShift) |
                         (0x0B << MediaKeyConstants.keyStateShift)
        XCTAssertNil(MediaKeysListener.parseMediaKeyAction(data1: keyUpData1))

        // Unknown key type should produce nil
        let unknownKeyData1 = (99 << MediaKeyConstants.keyCodeShift) |
                              (MediaKeyConstants.keyStateDown << MediaKeyConstants.keyStateShift)
        XCTAssertNil(MediaKeysListener.parseMediaKeyAction(data1: unknownKeyData1))
    }
    #endif
}
