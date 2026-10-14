import Foundation

/// Pure functional DDC/CI packet serializer and validator (100% testable without hardware)
public enum DDCPacketSerializer {

    /// Compute DDC/CI XOR Checksum with initial seed
    public static func computeChecksum(packet: [UInt8], seed: UInt8 = DDCI2CAddress.writeXorSeed.rawValue) -> UInt8 {
        var checksum = seed
        for byte in packet {
            checksum ^= byte
        }
        return checksum
    }

    /// Construct standard DDC/CI Write Packet for a VCP code and 16-bit value
    /// Packet: [SubAddress, Length | 0x80, OpCode(0x03), VcpCode, ValueHigh, ValueLow, Checksum]
    public static func buildWritePacket(vcpCode: DDCVcpCode, value: UInt16) -> [UInt8] {
        let subAddress = DDCI2CAddress.ddcSubAddress.rawValue
        let lengthFlag: UInt8 = DDCProtocolLimits.payloadLengthMask | DDCProtocolLimits.writePayloadCount
        let setCommandOpCode = DDCCommandOpCode.setVcp.rawValue
        let valHigh = UInt8((value >> 8) & 0xFF)
        let valLow = UInt8(value & 0xFF)

        var packet: [UInt8] = [subAddress, lengthFlag, setCommandOpCode, vcpCode.rawValue, valHigh, valLow]
        let checksum = computeChecksum(packet: packet, seed: DDCI2CAddress.writeXorSeed.rawValue)
        packet.append(checksum)
        return packet
    }

    /// Construct standard DDC/CI Read Request Packet for a VCP code
    /// Packet: [SubAddress, Length | 0x80, OpCode(0x01), VcpCode, Checksum]
    public static func buildReadPacket(vcpCode: DDCVcpCode) -> [UInt8] {
        let subAddress = DDCI2CAddress.ddcSubAddress.rawValue
        let lengthFlag: UInt8 = DDCProtocolLimits.payloadLengthMask | DDCProtocolLimits.readPayloadCount
        let getCommandOpCode = DDCCommandOpCode.getVcp.rawValue

        var packet: [UInt8] = [subAddress, lengthFlag, getCommandOpCode, vcpCode.rawValue]
        let checksum = computeChecksum(packet: packet, seed: DDCI2CAddress.writeXorSeed.rawValue)
        packet.append(checksum)
        return packet
    }

    /// Parse DDC/CI VCP Read Reply Buffer and validate checksum
    /// Expected format: [SourceAddress(0x6E), Length | 0x80, OpCode(0x02), ResultCode(0x00), VcpCode, Type, MaxHigh, MaxLow, CurHigh, CurLow, Checksum]
    public static func parseReadReply(buffer: [UInt8], expectedVcp: DDCVcpCode) -> (current: UInt16, max: UInt16)? {
        guard buffer.count >= DDCProtocolLimits.standardReplyMinLength else { return nil }
        guard buffer[2] == DDCCommandOpCode.getVcpReply.rawValue else { return nil }
        guard buffer[3] == DDCProtocolLimits.resultCodeSuccess else { return nil }
        guard buffer[4] == expectedVcp.rawValue else { return nil }

        // Validate XOR Checksum over all reply bytes including SourceAddress (seed = readXorSeed 0x6F)
        var checksum = DDCI2CAddress.readXorSeed.rawValue
        for i in 0..<(DDCProtocolLimits.standardReplyMinLength - 1) {
            checksum ^= buffer[i]
        }
        guard buffer[DDCProtocolLimits.standardReplyMinLength - 1] == checksum else {
            return nil
        }

        let maxVal = (UInt16(buffer[6]) << 8) | UInt16(buffer[7])
        let curVal = (UInt16(buffer[8]) << 8) | UInt16(buffer[9])
        return (curVal, maxVal)
    }

    /// Extract supported VCP hex opcodes from MCCS Capabilities String, safely handling nested parens
    public static func parseMCCSCapabilitiesVCPs(capabilitiesString: String) -> Set<UInt8> {
        var supportedVCPs = Set<UInt8>()
        guard let vcpStartRange = capabilitiesString.range(of: "vcp(") else {
            return supportedVCPs
        }

        let remainder = capabilitiesString[vcpStartRange.upperBound...]
        // Track parenthesis nesting depth to extract full vcp(...) contents
        var depth = 1
        var vcpContent = ""
        for char in remainder {
            if char == "(" {
                depth += 1
            } else if char == ")" {
                depth -= 1
                if depth == 0 { break }
            }
            vcpContent.append(char)
        }

        // Tokenize 2-character hex codes
        let tokens = vcpContent.split { $0 == " " || $0 == "(" || $0 == ")" }
        for token in tokens {
            if token.count == 2, let code = UInt8(token, radix: 16) {
                supportedVCPs.insert(code)
            }
        }
        return supportedVCPs
    }
}

#if os(macOS) && arch(arm64)
import IOKit

/// Direct Apple Silicon DDC/CI Hardware Controller using private IOAVService
public final class IOAVServiceDDC {
    private typealias IOAVServiceCreateFunc = @convention(c) (CFAllocator?, io_service_t) -> UnsafeMutableRawPointer?
    private typealias IOAVServiceWriteI2CFunc = @convention(c) (UnsafeMutableRawPointer, UInt32, UInt32, UnsafePointer<UInt8>, UInt32) -> kern_return_t
    private typealias IOAVServiceReadI2CFunc = @convention(c) (UnsafeMutableRawPointer, UInt32, UInt32, UnsafeMutablePointer<UInt8>, UInt32) -> kern_return_t

    private let avServiceHandle: UnsafeMutableRawPointer
    private let writeI2CFn: IOAVServiceWriteI2CFunc
    private let readI2CFn: IOAVServiceReadI2CFunc

    public init?(service: io_service_t) {
        let library = DynamicLibrary()
        guard let createFn = library.resolve("_IOAVServiceCreateWithService", as: IOAVServiceCreateFunc.self),
              let writeFn = library.resolve("_IOAVServiceWriteI2C", as: IOAVServiceWriteI2CFunc.self),
              let readFn = library.resolve("_IOAVServiceReadI2C", as: IOAVServiceReadI2CFunc.self),
              let avHandle = createFn(kCFAllocatorDefault, service) else {
            return nil
        }
        self.avServiceHandle = avHandle
        self.writeI2CFn = writeFn
        self.readI2CFn = readFn
    }

    private var i2cCoordinates: (slave: UInt32, sub: UInt32) {
        return (UInt32(DDCI2CAddress.ddcSlaveAddress.rawValue), UInt32(DDCI2CAddress.ddcSubAddress.rawValue))
    }

    /// Send a DDC/CI VCP command with auto-retry
    public func setVCP(code: DDCVcpCode, value: UInt16) -> Bool {
        let packet = DDCPacketSerializer.buildWritePacket(vcpCode: code, value: value)
        let (slave, sub) = i2cCoordinates

        for _ in 0..<DDCProtocolLimits.maxRetryAttempts {
            let kr = packet.withUnsafeBufferPointer { ptr in
                writeI2CFn(avServiceHandle, slave, sub, ptr.baseAddress!, UInt32(packet.count))
            }
            if kr == KERN_SUCCESS {
                return true
            }
            usleep(DDCProtocolLimits.defaultSleepMilliseconds * 1000)
        }
        return false
    }

    /// Engage or release hardware audio mute via DDC/CI VCP 0x8D
    public func setAudioMute(muted: Bool) -> Bool {
        let value = muted ? DDCProtocolLimits.audioMuteEngaged : DDCProtocolLimits.audioMuteReleased
        return setVCP(code: .audioMute, value: value)
    }

    /// Switch active video input source via DDC/CI VCP 0x60
    public func setInputSource(_ source: DDCInputSource) -> Bool {
        return setVCP(code: .inputSource, value: source.rawValue)
    }

    /// Read current active video input source via DDC/CI VCP 0x60
    public func getInputSource() -> DDCInputSource? {
        guard let result = getVCP(code: .inputSource) else { return nil }
        return DDCInputSource(rawValue: result.current)
    }
}
#endif
