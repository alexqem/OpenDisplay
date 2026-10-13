import XCTest
@testable import OpenDisplayCore

final class Phase10Tests: XCTestCase {

    func testMirrorConstants() {
        XCTAssertEqual(MirrorConstants.nullDirectDisplay, 0)
    }

    func testPresetConstants() {
        XCTAssertEqual(PresetConstants.defaultIconName, "display")
    }

    func testDisplayPresetManagerExportAndImport() {
        let entry1 = DisplayPresetEntry(
            displayUUID: "UUID-TEST-001",
            width: 3840,
            height: 2160,
            isHiDPI: true,
            brightness: 0.85,
            arrangementX: 0,
            arrangementY: 0
        )
        let preset1 = DisplayPreset(
            name: "Work 4K Setup",
            icon: "display.2",
            isBuiltin: false,
            displays: [entry1]
        )

        let builtinPreset = DisplayPreset(
            name: "Default Native",
            icon: PresetConstants.defaultIconName,
            isBuiltin: true,
            displays: []
        )

        let manager = DisplayPresetManager(initialPresets: [builtinPreset, preset1])
        XCTAssertEqual(manager.getAllPresets().count, 2)

        // Export user presets to JSON data
        guard let jsonData = manager.exportUserPresetsJSON() else {
            XCTFail("Export to JSON failed")
            return
        }

        // New manager with only builtin
        let newManager = DisplayPresetManager(initialPresets: [builtinPreset])
        XCTAssertEqual(newManager.getAllPresets().count, 1)

        // Import
        let success = newManager.importUserPresets(from: jsonData)
        XCTAssertTrue(success)
        XCTAssertEqual(newManager.getAllPresets().count, 2)

        let imported = newManager.getAllPresets().first(where: { $0.name == "Work 4K Setup" })
        XCTAssertNotNil(imported)
        XCTAssertEqual(imported?.displays.first?.width, 3840)
        XCTAssertEqual(imported?.displays.first?.brightness, 0.85)

        // Test delete non-builtin preset
        let removed = newManager.removePreset(id: preset1.id)
        XCTAssertTrue(removed)
        XCTAssertEqual(newManager.getAllPresets().count, 1)

        // Built-in preset cannot be removed
        let removedBuiltin = newManager.removePreset(id: builtinPreset.id)
        XCTAssertFalse(removedBuiltin)
    }

    func testDisplayPresetManagerMalformedJSON() {
        let manager = DisplayPresetManager()
        let corruptedData = Data("invalid-json-content".utf8)
        let success = manager.importUserPresets(from: corruptedData)
        XCTAssertFalse(success)
    }

    func testDisplayPresetManagerIgnoreBuiltinsInImport() {
        // Prepare preset marked as isBuiltin: true in JSON payload
        let fakeBuiltin = DisplayPreset(
            name: "Hacked Builtin",
            icon: "gear",
            isBuiltin: true,
            displays: []
        )
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode([fakeBuiltin]) else {
            XCTFail("Failed to encode")
            return
        }

        let manager = DisplayPresetManager()
        let success = manager.importUserPresets(from: data)
        XCTAssertTrue(success)
        // Since isBuiltin is true, importUserPresets filters it out!
        XCTAssertEqual(manager.getAllPresets().count, 0)
    }
}
