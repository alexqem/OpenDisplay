import XCTest
@testable import OpenDisplayCore

final class Phase14Tests: XCTestCase {

    func testDisplayPresetSharedBuiltins() {
        let presets = DisplayPresetManager.shared.getAllPresets()
        XCTAssertTrue(presets.contains(where: { $0.name == "Default Native" && $0.isBuiltin }))
    }

    func testHiDPIModeDetection() {
        XCTAssertTrue(DisplayPresetManager.isHiDPIMode(pixelWidth: 2880, pointWidth: 1440))
        XCTAssertFalse(DisplayPresetManager.isHiDPIMode(pixelWidth: 1920, pointWidth: 1920))
        XCTAssertFalse(DisplayPresetManager.isHiDPIMode(pixelWidth: 3840, pointWidth: 0))
        XCTAssertFalse(DisplayPresetManager.isHiDPIMode(pixelWidth: 100, pointWidth: 200))
    }

    func testVirtualDisplayManagerEmptyQueries() {
        #if os(macOS) && arch(arm64)
        let manager = VirtualDisplayManager.shared
        XCTAssertFalse(manager.contains(displayID: 0))
        XCTAssertFalse(manager.remove(displayID: 0))
        let duplicateIDs = manager.allControllers().map { $0.displayID }
        XCTAssertEqual(duplicateIDs.count, Set(duplicateIDs).count)
        #endif
    }

    func testDisplayItemModelNewStatusDefaults() {
        #if os(macOS) && arch(arm64)
        let item = DisplayItemModel(id: 77, name: "External Test Panel")
        XCTAssertEqual(item.brightness, DisplayItemModel.defaultBrightness)
        XCTAssertEqual(item.volume, DisplayItemModel.defaultVolume)
        XCTAssertFalse(item.isBuiltin)
        XCTAssertFalse(item.isVirtual)
        XCTAssertFalse(item.isHiDPI)
        XCTAssertFalse(item.isHDREnabled)
        XCTAssertFalse(item.isMirrored)
        XCTAssertFalse(item.isDisconnected)
        XCTAssertNil(item.colorProfileName)
        XCTAssertNil(item.volumeBeforeMute)
        XCTAssertEqual(item.rotation, .standard)
        XCTAssertEqual(item.pixelWidth, 0)
        XCTAssertEqual(item.pixelHeight, 0)

        item.volumeBeforeMute = 0.4
        XCTAssertEqual(item.volumeBeforeMute, 0.4)
        #endif
    }

    func testVirtualDisplayChipIdentity() {
        #if os(macOS) && arch(arm64)
        let chip = VirtualDisplayChip(id: 42, name: "Virtual 16:9 60Hz")
        XCTAssertEqual(chip.id, 42)
        XCTAssertEqual(chip.name, "Virtual 16:9 60Hz")
        let copy = VirtualDisplayChip(id: 42, name: "Virtual 16:9 60Hz")
        XCTAssertEqual(chip, copy)
        #endif
    }

    func testAtlasThemeExtendedTokens() {
        #if os(macOS) && arch(arm64)
        XCTAssertEqual(AtlasTheme.popoverWidth, 420.0)
        XCTAssertEqual(AtlasTheme.popoverHeight, 660.0)
        XCTAssertEqual(AtlasTheme.maxScrollHeight, 520.0)
        XCTAssertEqual(AtlasTheme.pickerNarrowWidth, 72.0)
        XCTAssertEqual(AtlasTheme.sectionSpacing, 16.0)
        XCTAssertEqual(AtlasTheme.blueprintGridSpacing, 18.0)
        XCTAssertEqual(AtlasTheme.iconButtonSide, 22.0)
        XCTAssertEqual(AtlasTheme.pillCornerRadius, 9999.0)
        XCTAssertEqual(AtlasTheme.percentLabelWidth, 34.0)
        #endif
    }

    func testDDCVolumeAndMuteConstants() {
        XCTAssertEqual(DDCProtocolLimits.vcpPercentScale, 100)
        XCTAssertEqual(DDCProtocolLimits.audioMuteEngaged, 1)
        XCTAssertEqual(DDCProtocolLimits.audioMuteReleased, 2)
        XCTAssertTrue(DDCVcpCode.allCases.contains(.audioSpeakerVolume))
        XCTAssertTrue(DDCVcpCode.allCases.contains(.audioMute))
    }

    func testMediaKeyBrightnessStepAndDebounceConstants() {
        XCTAssertEqual(MediaKeyConstants.brightnessStep, 0.05)
        XCTAssertEqual(MediaKeyConstants.ddcDebounceNanoseconds, 50_000_000)
    }
}
