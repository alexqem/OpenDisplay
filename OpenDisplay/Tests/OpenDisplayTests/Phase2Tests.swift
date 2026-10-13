import XCTest
@testable import OpenDisplayCore

final class Phase2Tests: XCTestCase {

    func testDDCWritePacketFraming() {
        // Brightness = 0x10, Value = 80 (0x0050)
        let packet = DDCPacketSerializer.buildWritePacket(vcpCode: .brightness, value: 80)
        
        // Expected layout: [0x51, 0x84, 0x03, 0x10, 0x00, 0x50, checksum]
        XCTAssertEqual(packet.count, 7)
        XCTAssertEqual(packet[0], 0x51)
        XCTAssertEqual(packet[1], 0x84)
        XCTAssertEqual(packet[2], 0x03)
        XCTAssertEqual(packet[3], 0x10) // VCP Brightness
        XCTAssertEqual(packet[4], 0x00) // High byte
        XCTAssertEqual(packet[5], 0x50) // Low byte (80)

        // Verify checksum: 0x6E ^ 0x51 ^ 0x84 ^ 0x03 ^ 0x10 ^ 0x00 ^ 0x50
        var expectedChecksum: UInt8 = 0x6E
        for i in 0..<6 {
            expectedChecksum ^= packet[i]
        }
        XCTAssertEqual(packet[6], expectedChecksum)
    }

    func testDDCReadPacketFraming() {
        // Contrast = 0x12
        let packet = DDCPacketSerializer.buildReadPacket(vcpCode: .contrast)

        // Expected layout: [0x51, 0x82, 0x01, 0x12, checksum]
        XCTAssertEqual(packet.count, 5)
        XCTAssertEqual(packet[0], 0x51)
        XCTAssertEqual(packet[1], 0x82)
        XCTAssertEqual(packet[2], 0x01)
        XCTAssertEqual(packet[3], 0x12)

        var expectedChecksum: UInt8 = 0x6E
        for i in 0..<4 {
            expectedChecksum ^= packet[i]
        }
        XCTAssertEqual(packet[4], expectedChecksum)
    }

    func testDDCReadReplyParsing() {
        // Mock reply for Brightness: current = 75 (0x004B), max = 100 (0x0064)
        // Checksum calculated with seed 0x6F = 0xB4
        var mockReply: [UInt8] = [
            0x6E, 0x88, 0x02, 0x00, 0x10, 0x00,
            0x00, 0x64, // Max = 100
            0x00, 0x4B  // Cur = 75
        ]
        var checksum: UInt8 = DDCI2CAddress.readXorSeed.rawValue
        for byte in mockReply { checksum ^= byte }
        mockReply.append(checksum)

        let result = DDCPacketSerializer.parseReadReply(buffer: mockReply, expectedVcp: .brightness)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.current, 75)
        XCTAssertEqual(result?.max, 100)

        // Corrupted checksum should fail validation
        var corrupted = mockReply
        corrupted[corrupted.count - 1] ^= 0xFF
        XCTAssertNil(DDCPacketSerializer.parseReadReply(buffer: corrupted, expectedVcp: .brightness))
    }

    func testMCCSCapabilitiesVCPParsingWithNestedParens() {
        let sampleCaps = "(prot(monitor)type(LCD)model(Dell U2720Q)cmds(01 02 03 07 0C E3 F3)vcp(02 04 05 08 10 12(01 05) 14 16 18 1A 52 60(01 03) 62 8D AC AE B2 B6 C6 C8 C9 D6(01 04) DF FD)mccs_ver(2.1))"

        let vcps = DDCPacketSerializer.parseMCCSCapabilitiesVCPs(capabilitiesString: sampleCaps)
        XCTAssertTrue(vcps.contains(0x10)) // Brightness
        XCTAssertTrue(vcps.contains(0x12)) // Contrast with nested sub-values
        XCTAssertTrue(vcps.contains(0x60)) // Input with nested sub-values
        XCTAssertTrue(vcps.contains(0x62)) // Volume
        XCTAssertTrue(vcps.contains(0x8D)) // Mute
        XCTAssertTrue(vcps.contains(0xD6)) // Power with nested sub-values

        XCTAssertFalse(vcps.contains(0xFF))
    }
}
