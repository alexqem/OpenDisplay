import Foundation

/// ICC Color Profile descriptor (100% testable value type)
public struct ICCProfileInfo: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let name: String
    public let path: URL
    public let colorSpaceType: String

    public init(id: UUID = UUID(), name: String, path: URL, colorSpaceType: String = ColorProfileConstants.defaultColorSpace) {
        self.id = id
        self.name = name
        self.path = path
        self.colorSpaceType = colorSpaceType
    }
}

/// Pure logic for ICC Profile Header inspection and color space detection
public enum ICCHeaderParser {

    /// Extract color space tag from raw ICC header bytes (offset 16, length 4)
    public static func parseColorSpaceType(headerData: Data) -> String {
        guard headerData.count >= ColorProfileConstants.minHeaderLength else {
            return ColorProfileConstants.defaultColorSpace
        }

        let slice = headerData[ColorProfileConstants.headerColorSpaceOffset..<(ColorProfileConstants.headerColorSpaceOffset + ColorProfileConstants.headerColorSpaceLength)]
        let bytes = [UInt8](slice)

        // Ensure printable ASCII
        guard bytes.allSatisfy({ $0 >= ColorProfileConstants.asciiPrintableMin && $0 <= ColorProfileConstants.asciiPrintableMax }),
              let tag = String(bytes: bytes, encoding: .ascii) else {
            return ColorProfileConstants.defaultColorSpace
        }

        let trimmed = tag.trimmingCharacters(in: .whitespaces)
        switch trimmed {
        case "RGB":  return "RGB"
        case "CMYK": return "CMYK"
        case "GRAY": return "Gray"
        case "LAB":  return "Lab"
        case "XYZ":  return "XYZ"
        default:     return trimmed.isEmpty ? ColorProfileConstants.defaultColorSpace : trimmed
        }
    }

    /// Calculate bits per channel from CoreGraphics pixel encoding string
    public static func bitsPerChannel(from encoding: String) -> Int {
        let rCount = encoding.filter { $0 == "R" }.count
        if rCount > 0 { return rCount }
        let dCount = encoding.filter { $0 == "D" }.count
        return dCount >= ColorProfileConstants.deepColorDCountThreshold
            ? ColorProfileConstants.deepBitsPerChannel
            : ColorProfileConstants.standardBitsPerChannel
    }
}

/// Pure logic for filtering per-display ICC profile litter.
/// macOS keeps `/Library/ColorSync/Profiles/Displays/<Name>-<UUID>.icc` forever after a
/// display (especially a virtual one) dies, so profile pickers must filter that
/// directory to UUIDs of currently-online displays.
public enum ICCProfileFilter {

    /// Identify whether an ICC profile lives in the per-display auto-generated directory
    public static func isPerDisplayProfile(directoryName: String) -> Bool {
        directoryName == ColorProfileConstants.displaysDirectory
    }

    /// Extract the ColorSync UUID from a per-display profile filename
    /// ("Color LCD-37D8832A-2D66-02CA-B9F7-8F30A301B230" -> "37D8832A-...-B230")
    public static func displayUUID(fromProfileFileName fileName: String) -> String? {
        let name = (fileName as NSString).deletingPathExtension
        let parts = name.split(separator: "-", omittingEmptySubsequences: false).map(String.init)
        // UUID = 8-4-4-4-12 hex segments at the tail
        guard parts.count >= 5 else { return nil }
        let tail = Array(parts.suffix(5))
        let expected = [8, 4, 4, 4, 12]
        for (segment, length) in zip(tail, expected) {
            guard segment.count == length, segment.allSatisfy({ $0.isHexDigit }) else { return nil }
        }
        return tail.joined(separator: "-")
    }

    /// Whether a profile file belongs in the picker list
    public static func shouldInclude(
        fileName: String,
        isPerDisplayProfile: Bool,
        onlineDisplayUUIDs: Set<String>
    ) -> Bool {
        guard isPerDisplayProfile else { return true }
        guard let uuid = displayUUID(fromProfileFileName: fileName) else { return false }
        return onlineDisplayUUIDs.contains(uuid)
    }
}

#if os(macOS) && arch(arm64)
import CoreGraphics
@preconcurrency import ColorSync

/// Service managing display ICC color profiles via ColorSync
public final class ColorProfileController: @unchecked Sendable {
    public static let shared = ColorProfileController()

    private init() {}

    /// Enumerate all available ICC profiles from standard filesystem directories.
    /// Factory/working-space profiles always pass; per-display profiles (Displays/
    /// subdirectory) are kept only when their UUID matches a currently-online display.
    public func enumerateProfiles() -> [ICCProfileInfo] {
        let onlineUUIDs = Self.onlineDisplayUUIDs()
        var profiles: [ICCProfileInfo] = []
        let fileManager = FileManager.default

        var searchDirs = ColorProfileConstants.defaultSearchDirectories.map { URL(fileURLWithPath: $0) }
        let userDir = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(ColorProfileConstants.userColorSyncSubpath)
        searchDirs.append(userDir)

        var seenNames = Set<String>()

        for dir in searchDirs {
            guard let enumerator = fileManager.enumerator(
                at: dir,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            ) else { continue }

            while let url = enumerator.nextObject() as? URL {
                let ext = url.pathExtension.lowercased()
                guard ext == ColorProfileConstants.iccExtension || ext == ColorProfileConstants.icmExtension else {
                    continue
                }

                // Verify profile header: must be display monitor profile (class == "mntr") and RGB color space ("RGB ")
                guard let handle = try? FileHandle(forReadingFrom: url) else { continue }
                defer { try? handle.close() }
                let headerData = handle.readData(ofLength: 128)
                guard headerData.count >= 20 else { continue }

                let devClass = String(decoding: headerData[12..<16], as: UTF8.self).trimmingCharacters(in: .whitespaces)
                let colorSpace = String(decoding: headerData[16..<20], as: UTF8.self).trimmingCharacters(in: .whitespaces)

                // Only allow monitor RGB profiles; printer (CMYK), abstract (Lab), and grayscale profiles cause SkyLight assertion crashes
                guard devClass == "mntr" && colorSpace == "RGB" else { continue }

                // Hide orphaned per-display profiles (dead monitors, torn-down virtual screens)
                let isPerDisplay = ICCProfileFilter.isPerDisplayProfile(directoryName: url.deletingLastPathComponent().lastPathComponent)
                guard ICCProfileFilter.shouldInclude(
                    fileName: url.lastPathComponent,
                    isPerDisplayProfile: isPerDisplay,
                    onlineDisplayUUIDs: onlineUUIDs
                ) else { continue }

                // One entry per name: identical display names across directories are ambiguous in UI
                let name = url.deletingPathExtension().lastPathComponent
                guard !seenNames.contains(name) else { continue }

                seenNames.insert(name)
                profiles.append(ICCProfileInfo(name: name, path: url))
            }
        }

        return profiles.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// ColorSync UUIDs of every currently-online display
    public static func onlineDisplayUUIDs() -> Set<String> {
        var uuids = Set<String>()
        for id in DisplayInventory.onlineDisplayIDs() {
            guard let rawUUID = CGDisplayCreateUUIDFromDisplayID(id) else { continue }
            let cfUUID = rawUUID.takeRetainedValue()
            if let string = CFUUIDCreateString(kCFAllocatorDefault, cfUUID) {
                uuids.insert(string as String)
            }
        }
        return uuids
    }

    /// Apply ICC profile to target display using ColorSync
    public func setProfile(_ profile: ICCProfileInfo?, for displayID: CGDirectDisplayID) -> Bool {
        guard let rawUUID = CGDisplayCreateUUIDFromDisplayID(displayID) else { return false }
        let uuid = rawUUID.takeRetainedValue()

        guard let deviceClass = kColorSyncDisplayDeviceClass?.takeUnretainedValue(),
              let profileIDKey = kColorSyncDeviceDefaultProfileID?.takeUnretainedValue() else {
            return false
        }

        if let profile = profile {
            // Check if profile file exists
            guard FileManager.default.fileExists(atPath: profile.path.path) else { return false }
            let profileDict: NSDictionary = [profileIDKey: profile.path as NSURL]
            return ColorSyncDeviceSetCustomProfiles(deviceClass, uuid, profileDict as CFDictionary)
        } else {
            // Restore factory/default profile
            let resetDict: NSDictionary = [profileIDKey: kCFNull as Any]
            return ColorSyncDeviceSetCustomProfiles(deviceClass, uuid, resetDict as CFDictionary)
        }
    }
}
#endif
