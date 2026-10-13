import XCTest
@testable import OpenDisplayCore

final class Phase11Tests: XCTestCase {

    func testColorProfileConstants() {
        XCTAssertEqual(ColorProfileConstants.iccExtension, "icc")
        XCTAssertEqual(ColorProfileConstants.icmExtension, "icm")
        XCTAssertEqual(ColorProfileConstants.defaultColorSpace, "RGB")
        XCTAssertEqual(ColorProfileConstants.headerColorSpaceOffset, 16)
        XCTAssertEqual(ColorProfileConstants.headerColorSpaceLength, 4)
        XCTAssertEqual(ColorProfileConstants.minHeaderLength, 20)
    }

    func testAutoBrightnessConstants() {
        XCTAssertEqual(AutoBrightnessConstants.defaultPollingIntervalSeconds, 2.0)
        XCTAssertEqual(AutoBrightnessConstants.defaultSensitivity, 1.0)
        XCTAssertEqual(AutoBrightnessConstants.minSensitivity, 0.5)
        XCTAssertEqual(AutoBrightnessConstants.maxSensitivity, 1.5)
        XCTAssertEqual(AutoBrightnessConstants.minBrightness, 0.0)
        XCTAssertEqual(AutoBrightnessConstants.maxBrightness, 1.0)
        XCTAssertEqual(AutoBrightnessConstants.changeThreshold, 0.01)
    }

    func testICCHeaderParserColorSpaceDetection() {
        // Construct simulated 24-byte ICC profile header
        var header = [UInt8](repeating: 0, count: 24)
        // Set ASCII "RGB " at offset 16
        header[16] = UInt8(ascii: "R")
        header[17] = UInt8(ascii: "G")
        header[18] = UInt8(ascii: "B")
        header[19] = UInt8(ascii: " ")

        let parsedRGB = ICCHeaderParser.parseColorSpaceType(headerData: Data(header))
        XCTAssertEqual(parsedRGB, "RGB")

        // Set ASCII "CMYK" at offset 16
        header[16] = UInt8(ascii: "C")
        header[17] = UInt8(ascii: "M")
        header[18] = UInt8(ascii: "Y")
        header[19] = UInt8(ascii: "K")

        let parsedCMYK = ICCHeaderParser.parseColorSpaceType(headerData: Data(header))
        XCTAssertEqual(parsedCMYK, "CMYK")

        // Truncated header data (< 20 bytes) falls back to default "RGB"
        let truncated = Data(repeating: 0, count: 12)
        XCTAssertEqual(ICCHeaderParser.parseColorSpaceType(headerData: truncated), "RGB")

        // Non-printable ASCII bytes in tag fallback to default "RGB"
        var nonPrintableHeader = [UInt8](repeating: 0, count: 24)
        nonPrintableHeader[16] = 0x01
        nonPrintableHeader[17] = 0x02
        nonPrintableHeader[18] = 0x03
        nonPrintableHeader[19] = 0x04
        XCTAssertEqual(ICCHeaderParser.parseColorSpaceType(headerData: Data(nonPrintableHeader)), "RGB")
    }

    func testICCHeaderParserBitsPerChannel() {
        XCTAssertEqual(ICCHeaderParser.bitsPerChannel(from: "--------RRRRRRRRGGGGGGGGBBBBBBBB"), 8)
        XCTAssertEqual(ICCHeaderParser.bitsPerChannel(from: "DDDDDDDDDDDDDDDDDDDDDDDDDDDDDD"), 10)
        XCTAssertEqual(ICCHeaderParser.bitsPerChannel(from: "Unknown"), 8)
    }

    func testBrightnessSyncCalculatorTarget() {
        // 1.0 sensitivity
        let target1 = BrightnessSyncCalculator.computeTargetBrightness(builtinBrightness: 0.5, sensitivity: 1.0)
        XCTAssertEqual(target1, 0.5, accuracy: 0.001)

        // 1.2 sensitivity
        let target2 = BrightnessSyncCalculator.computeTargetBrightness(builtinBrightness: 0.5, sensitivity: 1.2)
        XCTAssertEqual(target2, 0.6, accuracy: 0.001)

        // Clamping upper bound
        let targetOver = BrightnessSyncCalculator.computeTargetBrightness(builtinBrightness: 0.9, sensitivity: 1.5)
        XCTAssertEqual(targetOver, 1.0, accuracy: 0.001)

        // Clamping lower bound
        let targetUnder = BrightnessSyncCalculator.computeTargetBrightness(builtinBrightness: -0.2, sensitivity: 1.0)
        XCTAssertEqual(targetUnder, 0.0, accuracy: 0.001)
    }

    func testBrightnessSyncCalculatorSignificantChange() {
        XCTAssertTrue(BrightnessSyncCalculator.hasSignificantChange(oldValue: 0.50, newValue: 0.52))
        XCTAssertFalse(BrightnessSyncCalculator.hasSignificantChange(oldValue: 0.50, newValue: 0.505))
    }
}
