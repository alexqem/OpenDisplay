#if os(macOS) && arch(arm64)
import AppKit
import CoreGraphics

/// Immutable snapshot descriptor of one connected display as exposed by AppKit/CoreGraphics
public struct DisplayInventoryInfo: Identifiable, Equatable, Sendable {
    public let id: CGDirectDisplayID
    public let name: String
    public let isBuiltin: Bool
    public let isCast: Bool
    public let isHiDPI: Bool
    public let pixelWidth: Int
    public let pixelHeight: Int

    public init(
        id: CGDirectDisplayID,
        name: String,
        isBuiltin: Bool,
        isCast: Bool = false,
        isHiDPI: Bool,
        pixelWidth: Int,
        pixelHeight: Int
    ) {
        self.id = id
        self.name = name
        self.isBuiltin = isBuiltin
        self.isCast = isCast
        self.isHiDPI = isHiDPI
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
    }
}

/// Classification helpers for AirPlay / cast destinations (BetterDisplay parity via kCGDisplayIsAirPlay semantics)
public enum CastDisplayMatcher {
    /// Apple ("aapl") vendor identifier reported by CoreGraphics for AirPlay displays
    public static let appleCastVendorID: UInt32 = 0x6161_706C
    /// "airp" model identifier reported by CoreGraphics for AirPlay displays
    public static let airPlayModelID: UInt32 = 0x6169_7270
    /// NSScreen localizedName suffix macOS appends to AirPlay destinations
    public static let airPlayNameSuffix = "(AirPlay)"
    /// Display name used when a cast display is not exposed through NSScreen (mirrored slave)
    public static let airPlayNameFallback = "AirPlay Display"
    /// Display name used when a non-cast display is hidden inside a mirror group
    public static let mirroredNameFallback = "Mirrored Display"

    /// Pure predicate: display represents an AirPlay / cast destination
    public static func isCastDisplay(
        vendorID: UInt32,
        modelID: UInt32,
        localizedName: String?
    ) -> Bool {
        if vendorID == appleCastVendorID && modelID == airPlayModelID {
            return true
        }
        if let name = localizedName, name.hasSuffix(airPlayNameSuffix) {
            return true
        }
        return false
    }
}

/// Live display enumeration service bridging NSScreen identities and CoreGraphics display IDs
public enum DisplayInventory {

    /// Fetch all online CGDirectDisplayIDs via CoreGraphics
    public static func onlineDisplayIDs() -> [CGDirectDisplayID] {
        var count: UInt32 = 0
        CGGetOnlineDisplayList(0, nil, &count)
        guard count > 0 else { return [] }
        var ids = [CGDirectDisplayID](repeating: 0, count: Int(count))
        CGGetOnlineDisplayList(count, &ids, &count)
        return Array(ids.prefix(Int(count)))
    }

    /// Enumerate currently attached displays in stable system order
    public static func currentDisplays() -> [DisplayInventoryInfo] {
        var results: [DisplayInventoryInfo] = []
        var seenIDs = Set<CGDirectDisplayID>()
        for screen in NSScreen.screens {
            guard let rawID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else {
                continue
            }
            let pixelWidth = CGDisplayPixelsWide(rawID)
            let pointWidth = Int(screen.frame.width)
            let info = DisplayInventoryInfo(
                id: rawID,
                name: screen.localizedName,
                isBuiltin: CGDisplayIsBuiltin(rawID) != 0,
                isCast: CastDisplayMatcher.isCastDisplay(
                    vendorID: CGDisplayVendorNumber(rawID),
                    modelID: CGDisplayModelNumber(rawID),
                    localizedName: screen.localizedName
                ),
                isHiDPI: DisplayPresetManager.isHiDPIMode(pixelWidth: pixelWidth, pointWidth: pointWidth),
                pixelWidth: pixelWidth,
                pixelHeight: CGDisplayPixelsHigh(rawID)
            )
            results.append(info)
            seenIDs.insert(rawID)
        }

        // Supplementary pass: hardware-mirrored displays are collapsed out of
        // NSScreen.screens (only the mirror master is exposed). Pick the rest up
        // from the online display list so cast destinations and the built-in panel
        // remain visible while a mirror group is active (BetterDisplay parity).
        for id in onlineDisplayIDs() where !seenIDs.contains(id) {
            let vendor = CGDisplayVendorNumber(id)
            let model = CGDisplayModelNumber(id)
            let isCast = CastDisplayMatcher.isCastDisplay(vendorID: vendor, modelID: model, localizedName: nil)
            let pixelWidth = CGDisplayPixelsWide(id)
            results.append(
                DisplayInventoryInfo(
                    id: id,
                    name: isCast ? CastDisplayMatcher.airPlayNameFallback : CastDisplayMatcher.mirroredNameFallback,
                    isBuiltin: CGDisplayIsBuiltin(id) != 0,
                    isCast: isCast,
                    isHiDPI: false,
                    pixelWidth: pixelWidth,
                    pixelHeight: CGDisplayPixelsHigh(id)
                )
            )
        }
        return results
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
