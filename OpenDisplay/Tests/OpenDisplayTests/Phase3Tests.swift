import XCTest
@testable import OpenDisplayCore

final class Phase3Tests: XCTestCase {

    /// Helper to construct a valid Base EDID 128-byte block
    private func makeValidBaseEDID(manufacturer: (UInt8, UInt8), productID: UInt16, name: String) -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: 128)

        // 1. Fixed Header: 00 FF FF FF FF FF FF 00
        for i in 0..<8 {
            bytes[i] = EDIDConstants.fixedHeader[i]
        }

        // 2. Manufacturer: bytes 8..9
        bytes[8] = manufacturer.0
        bytes[9] = manufacturer.1

        // 3. Product ID: bytes 10..11 (little endian)
        bytes[10] = UInt8(productID & 0xFF)
        bytes[11] = UInt8((productID >> 8) & 0xFF)

        // 4. Descriptor 1: Monitor Name (offset 54..71)
        bytes[54] = 0x00
        bytes[55] = 0x00
        bytes[56] = 0x00
        bytes[57] = 0xFC // Monitor Name Tag
        bytes[58] = 0x00
        let nameBytes = Array(name.utf8.prefix(13))
        for (idx, b) in nameBytes.enumerated() {
            bytes[59 + idx] = b
        }
        if nameBytes.count < 13 {
            bytes[59 + nameBytes.count] = 0x0A // Terminator
        }

        // 5. Checksum at byte 127
        var sum: UInt32 = 0
        for i in 0..<127 {
            sum += UInt32(bytes[i])
        }
        bytes[127] = UInt8((256 - (sum % 256)) % 256)

        return bytes
    }

    func testBaseEDIDParsing() {
        // "DEL" (Dell) manufacturer encoding: D=4, E=5, L=12
        // word = (4 << 10) | (5 << 5) | 12 = 4096 | 160 | 12 = 4268 (0x10AC) -> bytes 0x10, 0xAC
        let edid = makeValidBaseEDID(manufacturer: (0x10, 0xAC), productID: 0x4124, name: "Dell U2720Q")

        let parsed = EDIDParser.parse(bytes: edid)
        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed?.manufacturer, "DEL")
        XCTAssertEqual(parsed?.productID, 0x4124)
        XCTAssertEqual(parsed?.monitorName, "Dell U2720Q")
        XCTAssertFalse(parsed?.hasCTA861Extension ?? true)
    }

    func testForceRGBModeCTA861Patch() {
        // Base block (128 bytes)
        var fullEDID = makeValidBaseEDID(manufacturer: (0x10, 0xAC), productID: 0x4124, name: "Dell U2720Q")
        fullEDID[126] = 1 // 1 extension block

        // Recompute base block checksum
        var baseSum: UInt32 = 0
        for i in 0..<127 { baseSum += UInt32(fullEDID[i]) }
        fullEDID[127] = UInt8((256 - (baseSum % 256)) % 256)

        // CTA-861 Extension block (128 bytes at offset 128)
        var extBlock = [UInt8](repeating: 0, count: 128)
        extBlock[0] = EDIDConstants.cta861ExtensionTag // 0x02
        extBlock[1] = 0x03 // Revision 3
        extBlock[2] = 0x04 // DTD offset

        // Byte 3: Flags with YCbCr 4:4:4 (0x20) and YCbCr 4:2:2 (0x10) enabled
        extBlock[3] = EDIDConstants.CTA861Flags.ycbcr444Mask | EDIDConstants.CTA861Flags.ycbcr422Mask

        // Initial extension block checksum
        var extSum: UInt32 = 0
        for i in 0..<127 { extSum += UInt32(extBlock[i]) }
        extBlock[127] = UInt8((256 - (extSum % 256)) % 256)

        fullEDID.append(contentsOf: extBlock)
        XCTAssertEqual(fullEDID.count, 256)

        // Apply Patch
        let patched = RGBForcingEngine.patchEDIDForRGBOnly(edidBytes: fullEDID)
        XCTAssertNotNil(patched)
        guard let patchedEDID = patched else { return }

        // Verify CTA-861 Byte 3 flags: bits 4 and 5 must be 0
        let patchedFlags = patchedEDID[128 + 3]
        XCTAssertEqual(patchedFlags & EDIDConstants.CTA861Flags.ycbcr444Mask, 0)
        XCTAssertEqual(patchedFlags & EDIDConstants.CTA861Flags.ycbcr422Mask, 0)

        // Verify Extension Block Checksum at byte 255 is valid
        var patchedExtSum: UInt32 = 0
        for i in 128..<256 {
            patchedExtSum += UInt32(patchedEDID[i])
        }
        XCTAssertEqual(patchedExtSum % 256, 0)
    }

    func testGenerateDisplayOverridePlist() {
        let sampleEDID: [UInt8] = [0x00, 0xFF, 0xFF, 0xFF, 0x01, 0x02, 0x03]
        let plistString = RGBForcingEngine.generateDisplayOverridePlist(vendorID: 0x10AC, productID: 0x4124, edidBytes: sampleEDID)

        XCTAssertTrue(plistString.contains("<integer>4268</integer>")) // 0x10AC = 4268
        XCTAssertTrue(plistString.contains("<integer>16676</integer>")) // 0x4124 = 16676
        XCTAssertTrue(plistString.contains("<key>IODisplayEDID</key>"))
    }
}
