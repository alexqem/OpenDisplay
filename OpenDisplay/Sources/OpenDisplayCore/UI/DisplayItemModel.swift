#if os(macOS) && arch(arm64)
import SwiftUI
import CoreGraphics

/// Observable UI state model representing a single connected or virtual display
public final class DisplayItemModel: ObservableObject, Identifiable {
    public static let defaultBrightness: Double = 0.8
    public static let defaultVolume: Double = 0.5

    public let id: CGDirectDisplayID
    public let name: String
    public let isBuiltin: Bool
    public let isVirtual: Bool
    public let isHiDPI: Bool
    public let pixelWidth: Int
    public let pixelHeight: Int
    @Published public var brightness: Double
    @Published public var volume: Double
    @Published public var isMuted: Bool
    @Published public var isXDROverdriveEnabled: Bool
    @Published public var isForceRGBActive: Bool = true
    @Published public var is10BitActive: Bool
    @Published public var isHDREnabled: Bool
    @Published public var isNotchOverlayActive: Bool
    @Published public var hasPhysicalNotch: Bool
    @Published public var isMirrored: Bool
    @Published public var isDisconnected: Bool
    @Published public var rotation: DisplayRotationAngle = .standard
    @Published public var colorProfileName: String?
    @Published public var inputSource: DDCInputSource?
    @Published public var availableResolutions: [DisplayResolutionDescriptor] = [] {
        didSet {
            recommendedResolutions = availableResolutions.filter { $0.isRecommended }
            otherResolutions = availableResolutions.filter { !$0.isRecommended }
        }
    }
    @Published public private(set) var recommendedResolutions: [DisplayResolutionDescriptor] = []
    @Published public private(set) var otherResolutions: [DisplayResolutionDescriptor] = []
    @Published public var selectedResolutionId: String?
    @Published public var isAdvancedDrawerExpanded: Bool = false
    @Published public var volumeBeforeMute: Double?
    @Published public var capabilities: DisplayCapabilities = .fallback
    @Published public var syncGroupMasterID: CGDirectDisplayID?
    @Published public var isGroupMaster: Bool = false
    @Published public var syncBrightnessOffset: Double = 0.0

    @Published public var isEditingBrightness: Bool = false
    @Published public var brightnessInputText: String = ""
    @Published public var isGPUDitheringEnabled: Bool = true
    @Published public var appearancePreset: DisplayAppearancePreset = .standard
    @Published public var isColorModeExpanded: Bool = false

    public init(
        id: CGDirectDisplayID,
        name: String,
        brightness: Double = DisplayItemModel.defaultBrightness,
        volume: Double = DisplayItemModel.defaultVolume,
        isMuted: Bool = false,
        isXDROverdriveEnabled: Bool = false,
        isForceRGBActive: Bool = false,
        is10BitActive: Bool = false,
        isBuiltin: Bool = false,
        isVirtual: Bool = false,
        isHiDPI: Bool = false,
        pixelWidth: Int = 0,
        pixelHeight: Int = 0
    ) {
        self.id = id
        self.name = name
        self.brightness = brightness
        self.volume = volume
        self.isMuted = isMuted
        self.isXDROverdriveEnabled = isXDROverdriveEnabled
        self.isForceRGBActive = isForceRGBActive
        self.is10BitActive = is10BitActive
        self.isBuiltin = isBuiltin
        self.isVirtual = isVirtual
        self.isHiDPI = isHiDPI
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
        self.isHDREnabled = false
        self.isNotchOverlayActive = false
        self.hasPhysicalNotch = false
        self.isMirrored = false
        self.isDisconnected = false
        self.colorProfileName = nil
        self.volumeBeforeMute = nil
    }
}
#endif
