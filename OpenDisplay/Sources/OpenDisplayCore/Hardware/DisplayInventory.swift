#if os(macOS) && arch(arm64)
import AppKit
import CoreGraphics

/// Immutable snapshot descriptor of one connected display as exposed by AppKit/CoreGraphics
public struct DisplayInventoryInfo: Identifiable, Equatable, Sendable {
    public let id: CGDirectDisplayID
    public let name: String
    public let isBuiltin: Bool
    public let isHiDPI: Bool
    public let pixelWidth: Int
    public let pixelHeight: Int

    public init(
        id: CGDirectDisplayID,
        name: String,
        isBuiltin: Bool,
        isHiDPI: Bool,
        pixelWidth: Int,
        pixelHeight: Int
    ) {
        self.id = id
        self.name = name
        self.isBuiltin = isBuiltin
        self.isHiDPI = isHiDPI
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
    }
}

/// Live display enumeration service bridging NSScreen identities and CoreGraphics display IDs
public enum DisplayInventory {

    /// Enumerate currently attached displays in stable system order
    public static func currentDisplays() -> [DisplayInventoryInfo] {
        return NSScreen.screens.compactMap { screen in
            guard let rawID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else {
                return nil
            }
            let pixelWidth = CGDisplayPixelsWide(rawID)
            let pointWidth = Int(screen.frame.width)
            return DisplayInventoryInfo(
                id: rawID,
                name: screen.localizedName,
                isBuiltin: CGDisplayIsBuiltin(rawID) != 0,
                isHiDPI: DisplayPresetManager.isHiDPIMode(pixelWidth: pixelWidth, pointWidth: pointWidth),
                pixelWidth: pixelWidth,
                pixelHeight: CGDisplayPixelsHigh(rawID)
            )
        }
    }

    /// Probe and parse hardware capabilities (HDMI VSDB, YCbCr, HDR, Deep Color) for a display
    public static func probeCapabilities(for displayID: CGDirectDisplayID) -> DisplayCapabilities {
        if CGDisplayIsBuiltin(displayID) != 0 {
            return DisplayCapabilities(
                isHDMI: false,
                supportsYCbCr444: false,
                supportsYCbCr422: false,
                supportsBasicAudio: true,
                supportsUnderscan: false,
                supports10BitDeepColor: ColorDepthController.shared.is10BitColorActive(displayID: displayID),
                supportsHDR: ColorDepthController.shared.supportsHDR(displayID: displayID),
                supportsDDC: false
            )
        }

        guard let service = IOAVServiceMatcher.service(for: displayID) else {
            return DisplayCapabilities.fallback
        }

        var caps = DisplayCapabilities.fallback
        if let edidBytes = IOAVServiceMatcher.extractEDIDBytes(for: service),
           let parsed = EDIDParser.parse(bytes: edidBytes) {
            caps = parsed.capabilities
        }

        // Augment parsed capabilities with live SkyLight / ColorDepth queries
        let is10Bit = ColorDepthController.shared.is10BitColorActive(displayID: displayID)
        let supportsHDR = ColorDepthController.shared.supportsHDR(displayID: displayID)
        let hasDDC = IOAVServiceDDC(service: service) != nil

        return caps.augmented(
            supports10BitDeepColor: is10Bit || caps.supports10BitDeepColor,
            supportsHDR: supportsHDR || caps.supportsHDR,
            supportsDDC: hasDDC
        )
    }

    /// Stable CoreGraphics UUID string for a display (preset persistence identity)
    public static func uuidString(for displayID: CGDirectDisplayID) -> String? {
        guard let rawUUID = CGDisplayCreateUUIDFromDisplayID(displayID) else { return nil }
        let uuid = rawUUID.takeRetainedValue()
        return CFUUIDCreateString(kCFAllocatorDefault, uuid) as String?
    }

    /// Resolve a persisted UUID string back to the active display ID
    public static func displayID(forUUIDString uuid: String) -> CGDirectDisplayID? {
        guard let cfUUID = CFUUIDCreateFromString(kCFAllocatorDefault, uuid as CFString) else { return nil }
        let resolved = CGDisplayGetDisplayIDFromUUID(cfUUID)
        return resolved == kCGNullDirectDisplay ? nil : resolved
    }
}
#endif
