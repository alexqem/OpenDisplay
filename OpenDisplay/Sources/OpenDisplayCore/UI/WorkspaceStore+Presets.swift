#if os(macOS) && arch(arm64)
import AppKit
import CoreGraphics

// MARK: - WorkspaceStore Presets & Serialization Extension (SRP)
extension WorkspaceStore {

    public func reloadPresets() {
        presets = DisplayPresetManager.shared.getAllPresets()
    }

    public func applyPreset(_ preset: DisplayPreset) {
        dispatcher.applyPreset(preset)
        refresh()
    }

    public func saveCurrentStateAsPreset(named name: String) {
        let entries = displays.compactMap { model -> DisplayPresetEntry? in
            guard let uuid = DisplayInventory.uuidString(for: model.id) else { return nil }
            let bounds = CGDisplayBounds(model.id)
            return DisplayPresetEntry(
                displayUUID: uuid,
                width: model.pixelWidth,
                height: model.pixelHeight,
                isHiDPI: model.isHiDPI,
                brightness: model.brightness,
                arrangementX: Int32(bounds.origin.x),
                arrangementY: Int32(bounds.origin.y)
            )
        }
        guard !entries.isEmpty else { return }
        DisplayPresetManager.shared.addPreset(DisplayPreset(name: name, displays: entries))
        reloadPresets()
    }

    public func deletePreset(_ preset: DisplayPreset) {
        _ = DisplayPresetManager.shared.removePreset(id: preset.id)
        reloadPresets()
    }

    public func importPresets() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.json]
        guard panel.runModal() == .OK, let url = panel.url, let data = try? Data(contentsOf: url) else { return }
        _ = DisplayPresetManager.shared.importUserPresets(from: data)
        reloadPresets()
    }

    public func exportPresets() {
        guard let data = DisplayPresetManager.shared.exportUserPresetsJSON() else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "OpenDisplayPresets"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        try? data.write(to: url)
    }
}
#endif
