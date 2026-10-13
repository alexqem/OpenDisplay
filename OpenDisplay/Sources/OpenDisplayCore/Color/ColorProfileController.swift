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

#if os(macOS) && arch(arm64)
import CoreGraphics
@preconcurrency import ColorSync

/// Service managing display ICC color profiles via ColorSync
public final class ColorProfileController: @unchecked Sendable {
    public static let shared = ColorProfileController()

    private init() {}

    /// Enumerate all available ICC profiles from standard filesystem directories
    public func enumerateProfiles() -> [ICCProfileInfo] {
        var profiles: [ICCProfileInfo] = []
        let fileManager = FileManager.default

        var searchDirs = ColorProfileConstants.defaultSearchDirectories.map { URL(fileURLWithPath: $0) }
        let userDir = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(ColorProfileConstants.userColorSyncSubpath)
        searchDirs.append(userDir)

        var seenPaths = Set<URL>()

        for dir in searchDirs {
            guard let enumerator = fileManager.enumerator(
                at: dir,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            ) else { continue }

            while let url = enumerator.nextObject() as? URL {
                guard !seenPaths.contains(url) else { continue }
                let ext = url.pathExtension.lowercased()
                guard ext == ColorProfileConstants.iccExtension || ext == ColorProfileConstants.icmExtension else {
                    continue
                }
                seenPaths.insert(url)

                let name = url.deletingPathExtension().lastPathComponent
                profiles.append(ICCProfileInfo(name: name, path: url))
            }
        }

        return profiles.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// Apply ICC profile to target display using ColorSync
    public func setProfile(_ profile: ICCProfileInfo, for displayID: CGDirectDisplayID) -> Bool {
        guard let rawUUID = CGDisplayCreateUUIDFromDisplayID(displayID) else { return false }
        let uuid = rawUUID.takeRetainedValue()

        guard let deviceClass = kColorSyncDisplayDeviceClass?.takeUnretainedValue(),
              let profileIDKey = kColorSyncDeviceDefaultProfileID?.takeUnretainedValue() else {
            return false
        }

        let profileDict: NSDictionary = [profileIDKey: profile.path as NSURL]
        return ColorSyncDeviceSetCustomProfiles(deviceClass, uuid, profileDict as CFDictionary)
    }
}
#endif
