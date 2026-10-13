import Foundation
import Combine

/// Unrestricted feature state engine: All features are natively unlocked without DRM or licensing gating
public final class AppFeatureManager: ObservableObject, @unchecked Sendable {
    public static let shared = AppFeatureManager()

    // 100% permanently unlocked features
    @Published public private(set) var isProUnlocked: Bool = true
    @Published public private(set) var isCustomResolutionEnabled: Bool = true
    @Published public private(set) var isXDROverdriveEnabled: Bool = true
    @Published public private(set) var isPipStreamingEnabled: Bool = true
    @Published public private(set) var isDDCControlEnabled: Bool = true
    @Published public private(set) var isDisplayGroupsEnabled: Bool = true
    @Published public private(set) var isForceRGBEnabled: Bool = true

    private init() {
        // Zero licensing checks, zero expiration timers
    }
}
