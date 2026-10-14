import XCTest
@testable import OpenDisplayCore

final class Phase15Tests: XCTestCase {

    func testHDMIAndCTA861CapabilitiesDetection() {
        // Construct synthetic 256-byte EDID with CTA-861 Extension and HDMI VSDB (IEEE 0x000C03)
        var edid = [UInt8](repeating: 0, count: 256)

        // Fixed EDID Header: 00 FF FF FF FF FF FF 00
        edid[0] = 0x00
        for i in 1...6 { edid[i] = 0xFF }
        edid[7] = 0x00

        // Manufacturer "DEL" (Dell): 0x10, 0xAC
        edid[8] = 0x10
        edid[9] = 0xAC
        edid[10] = 0x24 // Product ID
        edid[11] = 0x40

        // Checksum for base block so validateBlockChecksum passes
        var baseSum: UInt32 = 0
        for i in 0..<127 { baseSum += UInt32(edid[i]) }
        edid[127] = UInt8((256 - (baseSum % 256)) % 256)

        // CTA-861 Extension at byte 128
        let ext = 128
        edid[ext] = EDIDConstants.cta861ExtensionTag // 0x02
        edid[ext + 1] = 0x03 // Revision 3
        edid[ext + 2] = 16   // d = 16 (Data block collection ends at 128 + 16)

        // Byte 3 (128 + 3): Flags: YCbCr 4:4:4 (bit 5) + Basic Audio (bit 6)
        edid[ext + 3] = (1 << 5) | (1 << 6)

        // Data Block 1: Vendor-Specific Data Block (Tag 3, length 5) -> Header byte: (3 << 5) | 5 = 0x65
        edid[ext + 4] = 0x65
        // IEEE Registration Identifier 0x000C03 (03, 0C, 00)
        edid[ext + 5] = EDIDConstants.HDMIVSDBConstants.ieeeRegistrationByte0 // 0x03
        edid[ext + 6] = EDIDConstants.HDMIVSDBConstants.ieeeRegistrationByte1 // 0x0C
        edid[ext + 7] = EDIDConstants.HDMIVSDBConstants.ieeeRegistrationByte2 // 0x00

        // Physical Address: 1.0.0.0 -> Bytes: 0x10, 0x00
        edid[ext + 8] = 0x10
        edid[ext + 9] = 0x00

        // Recalculate Extension checksum at byte 255
        var extSum: UInt32 = 0
        for i in 128..<255 { extSum += UInt32(edid[i]) }
        edid[255] = UInt8((256 - (extSum % 256)) % 256)

        // Parse using EDIDParser
        guard let parsed = EDIDParser.parse(bytes: edid) else {
            XCTFail("Failed to parse synthetic EDID")
            return
        }

        XCTAssertTrue(parsed.hasCTA861Extension)
        XCTAssertTrue(parsed.capabilities.isHDMI)
        XCTAssertTrue(parsed.capabilities.supportsYCbCr444)
        XCTAssertFalse(parsed.capabilities.supportsYCbCr422)
        XCTAssertTrue(parsed.capabilities.supportsBasicAudio)
        XCTAssertEqual(parsed.capabilities.physicalAddress, "1.0.0.0")

        // Test augmented capability copy
        let augmented = parsed.capabilities.augmented(supportsHDR: true, supportsDDC: true)
        XCTAssertTrue(augmented.supportsHDR)
        XCTAssertTrue(augmented.supportsDDC)
        XCTAssertTrue(augmented.isHDMI)
    }

    func testDisplayCapabilitiesFallback() {
        let fallback = DisplayCapabilities.fallback
        XCTAssertFalse(fallback.isHDMI)
        XCTAssertFalse(fallback.supportsYCbCr444)
        XCTAssertFalse(fallback.supportsYCbCr422)
        XCTAssertFalse(fallback.supportsBasicAudio)
        XCTAssertFalse(fallback.supportsUnderscan)
        XCTAssertFalse(fallback.supports10BitDeepColor)
        XCTAssertFalse(fallback.supportsHDR)
        XCTAssertFalse(fallback.supportsDDC)
        XCTAssertNil(fallback.physicalAddress)
    }

    func testCTA861StructureAndFlagsConstants() {
        XCTAssertEqual(EDIDConstants.CTA861Flags.ycbcr444Mask, 32)
        XCTAssertEqual(EDIDConstants.CTA861Flags.ycbcr422Mask, 16)
        XCTAssertEqual(EDIDConstants.CTA861Flags.basicAudioMask, 64)
        XCTAssertEqual(EDIDConstants.CTA861Flags.underscanMask, 128)

        XCTAssertEqual(EDIDConstants.CTA861Structure.dOffsetByteIndex, 2)
        XCTAssertEqual(EDIDConstants.CTA861Structure.dataBlockCollectionStartOffset, 4)
        XCTAssertEqual(EDIDConstants.CTA861Structure.tagBitShift, 5)
        XCTAssertEqual(EDIDConstants.CTA861Structure.tagMask, 0x07)
        XCTAssertEqual(EDIDConstants.CTA861Structure.lengthMask, 0x1F)
    }

    func testHDMIVSDBConstants() {
        XCTAssertEqual(EDIDConstants.HDMIVSDBConstants.ieeeRegistrationByte0, 0x03)
        XCTAssertEqual(EDIDConstants.HDMIVSDBConstants.ieeeRegistrationByte1, 0x0C)
        XCTAssertEqual(EDIDConstants.HDMIVSDBConstants.ieeeRegistrationByte2, 0x00)
        XCTAssertEqual(EDIDConstants.HDMIVSDBConstants.vsdbTagCode, 0x03)
    }

    func testAtlasSwitchConstants() {
        #if os(macOS) && arch(arm64)
        XCTAssertEqual(AtlasTheme.switchWidth, 32.0)
        XCTAssertEqual(AtlasTheme.switchHeight, 18.0)
        XCTAssertEqual(AtlasTheme.switchThumbSize, 14.0)
        XCTAssertEqual(AtlasTheme.switchThumbPadding, 2.0)
        XCTAssertEqual(AtlasTheme.switchAnimationDuration, 0.16)
        #endif
    }
}
