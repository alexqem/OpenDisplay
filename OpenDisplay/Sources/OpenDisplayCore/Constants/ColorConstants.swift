import Foundation

/// Pixel Encoding Formats used by SkyLight & CoreGraphics
public enum ColorPixelFormat: String, Sendable {
    case argb8888     = "ARGB8888"
    case argb2101010  = "ARGB2101010"
    case rgba16Float  = "RGBA16Float"

    public var bitsPerSample: Int32 {
        switch self {
        case .argb8888:    return 8
        case .argb2101010: return 10
        case .rgba16Float: return 16
        }
    }

    public var isDeepColor: Bool {
        return bitsPerSample >= 10
    }
}

/// Bit offsets and constants for EDID 1.4 Base and CTA-861 Extension Blocks
public enum EDIDConstants {
    public static let baseBlockLength: Int = 128
    public static let extensionBlockOffset: Int = 128
    public static let fixedHeader: [UInt8] = [0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00]
    public static let cta861ExtensionTag: UInt8 = 0x02

    /// CTA-861 Extension Block structural layout and Data Block parsing constants
    public enum CTA861Structure {
        public static let dOffsetByteIndex: Int = 2
        public static let dataBlockCollectionStartOffset: Int = 4
        public static let tagBitShift: UInt8 = 5
        public static let tagMask: UInt8 = 0x07
        public static let lengthMask: UInt8 = 0x1F
        public static let highNibbleShift: UInt8 = 4
        public static let nibbleMask: UInt8 = 0x0F
        public static let minVSDBHeaderLength: Int = 3
        public static let minCECPhysicalAddressLength: Int = 5
    }

    /// Byte 3 of CTA-861 Extension Block: Color format capability flags
    public enum CTA861Flags {
        public static let byteIndexInBlock: Int = 3
        public static let ycbcr444Mask: UInt8 = 1 << 5
        public static let ycbcr422Mask: UInt8 = 1 << 4
        public static let basicAudioMask: UInt8 = 1 << 6
        public static let underscanMask: UInt8 = 1 << 7
    }

    /// HDMI Vendor-Specific Data Block (IEEE Registration Identifier 0x000C03)
    public enum HDMIVSDBConstants {
        public static let ieeeRegistrationByte0: UInt8 = 0x03
        public static let ieeeRegistrationByte1: UInt8 = 0x0C
        public static let ieeeRegistrationByte2: UInt8 = 0x00
        public static let vsdbTagCode: UInt8 = 0x03
    }
}

/// Transfer Table (LUT) limits for software dimming
public enum GammaTableConstants {
    public static let standardTableSize: UInt32 = 256
    public static let highPrecisionTableSize: UInt32 = 1024
    public static let minLuminanceFloor: Float = 0.001
}

/// Constants for Liquid Retina XDR / EDR Headroom Overdrive
public enum XDROverdriveConstants {
    public static let baseSDRNits: Float = 500.0
    public static let peakXDRNits: Float = 1600.0
    public static let defaultHeadroomMultiplier: Float = 1.0
}

/// Constants for ColorSync and ICC Profile Management
public enum ColorProfileConstants {
    public static let iccExtension: String = "icc"
    public static let icmExtension: String = "icm"
    public static let defaultColorSpace: String = "RGB"
    public static let userColorSyncSubpath: String = "Library/ColorSync/Profiles"
    public static let headerColorSpaceOffset: Int = 16
    public static let headerColorSpaceLength: Int = 4
    public static let minHeaderLength: Int = 20
    public static let asciiPrintableMin: UInt8 = 0x20
    public static let asciiPrintableMax: UInt8 = 0x7E
    public static let deepColorDCountThreshold: Int = 30
    public static let standardBitsPerChannel: Int = 8
    public static let deepBitsPerChannel: Int = 10
    public static let defaultSearchDirectories: [String] = [
        "/Library/ColorSync/Profiles",
        "/System/Library/ColorSync/Profiles"
    ]
}
