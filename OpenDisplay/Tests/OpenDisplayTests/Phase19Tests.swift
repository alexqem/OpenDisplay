import XCTest
@testable import OpenDisplayCore

final class Phase19Tests: XCTestCase {

    func testDisplayGroupTargetLevelMath() {
        // Normal addition
        let normal = DisplayGroup.calculateTargetLevel(masterLevel: 0.6, offset: 0.1)
        XCTAssertEqual(normal, 0.7, accuracy: 0.001)

        // Lower clamp (0.0 floor)
        let floored = DisplayGroup.calculateTargetLevel(masterLevel: 0.2, offset: -0.3)
        XCTAssertEqual(floored, 0.0, accuracy: 0.001)

        // Upper clamp (1.0 ceiling)
        let ceilinged = DisplayGroup.calculateTargetLevel(masterLevel: 0.9, offset: 0.2)
        XCTAssertEqual(ceilinged, 1.0, accuracy: 0.001)

        // Negative master input clamped
        let underflow = DisplayGroup.calculateTargetLevel(masterLevel: -0.5, offset: 0.1)
        XCTAssertEqual(underflow, 0.0, accuracy: 0.001)
    }

    func testDisplayGroupMemberOffsetClamping() {
        let clampedHigh = DisplayGroupMember(displayID: 10, brightnessOffset: 0.9, volumeOffset: 1.5)
        XCTAssertEqual(clampedHigh.brightnessOffset, DisplayGroupConstants.maxOffset)
        XCTAssertEqual(clampedHigh.volumeOffset, DisplayGroupConstants.maxOffset)

        let clampedLow = DisplayGroupMember(displayID: 10, brightnessOffset: -0.9, volumeOffset: -1.0)
        XCTAssertEqual(clampedLow.brightnessOffset, DisplayGroupConstants.minOffset)
        XCTAssertEqual(clampedLow.volumeOffset, DisplayGroupConstants.minOffset)
    }

    func testDisplayGroupManagerLinkAndUnlink() {
        let manager = DisplayGroupManager(initialGroups: [])
        let masterID: CGDirectDisplayID = 101
        let slaveID1: CGDirectDisplayID = 201
        let slaveID2: CGDirectDisplayID = 202

        // Link first slave
        manager.linkSlave(masterID: masterID, slaveID: slaveID1, brightnessOffset: 0.05)
        XCTAssertEqual(manager.getAllGroups().count, 1)

        let group1 = manager.groupForMaster(displayID: masterID)
        XCTAssertNotNil(group1)
        XCTAssertEqual(group1?.members.count, 1)
        XCTAssertEqual(group1?.members.first?.displayID, slaveID1)
        XCTAssertEqual(group1?.members.first?.brightnessOffset, 0.05)

        // Link second slave to same master
        manager.linkSlave(masterID: masterID, slaveID: slaveID2, brightnessOffset: -0.10)
        let group2 = manager.groupForMaster(displayID: masterID)
        XCTAssertEqual(group2?.members.count, 2)

        // Containing query
        let containing1 = manager.groupContaining(displayID: slaveID1)
        XCTAssertEqual(containing1?.masterDisplayID, masterID)

        let containingMaster = manager.groupContaining(displayID: masterID)
        XCTAssertEqual(containingMaster?.masterDisplayID, masterID)

        // Cannot link master as slave to itself
        manager.linkSlave(masterID: masterID, slaveID: masterID)
        XCTAssertEqual(manager.groupForMaster(displayID: masterID)?.members.count, 2)

        // Unlink one slave
        manager.unlinkSlave(slaveID: slaveID1)
        let groupAfterUnlink = manager.groupForMaster(displayID: masterID)
        XCTAssertEqual(groupAfterUnlink?.members.count, 1)
        XCTAssertEqual(groupAfterUnlink?.members.first?.displayID, slaveID2)

        // Unlink last slave removes empty group
        manager.unlinkSlave(slaveID: slaveID2)
        XCTAssertEqual(manager.getAllGroups().count, 0)
    }

    func testDisplayGroupJSONSerialization() {
        let manager = DisplayGroupManager(initialGroups: [])
        manager.linkSlave(masterID: 50, slaveID: 60, brightnessOffset: 0.12, volumeOffset: -0.05)

        guard let json = manager.exportGroupsJSON() else {
            XCTFail("Failed to export JSON")
            return
        }

        let newManager = DisplayGroupManager(initialGroups: [])
        XCTAssertTrue(newManager.importGroupsJSON(json))
        XCTAssertEqual(newManager.getAllGroups().count, 1)

        let restored = newManager.groupForMaster(displayID: 50)
        XCTAssertNotNil(restored)
        XCTAssertEqual(restored?.members.first?.displayID, 60)
        XCTAssertEqual(restored?.members.first?.brightnessOffset ?? 0.0, 0.12, accuracy: 0.001)
        XCTAssertEqual(restored?.members.first?.volumeOffset ?? 0.0, -0.05, accuracy: 0.001)
    }

    func testOpenDisplayCLIGroupCommands() {
        let linkCmd = OpenDisplayCLI.parse(arguments: ["link-group", "-master=1", "-slave=2", "-offset=0.15"])
        XCTAssertEqual(linkCmd, .linkGroup(master: "1", slave: "2", offset: 0.15))

        let unlinkCmd = OpenDisplayCLI.parse(arguments: ["unlink-group", "-slave=2"])
        XCTAssertEqual(unlinkCmd, .unlinkGroup(slave: "2"))

        let listCmd = OpenDisplayCLI.parse(arguments: ["list-groups"])
        XCTAssertEqual(listCmd, .listGroups)
    }
}
