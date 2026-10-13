import XCTest
@testable import OpenDisplayCore

final class Phase8Tests: XCTestCase {

    func testAppFeatureManagerPermanentlyUnlocked() {
        let mgr = AppFeatureManager.shared
        XCTAssertTrue(mgr.isProUnlocked)
        XCTAssertTrue(mgr.isCustomResolutionEnabled)
        XCTAssertTrue(mgr.isXDROverdriveEnabled)
        XCTAssertTrue(mgr.isPipStreamingEnabled)
        XCTAssertTrue(mgr.isDDCControlEnabled)
        XCTAssertTrue(mgr.isDisplayGroupsEnabled)
        XCTAssertTrue(mgr.isForceRGBEnabled)
    }

    func testDisplayItemModelInitialization() {
        #if os(macOS) && arch(arm64)
        let item = DisplayItemModel(id: 101, name: "Studio Display", brightness: 0.9, volume: 0.7)
        XCTAssertEqual(item.id, 101)
        XCTAssertEqual(item.name, "Studio Display")
        XCTAssertEqual(item.brightness, 0.9)
        XCTAssertEqual(item.volume, 0.7)
        XCTAssertFalse(item.isMuted)

        item.brightness = 0.5
        XCTAssertEqual(item.brightness, 0.5)

        // Test AtlasTheme tokens and typography scale
        XCTAssertEqual(AtlasTheme.zeroRadius, 0.0)
        XCTAssertEqual(AtlasTheme.borderWidth, 1.0)
        XCTAssertEqual(AtlasTheme.popoverWidth, 400.0)
        XCTAssertEqual(AtlasTheme.maxScrollHeight, 400.0)
        XCTAssertEqual(AtlasTheme.pickerWidth, 120.0)
        XCTAssertEqual(AtlasTheme.fontHeadline, 16.0)
        XCTAssertEqual(AtlasTheme.fontCaptionSmall, 9.0)

        // Verify state mutation on DisplayItemModel triggers published update
        item.isForceRGBActive.toggle()
        XCTAssertTrue(item.isForceRGBActive)

        item.is10BitActive.toggle()
        XCTAssertTrue(item.is10BitActive)

        item.isXDROverdriveEnabled.toggle()
        XCTAssertTrue(item.isXDROverdriveEnabled)
        #endif
    }
}
