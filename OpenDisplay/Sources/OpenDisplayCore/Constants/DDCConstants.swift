import Foundation

/// DDC/CI Standard VCP (Virtual Control Panel) Feature OpCodes
public enum DDCVcpCode: UInt8, CaseIterable, Sendable {
    case factoryReset          = 0x04
    case restoreBrightness     = 0x05
    case restoreColor          = 0x08
    case brightness            = 0x10
    case contrast              = 0x12
    case selectColorPreset     = 0x14
    case redGain               = 0x16
    case greenGain             = 0x18
    case blueGain              = 0x1A
    case inputSource           = 0x60
    case audioSpeakerVolume    = 0x62
    case audioMute             = 0x8D
    case controlLock           = 0xAE
    case monitorStatus         = 0xB6
    case powerControl          = 0xD6
    case capabilitiesRequest   = 0xF3
}

/// DDC/CI I2C Bus Addresses and Protocol Seeds
public enum DDCI2CAddress: UInt8, Sendable {
    case ddcSlaveAddress       = 0x37
    case ddcSubAddress         = 0x51
    case writeXorSeed          = 0x6E
    case readXorSeed           = 0x6F
    case edidI2CAddress        = 0x50
}

/// DDC/CI Command OpCodes (Direction & Request Type)
public enum DDCCommandOpCode: UInt8, Sendable {
    case getVcp                   = 0x01
    case getVcpReply              = 0x02
    case setVcp                   = 0x03
    case mccsCapabilitiesReply    = 0xE3
    case mccsCapabilitiesRequest  = 0xF3
}

/// Timing, retry budgets and buffer constraints for DDC/CI communication
public enum DDCProtocolLimits {
    public static let defaultSleepMilliseconds: UInt32 = 40
    public static let maxRetryAttempts: Int = 3
    public static let maxCapabilitiesReplyChunkSize: Int = 32
    public static let standardPacketHeaderLength: Int = 3
    public static let standardPacketOverhead: Int = 4
    public static let payloadLengthMask: UInt8 = 0x80
    public static let writePayloadCount: UInt8 = 4 // setVcp payload: 4 bytes
    public static let readPayloadCount: UInt8 = 2  // getVcp payload: 2 bytes
    public static let standardReplyMinLength: Int = 11
    public static let readReplyBufferSize: Int = 12
    public static let resultCodeSuccess: UInt8 = 0x00
    public static let vcpPercentScale: UInt16 = 100
    public static let audioMuteEngaged: UInt16 = 1
    public static let audioMuteReleased: UInt16 = 2
}

/// Standard DDC/CI Input Source Codes (VCP 0x60)
public enum DDCInputSource: UInt16, CaseIterable, Sendable, Identifiable {
    case displayPort1 = 0x0F
    case displayPort2 = 0x10
    case hdmi1        = 0x11
    case hdmi2        = 0x12
    case usbC         = 0x1B

    public var id: UInt16 { rawValue }

    public var label: String {
        switch self {
        case .displayPort1: return "DP 1"
        case .displayPort2: return "DP 2"
        case .hdmi1:        return "HDMI 1"
        case .hdmi2:        return "HDMI 2"
        case .usbC:         return "USB-C"
        }
    }

    public var cliIdentifier: String {
        switch self {
        case .displayPort1: return "dp1"
        case .displayPort2: return "dp2"
        case .hdmi1:        return "hdmi1"
        case .hdmi2:        return "hdmi2"
        case .usbC:         return "usbc"
        }
    }

    public static func from(cliString: String) -> DDCInputSource? {
        let normalized = cliString.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return allCases.first { $0.cliIdentifier == normalized || String($0.rawValue) == normalized }
    }
}

