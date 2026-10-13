import XCTest
@testable import OpenDisplayCore

final class Phase1Tests: XCTestCase {

    func testDDCVcpCodeRawValues() {
        XCTAssertEqual(DDCVcpCode.brightness.rawValue, 0x10)
        XCTAssertEqual(DDCVcpCode.contrast.rawValue, 0x12)
        XCTAssertEqual(DDCVcpCode.audioSpeakerVolume.rawValue, 0x62)
        XCTAssertEqual(DDCVcpCode.audioMute.rawValue, 0x8D)
        XCTAssertEqual(DDCVcpCode.inputSource.rawValue, 0x60)
        XCTAssertEqual(DDCVcpCode.controlLock.rawValue, 0xAE)
        XCTAssertEqual(DDCVcpCode.monitorStatus.rawValue, 0xB6)
        XCTAssertEqual(DDCVcpCode.powerControl.rawValue, 0xD6)
        XCTAssertEqual(DDCVcpCode.capabilitiesRequest.rawValue, 0xF3)
    }

    func testDDCProtocolLimits() {
        XCTAssertEqual(DDCProtocolLimits.defaultSleepMilliseconds, 40)
        XCTAssertEqual(DDCProtocolLimits.maxRetryAttempts, 3)
        XCTAssertEqual(DDCProtocolLimits.maxCapabilitiesReplyChunkSize, 32)
        XCTAssertEqual(DDCProtocolLimits.standardPacketHeaderLength, 3)
        XCTAssertEqual(DDCProtocolLimits.standardPacketOverhead, 4)
    }

    func testVirtualDisplayLimits() {
        XCTAssertEqual(VirtualDisplayLimits.maxPixelsWide, 7680)
        XCTAssertEqual(VirtualDisplayLimits.maxPixelsHigh, 4320)
        XCTAssertEqual(VirtualDisplayLimits.defaultVendorID, 0xF0F0)
        XCTAssertEqual(VirtualDisplayLimits.defaultProductID, 0x0D0D)
        XCTAssertEqual(VirtualDisplayLimits.defaultRefreshRate, 60.0)
        XCTAssertEqual(VirtualDisplayLimits.hiDPIScaleFactor, 2)
    }

    func testGammaTableConstants() {
        XCTAssertEqual(GammaTableConstants.standardTableSize, 256)
        XCTAssertEqual(GammaTableConstants.highPrecisionTableSize, 1024)
        XCTAssertEqual(GammaTableConstants.minLuminanceFloor, 0.001)
    }

    func testDynamicObjCClass() {
        let nsObjectClass = DynamicObjCClass.resolve("NSObject")
        XCTAssertNotNil(nsObjectClass)
        if let obj = nsObjectClass?.init() {
            XCTAssertTrue(DynamicObjCClass.checkSelector("description", on: obj))
            XCTAssertFalse(DynamicObjCClass.checkSelector("nonExistentSelectorXYZ", on: obj))
        }
    }

    func testOddAspectRatioCalculations() {
        // 21.3:9 on 2130 wide -> 900 high
        let (w21_3, h21_3) = DisplayAspectPreset.ratio21_3_9.dimensions(forWidth: 2130)
        XCTAssertEqual(w21_3, 2130)
        XCTAssertEqual(h21_3, 900)
    }

    func testDDCI2CAddressConstants() {
        XCTAssertEqual(DDCI2CAddress.ddcSlaveAddress.rawValue, 0x37)
        XCTAssertEqual(DDCI2CAddress.ddcSubAddress.rawValue, 0x51)
        XCTAssertEqual(DDCI2CAddress.writeXorSeed.rawValue, 0x6E)
        XCTAssertEqual(DDCI2CAddress.readXorSeed.rawValue, 0x6F)
        XCTAssertEqual(DDCI2CAddress.edidI2CAddress.rawValue, 0x50)
    }

    func testAll15AspectRatioCalculations() {
        XCTAssertEqual(DisplayAspectPreset.allCases.count, 15)

        // 16:9 on 3840 wide -> 2160 high
        let (w16_9, h16_9) = DisplayAspectPreset.ratio16_9.dimensions(forWidth: 3840)
        XCTAssertEqual(w16_9, 3840)
        XCTAssertEqual(h16_9, 2160)

        // 16:10 on 2560 wide -> 1600 high
        let (w16_10, h16_10) = DisplayAspectPreset.ratio16_10.dimensions(forWidth: 2560)
        XCTAssertEqual(w16_10, 2560)
        XCTAssertEqual(h16_10, 1600)

        // 1:1 on 2048 wide -> 2048 high
        let (w1_1, h1_1) = DisplayAspectPreset.ratio1_1.dimensions(forWidth: 2048)
        XCTAssertEqual(w1_1, 2048)
        XCTAssertEqual(h1_1, 2048)

        // Verify non-zero height for all 15 presets
        for preset in DisplayAspectPreset.allCases {
            let dim = preset.dimensions(forWidth: 1920)
            XCTAssertGreaterThan(dim.height, 0)
        }
    }

    func testColorPixelFormats() {
        XCTAssertEqual(ColorPixelFormat.argb8888.bitsPerSample, 8)
        XCTAssertFalse(ColorPixelFormat.argb8888.isDeepColor)

        XCTAssertEqual(ColorPixelFormat.argb2101010.bitsPerSample, 10)
        XCTAssertTrue(ColorPixelFormat.argb2101010.isDeepColor)

        XCTAssertEqual(ColorPixelFormat.rgba16Float.bitsPerSample, 16)
        XCTAssertTrue(ColorPixelFormat.rgba16Float.isDeepColor)
    }

    func testEDIDFixedHeader() {
        let expected: [UInt8] = [0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00]
        XCTAssertEqual(EDIDConstants.fixedHeader, expected)
        XCTAssertEqual(EDIDConstants.CTA861Flags.ycbcr444Mask, 0x20)
        XCTAssertEqual(EDIDConstants.CTA861Flags.ycbcr422Mask, 0x10)
    }
}
