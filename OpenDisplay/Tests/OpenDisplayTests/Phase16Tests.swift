import XCTest
@testable import OpenDisplayCore

final class Phase16Tests: XCTestCase {

    func testDDCInputSourceRawValuesAndLabels() {
        XCTAssertEqual(DDCInputSource.displayPort1.rawValue, 0x0F)
        XCTAssertEqual(DDCInputSource.displayPort2.rawValue, 0x10)
        XCTAssertEqual(DDCInputSource.hdmi1.rawValue, 0x11)
        XCTAssertEqual(DDCInputSource.hdmi2.rawValue, 0x12)
        XCTAssertEqual(DDCInputSource.usbC.rawValue, 0x1B)

        XCTAssertEqual(DDCInputSource.displayPort1.label, "DP 1")
        XCTAssertEqual(DDCInputSource.displayPort2.label, "DP 2")
        XCTAssertEqual(DDCInputSource.hdmi1.label, "HDMI 1")
        XCTAssertEqual(DDCInputSource.hdmi2.label, "HDMI 2")
        XCTAssertEqual(DDCInputSource.usbC.label, "USB-C")
    }

    func testDDCInputSourceCLIResolution() {
        XCTAssertEqual(DDCInputSource.from(cliString: "dp1"), .displayPort1)
        XCTAssertEqual(DDCInputSource.from(cliString: "DP1"), .displayPort1)
        XCTAssertEqual(DDCInputSource.from(cliString: "dp2"), .displayPort2)
        XCTAssertEqual(DDCInputSource.from(cliString: "hdmi1"), .hdmi1)
        XCTAssertEqual(DDCInputSource.from(cliString: "HDMI2"), .hdmi2)
        XCTAssertEqual(DDCInputSource.from(cliString: "usbc"), .usbC)
        XCTAssertEqual(DDCInputSource.from(cliString: "USBC"), .usbC)

        // Raw values as numeric strings
        XCTAssertEqual(DDCInputSource.from(cliString: "15"), .displayPort1)
        XCTAssertEqual(DDCInputSource.from(cliString: "17"), .hdmi1)
        XCTAssertEqual(DDCInputSource.from(cliString: "27"), .usbC)

        XCTAssertNil(DDCInputSource.from(cliString: "vga"))
        XCTAssertNil(DDCInputSource.from(cliString: "unknown"))
    }

    func testDDCInputSourceWritePacketEncoding() {
        // Build write packet for VCP 0x60 (inputSource) with value 0x0011 (HDMI 1)
        // Format: [SubAddress 0x51, LengthFlag 0x84, OpCode 0x03, VCP 0x60, ValHigh 0x00, ValLow 0x11, Checksum]
        let packet = DDCPacketSerializer.buildWritePacket(vcpCode: .inputSource, value: DDCInputSource.hdmi1.rawValue)

        XCTAssertEqual(packet.count, 7)
        XCTAssertEqual(packet[0], DDCI2CAddress.ddcSubAddress.rawValue) // 0x51
        XCTAssertEqual(packet[1], DDCProtocolLimits.payloadLengthMask | DDCProtocolLimits.writePayloadCount) // 0x84
        XCTAssertEqual(packet[2], DDCCommandOpCode.setVcp.rawValue) // 0x03
        XCTAssertEqual(packet[3], DDCVcpCode.inputSource.rawValue) // 0x60
        XCTAssertEqual(packet[4], 0x00) // Value High
        XCTAssertEqual(packet[5], 0x11) // Value Low (HDMI 1)

        // Verify XOR Checksum
        var expectedChecksum = DDCI2CAddress.writeXorSeed.rawValue
        for i in 0..<6 {
            expectedChecksum ^= packet[i]
        }
        XCTAssertEqual(packet[6], expectedChecksum)
    }

    func testCLICommandInputSourceParsing() {
        let args1 = ["set-input", "-target=1", "-input=hdmi1"]
        let cmd1 = OpenDisplayCLI.parse(arguments: args1)
        XCTAssertEqual(cmd1, .setInputSource(target: "1", source: "hdmi1"))

        let args2 = ["input", "-input=usbc"]
        let cmd2 = OpenDisplayCLI.parse(arguments: args2)
        XCTAssertEqual(cmd2, .setInputSource(target: AutomationConstants.cliDefaultTargetActive, source: "usbc"))
    }
}
