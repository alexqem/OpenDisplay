import Foundation

/// Parsed descriptor for an external display's EDID (Extended Display Identification Data)
public struct ParsedEDID: Sendable {
    public let manufacturer: String
    public let productID: UInt16
    public let serialNumber: UInt32
    public let monitorName: String?
    public let hasCTA861Extension: Bool
    public let rawBytes: [UInt8]
}

/// Pure functional parser and validator for EDID 1.4 Base and Extension Blocks
public enum EDIDParser {

    /// Validate 128-byte block modulo 256 checksum
    public static func validateBlockChecksum(block: [UInt8]) -> Bool {
        guard block.count >= EDIDConstants.baseBlockLength else { return false }
        var sum: UInt32 = 0
        for i in 0..<EDIDConstants.baseBlockLength {
            sum += UInt32(block[i])
        }
        return (sum % 256) == 0
    }

    /// Decode 3-letter manufacturer abbreviation from 2 big-endian bytes
    public static func decodeManufacturer(byte1: UInt8, byte2: UInt8) -> String {
        let word = (UInt16(byte1) << 8) | UInt16(byte2)
        let char1 = Character(UnicodeScalar(UInt8((word >> 10) & 0x1F) + 64))
        let char2 = Character(UnicodeScalar(UInt8((word >> 5) & 0x1F) + 64))
        let char3 = Character(UnicodeScalar(UInt8(word & 0x1F) + 64))
        return String([char1, char2, char3])
    }

    /// Parse complete EDID byte stream
    public static func parse(bytes: [UInt8]) -> ParsedEDID? {
        guard bytes.count >= EDIDConstants.baseBlockLength else { return nil }

        // 1. Verify 8-byte fixed header: 00 FF FF FF FF FF FF 00
        for i in 0..<EDIDConstants.fixedHeader.count {
            if bytes[i] != EDIDConstants.fixedHeader[i] {
                return nil
            }
        }

        // 2. Validate Base Block Checksum
        guard validateBlockChecksum(block: Array(bytes[0..<EDIDConstants.baseBlockLength])) else {
            return nil
        }

        // 3. Extract Manufacturer Code (bytes 8..9)
        let mfg = decodeManufacturer(byte1: bytes[8], byte2: bytes[9])

        // 4. Extract Product ID (bytes 10..11, little endian)
        let productID = UInt16(bytes[10]) | (UInt16(bytes[11]) << 8)

        // 5. Extract Serial Number (bytes 12..15, little endian)
        let serial = UInt32(bytes[12]) |
                     (UInt32(bytes[13]) << 8) |
                     (UInt32(bytes[14]) << 16) |
                     (UInt32(bytes[15]) << 24)

        // 6. Check for CTA-861 Extension at offset 128
        var hasCTA861 = false
        if bytes.count >= (EDIDConstants.extensionBlockOffset + EDIDConstants.baseBlockLength) {
            hasCTA861 = bytes[EDIDConstants.extensionBlockOffset] == EDIDConstants.cta861ExtensionTag
        }

        // 7. Search for Monitor Name in 18-byte Descriptor Blocks (bytes 54..125)
        var monitorName: String?
        for descriptorIndex in 0..<4 {
            let offset = 54 + (descriptorIndex * 18)
            // Monitor Name Descriptor tag: byte 0..2 are 0, byte 3 is 0xFC
            if bytes[offset] == 0 && bytes[offset + 1] == 0 && bytes[offset + 2] == 0 && bytes[offset + 3] == 0xFC {
                let nameBytes = bytes[(offset + 5)..<(offset + 18)]
                let cleanBytes = nameBytes.prefix { $0 != 0x0A && $0 != 0x00 }
                monitorName = String(bytes: cleanBytes, encoding: .ascii)?.trimmingCharacters(in: .whitespaces)
                break
            }
        }

        return ParsedEDID(
            manufacturer: mfg,
            productID: productID,
            serialNumber: serial,
            monitorName: monitorName,
            hasCTA861Extension: hasCTA861,
            rawBytes: bytes
        )
    }
}
