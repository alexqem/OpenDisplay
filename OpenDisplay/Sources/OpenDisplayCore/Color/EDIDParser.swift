import Foundation

/// Autodetected hardware capabilities of an attached HDMI or DisplayPort monitor
public struct DisplayCapabilities: Equatable, Sendable {
    public let isHDMI: Bool
    public let supportsYCbCr444: Bool
    public let supportsYCbCr422: Bool
    public let supportsBasicAudio: Bool
    public let supportsUnderscan: Bool
    public let supports10BitDeepColor: Bool
    public let supportsHDR: Bool
    public let supportsDDC: Bool
    public let physicalAddress: String? // HDMI-CEC physical address (e.g., "1.0.0.0")

    public init(
        isHDMI: Bool = false,
        supportsYCbCr444: Bool = false,
        supportsYCbCr422: Bool = false,
        supportsBasicAudio: Bool = false,
        supportsUnderscan: Bool = false,
        supports10BitDeepColor: Bool = false,
        supportsHDR: Bool = false,
        supportsDDC: Bool = false,
        physicalAddress: String? = nil
    ) {
        self.isHDMI = isHDMI
        self.supportsYCbCr444 = supportsYCbCr444
        self.supportsYCbCr422 = supportsYCbCr422
        self.supportsBasicAudio = supportsBasicAudio
        self.supportsUnderscan = supportsUnderscan
        self.supports10BitDeepColor = supports10BitDeepColor
        self.supportsHDR = supportsHDR
        self.supportsDDC = supportsDDC
        self.physicalAddress = physicalAddress
    }

    /// Empty capabilities for virtual or unprobed displays
    public static let fallback = DisplayCapabilities()
}

/// Parsed descriptor for an external display's EDID (Extended Display Identification Data)
public struct ParsedEDID: Sendable {
    public let manufacturer: String
    public let productID: UInt16
    public let serialNumber: UInt32
    public let monitorName: String?
    public let hasCTA861Extension: Bool
    public let capabilities: DisplayCapabilities
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

    /// Inspect CTA-861 Extension Block for HDMI VSDB, YCbCr, and Audio capabilities
    public static func inspectCTA861Capabilities(bytes: [UInt8]) -> DisplayCapabilities {
        guard bytes.count >= (EDIDConstants.extensionBlockOffset + EDIDConstants.baseBlockLength) else {
            return DisplayCapabilities.fallback
        }

        let extStart = EDIDConstants.extensionBlockOffset
        guard bytes[extStart] == EDIDConstants.cta861ExtensionTag else {
            return DisplayCapabilities.fallback
        }

        // Byte 3 of CTA-861: Feature flags
        let flagsByte = bytes[extStart + EDIDConstants.CTA861Flags.byteIndexInBlock]
        let supportsYCbCr444 = (flagsByte & EDIDConstants.CTA861Flags.ycbcr444Mask) != 0
        let supportsYCbCr422 = (flagsByte & EDIDConstants.CTA861Flags.ycbcr422Mask) != 0
        let supportsAudio = (flagsByte & EDIDConstants.CTA861Flags.basicAudioMask) != 0
        let supportsUnderscan = (flagsByte & EDIDConstants.CTA861Flags.underscanMask) != 0

        // Parse Data Block Collection (starts at byte 4 up to d offset)
        let dOffset = Int(bytes[extStart + 2])
        let dataBlockEnd = min(extStart + dOffset, extStart + EDIDConstants.baseBlockLength - 1)
        var cursor = extStart + 4

        var isHDMI = false
        var physicalAddr: String? = nil

        while cursor < dataBlockEnd {
            let header = bytes[cursor]
            let tag = (header >> 5) & 0x07
            let length = Int(header & 0x1F)
            cursor += 1

            // Tag 3 = Vendor-Specific Data Block (VSDB)
            if tag == EDIDConstants.HDMIVSDBConstants.vsdbTagCode, length >= 3, cursor + length <= bytes.count {
                // Check 24-bit IEEE Registration Identifier for HDMI: 00-0C-03 (little-endian: 03 0C 00)
                let b0 = bytes[cursor]
                let b1 = bytes[cursor + 1]
                let b2 = bytes[cursor + 2]
                if b0 == EDIDConstants.HDMIVSDBConstants.ieeeRegistrationByte0 &&
                   b1 == EDIDConstants.HDMIVSDBConstants.ieeeRegistrationByte1 &&
                   b2 == EDIDConstants.HDMIVSDBConstants.ieeeRegistrationByte2 {
                    isHDMI = true

                    // Bytes 4-5: Physical Address (e.g. 1.0.0.0 for CEC routing)
                    if length >= 5 {
                        let a = (bytes[cursor + 3] >> 4) & 0x0F
                        let b = bytes[cursor + 3] & 0x0F
                        let c = (bytes[cursor + 4] >> 4) & 0x0F
                        let d = bytes[cursor + 4] & 0x0F
                        physicalAddr = "\(a).\(b).\(c).\(d)"
                    }
                }
            }

            cursor += length
        }

        return DisplayCapabilities(
            isHDMI: isHDMI,
            supportsYCbCr444: supportsYCbCr444,
            supportsYCbCr422: supportsYCbCr422,
            supportsBasicAudio: supportsAudio,
            supportsUnderscan: supportsUnderscan,
            supports10BitDeepColor: false,
            supportsHDR: false,
            supportsDDC: true,
            physicalAddress: physicalAddr
        )
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

        // 6. Check for CTA-861 Extension at offset 128 & Extract Capabilities
        var hasCTA861 = false
        var caps = DisplayCapabilities.fallback
        if bytes.count >= (EDIDConstants.extensionBlockOffset + EDIDConstants.baseBlockLength) {
            hasCTA861 = bytes[EDIDConstants.extensionBlockOffset] == EDIDConstants.cta861ExtensionTag
            if hasCTA861 {
                caps = inspectCTA861Capabilities(bytes: bytes)
            }
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
            capabilities: caps,
            rawBytes: bytes
        )
    }
}
