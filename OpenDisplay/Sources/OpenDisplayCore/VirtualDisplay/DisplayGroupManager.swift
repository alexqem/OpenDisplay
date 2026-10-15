import Foundation
import CoreGraphics

/// Descriptor for a member display within a sync group, including its individual calibration offset
public struct DisplayGroupMember: Codable, Equatable, Identifiable, Sendable {
    public let displayID: CGDirectDisplayID
    public var brightnessOffset: Double // Calibration offset added to master brightness (-0.5 to +0.5)
    public var volumeOffset: Double     // Calibration offset added to master volume (-0.5 to +0.5)

    public var id: CGDirectDisplayID { displayID }

    public init(
        displayID: CGDirectDisplayID,
        brightnessOffset: Double = DisplayGroupConstants.defaultOffset,
        volumeOffset: Double = DisplayGroupConstants.defaultOffset
    ) {
        self.displayID = displayID
        self.brightnessOffset = max(DisplayGroupConstants.minOffset, min(DisplayGroupConstants.maxOffset, brightnessOffset))
        self.volumeOffset = max(DisplayGroupConstants.minOffset, min(DisplayGroupConstants.maxOffset, volumeOffset))
    }
}

/// Unified display group linking a Master display to one or more Slave displays
public struct DisplayGroup: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var masterDisplayID: CGDirectDisplayID
    public var members: [DisplayGroupMember] // Slave displays with individual offsets
    public var isBrightnessSyncEnabled: Bool
    public var varVolumeSyncEnabled: Bool
    public var isPowerSyncEnabled: Bool

    public init(
        id: UUID = UUID(),
        name: String = DisplayGroupConstants.defaultGroupName,
        masterDisplayID: CGDirectDisplayID,
        members: [DisplayGroupMember] = [],
        isBrightnessSyncEnabled: Bool = true,
        varVolumeSyncEnabled: Bool = true,
        isPowerSyncEnabled: Bool = true
    ) {
        self.id = id
        self.name = String(name.prefix(DisplayGroupConstants.maxGroupNameLength))
        self.masterDisplayID = masterDisplayID
        self.members = members.filter { $0.displayID != masterDisplayID }
        self.isBrightnessSyncEnabled = isBrightnessSyncEnabled
        self.varVolumeSyncEnabled = varVolumeSyncEnabled
        self.isPowerSyncEnabled = isPowerSyncEnabled
    }

    /// Pure mathematical calculation of target slave brightness based on master level and member calibration offset
    public static func calculateTargetLevel(masterLevel: Double, offset: Double) -> Double {
        let raw = masterLevel + offset
        return max(DisplayGroupConstants.minLevel, min(DisplayGroupConstants.maxLevel, raw))
    }

    /// Check if a display ID participates in this group (as master or member)
    public func contains(displayID: CGDirectDisplayID) -> Bool {
        return masterDisplayID == displayID || members.contains(where: { $0.displayID == displayID })
    }

    /// Returns member settings for a specific slave display
    public func member(for displayID: CGDirectDisplayID) -> DisplayGroupMember? {
        return members.first(where: { $0.displayID == displayID })
    }
}

/// In-memory manager for Display Synchronization Groups (100% pure logic, thread-safe, non-Apple host testable)
public final class DisplayGroupManager: @unchecked Sendable {
    public static let shared = DisplayGroupManager()

    private var groups: [DisplayGroup] = []
    private let lock = NSLock()

    public init(initialGroups: [DisplayGroup] = []) {
        self.groups = initialGroups
    }

    /// Retrieve all configured groups
    public func getAllGroups() -> [DisplayGroup] {
        lock.lock()
        defer { lock.unlock() }
        return groups
    }

    /// Find the group where this display is registered as the Master
    public func groupForMaster(displayID: CGDirectDisplayID) -> DisplayGroup? {
        lock.lock()
        defer { lock.unlock() }
        return groups.first(where: { $0.masterDisplayID == displayID })
    }

    /// Find the group containing this display (as master or slave)
    public func groupContaining(displayID: CGDirectDisplayID) -> DisplayGroup? {
        lock.lock()
        defer { lock.unlock() }
        return groups.first(where: { $0.contains(displayID: displayID) })
    }

    /// Register or update a group
    public func setGroup(_ group: DisplayGroup) {
        lock.lock()
        defer { lock.unlock() }
        if let idx = groups.firstIndex(where: { $0.id == group.id }) {
            groups[idx] = group
        } else {
            groups.append(group)
        }
    }

    /// Remove a group by its unique ID
    @discardableResult
    public func removeGroup(id: UUID) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard let idx = groups.firstIndex(where: { $0.id == id }) else {
            return false
        }
        groups.remove(at: idx)
        return true
    }

    /// Add a slave display to a master's group, creating group if necessary
    public func linkSlave(masterID: CGDirectDisplayID, slaveID: CGDirectDisplayID, brightnessOffset: Double = 0.0, volumeOffset: Double = 0.0) {
        guard masterID != slaveID else { return }
        lock.lock()
        defer { lock.unlock() }

        // Remove slave from any existing groups first
        for i in 0..<groups.count {
            groups[i].members.removeAll(where: { $0.displayID == slaveID })
        }

        if let idx = groups.firstIndex(where: { $0.masterDisplayID == masterID }) {
            var group = groups[idx]
            group.members.removeAll(where: { $0.displayID == slaveID })
            group.members.append(DisplayGroupMember(
                displayID: slaveID,
                brightnessOffset: brightnessOffset,
                volumeOffset: volumeOffset
            ))
            groups[idx] = group
        } else {
            let newGroup = DisplayGroup(
                masterDisplayID: masterID,
                members: [DisplayGroupMember(
                    displayID: slaveID,
                    brightnessOffset: brightnessOffset,
                    volumeOffset: volumeOffset
                )]
            )
            groups.append(newGroup)
        }
    }

    /// Unlink a slave display from all groups
    public func unlinkSlave(slaveID: CGDirectDisplayID) {
        lock.lock()
        defer { lock.unlock() }
        for i in 0..<groups.count {
            groups[i].members.removeAll(where: { $0.displayID == slaveID })
        }
        // Cleanup empty groups
        groups.removeAll(where: { $0.members.isEmpty })
    }

    /// Pure JSON serialization of all groups
    public func exportGroupsJSON() -> Data? {
        lock.lock()
        defer { lock.unlock() }
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try? encoder.encode(groups)
    }

    /// Pure JSON deserialization of groups
    public func importGroupsJSON(_ data: Data) -> Bool {
        let decoder = JSONDecoder()
        guard let decoded = try? decoder.decode([DisplayGroup].self, from: data) else {
            return false
        }
        lock.lock()
        defer { lock.unlock() }
        self.groups = decoded
        return true
    }
}
