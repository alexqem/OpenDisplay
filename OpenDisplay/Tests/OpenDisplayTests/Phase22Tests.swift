import XCTest
@testable import OpenDisplayCore

final class Phase22Tests: XCTestCase {

    // MARK: - Cast Display Detection (AirPlay / BetterDisplay parity)

    func testCastDetectionByVendorAndModel() {
        // Live-verified identifiers of the AirPlay destination (aapl / airp)
        XCTAssertTrue(CastDisplayMatcher.isCastDisplay(
            vendorID: 0x6161_706C, modelID: 0x6169_7270, localizedName: nil
        ))
    }

    func testCastDetectionByNameSuffix() {
        XCTAssertTrue(CastDisplayMatcher.isCastDisplay(
            vendorID: 0x610, modelID: 0xa04e, localizedName: "AppleTV (AirPlay)"
        ))
        XCTAssertTrue(CastDisplayMatcher.isCastDisplay(
            vendorID: 0, modelID: 0, localizedName: "Kitchen TV (AirPlay)"
        ))
    }

    func testNonCastDisplaysAreNotMatched() {
        XCTAssertFalse(CastDisplayMatcher.isCastDisplay(
            vendorID: 0x610, modelID: 0xa04e, localizedName: "Color LCD"
        ))
        XCTAssertFalse(CastDisplayMatcher.isCastDisplay(
            vendorID: 0x6161_706C, modelID: 0xa04e, localizedName: "Dell U2723QE"
        ))
        XCTAssertFalse(CastDisplayMatcher.isCastDisplay(
            vendorID: 0, modelID: 0, localizedName: nil
        ))
    }

    func testAirPlayNameFallbackConstant() {
        XCTAssertEqual(CastDisplayMatcher.airPlayNameSuffix, "(AirPlay)")
        XCTAssertEqual(CastDisplayMatcher.airPlayNameFallback, "AirPlay Display")
        XCTAssertEqual(CastDisplayMatcher.mirroredNameFallback, "Mirrored Display")
    }

    // MARK: - HiDPI Toggle Mode Selection (cast-like AirPlay mode table)

    /// Mirrors the live SkyLight table of an AirPlay display (native 1920x1080)
    private func castLikeModes() -> [DisplayResolutionDescriptor] {
        return [
            ResolutionClassifier.classify(modeNumber: 0, pixelWidth: 800, pixelHeight: 600, pointWidth: 800, pointHeight: 600, refreshRate: 30, nativePixelWidth: 1920, nativePixelHeight: 1080, isCurrent: false),
            ResolutionClassifier.classify(modeNumber: 1, pixelWidth: 960, pixelHeight: 540, pointWidth: 960, pointHeight: 540, refreshRate: 30, nativePixelWidth: 1920, nativePixelHeight: 1080, isCurrent: false),
            ResolutionClassifier.classify(modeNumber: 2, pixelWidth: 1280, pixelHeight: 720, pointWidth: 1280, pointHeight: 720, refreshRate: 30, nativePixelWidth: 1920, nativePixelHeight: 1080, isCurrent: false),
            ResolutionClassifier.classify(modeNumber: 3, pixelWidth: 1920, pixelHeight: 1080, pointWidth: 1920, pointHeight: 1080, refreshRate: 30, nativePixelWidth: 1920, nativePixelHeight: 1080, isCurrent: true),
            ResolutionClassifier.classify(modeNumber: 4, pixelWidth: 1280, pixelHeight: 720, pointWidth: 640, pointHeight: 360, refreshRate: 30, nativePixelWidth: 1920, nativePixelHeight: 1080, isCurrent: false),
            ResolutionClassifier.classify(modeNumber: 5, pixelWidth: 1920, pixelHeight: 1080, pointWidth: 960, pointHeight: 540, refreshRate: 30, nativePixelWidth: 1920, nativePixelHeight: 1080, isCurrent: false)
        ]
    }

    func testBestHiDPIModePicksLargestBuffer() {
        // BetterDisplay "Hi Resolution": native-halved 960x540@2x (1080p stream) wins
        let best = ResolutionClassifier.bestHiDPIMode(in: castLikeModes())
        XCTAssertEqual(best?.modeNumber, 5)
        XCTAssertEqual(best?.pointWidth, 960)
        XCTAssertEqual(best?.pixelWidth, 1920)
        XCTAssertTrue(best?.isHiDPI ?? false)
    }

    func testBestHiDPIModeEmptyForLoDPIOnlyTable() {
        let loDPIOnly = castLikeModes().filter { !$0.isHiDPI }
        XCTAssertNil(ResolutionClassifier.bestHiDPIMode(in: loDPIOnly))
    }

    func testBestLoDPIModeRestoresSamePoints() {
        let modes = castLikeModes()
        let hidpi = modes.first { $0.modeNumber == 5 }!
        let restored = ResolutionClassifier.bestLoDPIMode(current: hidpi, in: modes)
        // 960x540 points at 1x exists (mode 1) -> same desktop size, no HiDPI
        XCTAssertEqual(restored?.modeNumber, 1)
        XCTAssertEqual(restored?.pointWidth, 960)
        XCTAssertFalse(restored?.isHiDPI ?? true)
    }

    func testBestLoDPIModeFallbackWhenPointsMissing() {
        let modes = castLikeModes().filter { $0.modeNumber != 1 }
        let hidpi = ResolutionClassifier.bestHiDPIMode(in: modes)!
        let restored = ResolutionClassifier.bestLoDPIMode(current: hidpi, in: modes)
        // No 960x540@1x -> falls back to largest 1x buffer (1920x1080, mode 3)
        XCTAssertEqual(restored?.modeNumber, 3)
        XCTAssertFalse(restored?.isHiDPI ?? true)
    }

    // MARK: - Ultra Sharp Cast Controller (pure state + tier metadata)

    func testSharpnessTierMetadata() {
        XCTAssertEqual(CastVirtualResolutionController.SharpnessTier.quadHD.pixelWidth, 2560)
        XCTAssertEqual(CastVirtualResolutionController.SharpnessTier.quadHD.pixelHeight, 1440)
        XCTAssertEqual(CastVirtualResolutionController.SharpnessTier.quadHD.refreshRate, 60.0)
        XCTAssertEqual(CastVirtualResolutionController.SharpnessTier.ultraHD.pixelWidth, 3840)
        XCTAssertEqual(CastVirtualResolutionController.SharpnessTier.ultraHD.pixelHeight, 2160)
        XCTAssertEqual(CastVirtualResolutionController.SharpnessTier.ultraHD.refreshRate, 30.0)
        XCTAssertEqual(CastVirtualResolutionController.SharpnessTier.allCases.count, 2)
    }

    func testControllerStartsDisengaged() {
        let controller = CastVirtualResolutionController.shared
        XCTAssertFalse(controller.isActive(for: 12))
        XCTAssertFalse(controller.isActive(for: 0))
        // Orphaned teardown with no engagement must be a safe no-op
        controller.teardownIfOrphaned(onlineCastIDs: [])
        XCTAssertFalse(controller.isActive(for: 12))
    }

    func testDisableWithoutEnableIsSafeNoOp() {
        XCTAssertFalse(CastVirtualResolutionController.shared.disable())
    }

    // MARK: - DisplayItemModel Cast Flag

    func testDisplayItemModelCarriesCastFlag() {
        let cast = DisplayItemModel(id: 12, name: "AppleTV (AirPlay)", isCast: true)
        XCTAssertTrue(cast.isCast)
        XCTAssertFalse(cast.isBuiltin)
        XCTAssertFalse(cast.isVirtual)

        let regular = DisplayItemModel(id: 1, name: "Color LCD")
        XCTAssertFalse(regular.isCast)
    }

    // MARK: - ICC Profile Litter Filter

    func testDisplayUUIDParsingFromProfileNames() {
        XCTAssertEqual(
            ICCProfileFilter.displayUUID(fromProfileFileName: "Color LCD-37D8832A-2D66-02CA-B9F7-8F30A301B230.icc"),
            "37D8832A-2D66-02CA-B9F7-8F30A301B230"
        )
        XCTAssertEqual(
            ICCProfileFilter.displayUUID(fromProfileFileName: "OpenDisplay-CastSharp-54107A8A-0104-4EC7-AE91-458724B9B194.icc"),
            "54107A8A-0104-4EC7-AE91-458724B9B194"
        )
        // Factory profiles carry no UUID tail
        XCTAssertNil(ICCProfileFilter.displayUUID(fromProfileFileName: "Display P3.icc"))
        XCTAssertNil(ICCProfileFilter.displayUUID(fromProfileFileName: "sRGB Profile.icc"))
    }

    func testIsPerDisplayProfileDirectory() {
        XCTAssertTrue(ICCProfileFilter.isPerDisplayProfile(directoryName: "Displays"))
        XCTAssertFalse(ICCProfileFilter.isPerDisplayProfile(directoryName: "Profiles"))
        XCTAssertFalse(ICCProfileFilter.isPerDisplayProfile(directoryName: "ColorSync"))
    }

    func testPerDisplayProfileFiltering() {
        let online: Set<String> = ["37D8832A-2D66-02CA-B9F7-8F30A301B230"]
        // Online display profile stays
        XCTAssertTrue(ICCProfileFilter.shouldInclude(
            fileName: "Color LCD-37D8832A-2D66-02CA-B9F7-8F30A301B230.icc",
            isPerDisplayProfile: true,
            onlineDisplayUUIDs: online
        ))
        // Orphaned virtual-screen litter (dead MatrixTest / CastSharp displays) is hidden
        XCTAssertFalse(ICCProfileFilter.shouldInclude(
            fileName: "MatrixTest0-E99BCEFC-E53F-4550-B27F-79D616143B17.icc",
            isPerDisplayProfile: true,
            onlineDisplayUUIDs: online
        ))
        XCTAssertFalse(ICCProfileFilter.shouldInclude(
            fileName: "OpenDisplay-CastSharp-54107A8A-0104-4EC7-AE91-458724B9B194.icc",
            isPerDisplayProfile: true,
            onlineDisplayUUIDs: online
        ))
        // Factory profiles always pass
        XCTAssertTrue(ICCProfileFilter.shouldInclude(
            fileName: "Display P3.icc",
            isPerDisplayProfile: false,
            onlineDisplayUUIDs: []
        ))
        // Per-display file with unparseable UUID is hidden
        XCTAssertFalse(ICCProfileFilter.shouldInclude(
            fileName: "weird-thing.icc",
            isPerDisplayProfile: true,
            onlineDisplayUUIDs: online
        ))
    }

    // MARK: - Resolution Deduplication

    func testDeduplicatedResolutionsRemovesRefreshRateDuplicates() {
        let m120 = DisplayResolutionDescriptor(
            modeNumber: 0, pixelWidth: 3024, pixelHeight: 1964,
            pointWidth: 1512, pointHeight: 982, refreshRate: 120.0,
            isCurrent: false, isNative: false, isRecommended: true,
            tier: .recommendedHiDPI, aspectRatioString: "16:10"
        )
        let m60 = DisplayResolutionDescriptor(
            modeNumber: 1, pixelWidth: 3024, pixelHeight: 1964,
            pointWidth: 1512, pointHeight: 982, refreshRate: 60.0,
            isCurrent: true, isNative: false, isRecommended: true,
            tier: .recommendedHiDPI, aspectRatioString: "16:10"
        )
        let m59 = DisplayResolutionDescriptor(
            modeNumber: 2, pixelWidth: 3024, pixelHeight: 1964,
            pointWidth: 1512, pointHeight: 982, refreshRate: 59.0,
            isCurrent: false, isNative: false, isRecommended: true,
            tier: .recommendedHiDPI, aspectRatioString: "16:10"
        )
        let other = DisplayResolutionDescriptor(
            modeNumber: 3, pixelWidth: 1920, pixelHeight: 1080,
            pointWidth: 1920, pointHeight: 1080, refreshRate: 60.0,
            isCurrent: false, isNative: false, isRecommended: false,
            tier: .standard1x, aspectRatioString: "16:9"
        )

        let unique = ResolutionClassifier.deduplicatedResolutions(from: [m120, m60, m59, other])
        XCTAssertEqual(unique.count, 2)
        // Must preserve the current mode (m60) for 1512x982
        let matched = unique.first(where: { $0.pointWidth == 1512 && $0.pointHeight == 982 })
        XCTAssertEqual(matched?.modeNumber, 1)
        XCTAssertEqual(matched?.refreshRate, 60.0)
    }

    // MARK: - Standard Resolution Filtering & Adaptive Height

    func testStandardResolutionThreshold() {
        let lowRes = DisplayResolutionDescriptor(
            modeNumber: 10, pixelWidth: 640, pixelHeight: 480,
            pointWidth: 640, pointHeight: 480, refreshRate: 60.0,
            isCurrent: false, isNative: false, isRecommended: false,
            tier: .standard1x, aspectRatioString: "4:3"
        )
        let standard = DisplayResolutionDescriptor(
            modeNumber: 11, pixelWidth: 1920, pixelHeight: 1080,
            pointWidth: 1920, pointHeight: 1080, refreshRate: 60.0,
            isCurrent: false, isNative: false, isRecommended: false,
            tier: .standard1x, aspectRatioString: "16:9"
        )
        let currentLowRes = DisplayResolutionDescriptor(
            modeNumber: 12, pixelWidth: 640, pixelHeight: 480,
            pointWidth: 640, pointHeight: 480, refreshRate: 60.0,
            isCurrent: true, isNative: false, isRecommended: false,
            tier: .standard1x, aspectRatioString: "4:3"
        )

        XCTAssertFalse(ResolutionClassifier.isStandardResolution(lowRes))
        XCTAssertTrue(ResolutionClassifier.isStandardResolution(standard))
        // If user is currently running low res, it must not be hidden
        XCTAssertTrue(ResolutionClassifier.isStandardResolution(currentLowRes))
    }

    func testAdaptivePopoverHeightNeverExceedsDefault() {
        let height = AtlasTheme.adaptivePopoverHeight()
        XCTAssertLessThanOrEqual(height, AtlasTheme.popoverHeight)
        XCTAssertGreaterThanOrEqual(height, AtlasTheme.adaptivePopoverMinHeight)
    }

    func testFormatRefreshRateSharedUtility() {
        XCTAssertEqual(ResolutionClassifier.formatRefreshRate(120.0, isBuiltin: true), "120Hz (ProMotion)")
        XCTAssertEqual(ResolutionClassifier.formatRefreshRate(120.0, isBuiltin: false), "120Hz")
        XCTAssertEqual(ResolutionClassifier.formatRefreshRate(60.0), "60Hz")
        XCTAssertEqual(ResolutionClassifier.formatRefreshRate(59.94), "59.94Hz")
    }
}
