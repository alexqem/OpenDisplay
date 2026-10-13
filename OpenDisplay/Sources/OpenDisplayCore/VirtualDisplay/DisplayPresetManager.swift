import Foundation

/// Per-display settings entry in a preset snapshot
public struct DisplayPresetEntry: Codable, Equatable, Sendable {
    public let displayUUID: String
    public let width: Int
    public let height: Int
    public let isHiDPI: Bool
    public let brightness: Double?
    public let arrangementX: Int32?
    public let arrangementY: Int32?

    public init(
        displayUUID: String,
        width: Int,
        height: Int,
        isHiDPI: Bool,
        brightness: Double? = nil,
        arrangementX: Int32? = nil,
        arrangementY: Int32? = nil
    ) {
        self.displayUUID = displayUUID
        self.width = width
        self.height = height
        self.isHiDPI = isHiDPI
        self.brightness = brightness
        self.arrangementX = arrangementX
        self.arrangementY = arrangementY
    }
}

/// Named collection of display settings for one-click setup restoration
public struct DisplayPreset: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let name: String
    public let icon: String
    public let isBuiltin: Bool
    public let displays: [DisplayPresetEntry]

    public init(
        id: UUID = UUID(),
        name: String,
        icon: String = PresetConstants.defaultIconName,
        isBuiltin: Bool = false,
        displays: [DisplayPresetEntry]
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.isBuiltin = isBuiltin
        self.displays = displays
    }
}

/// In-memory preset manager and JSON serializer/deserializer (100% testable without disk/hardware)
public final class DisplayPresetManager: @unchecked Sendable {
    private var presets: [DisplayPreset] = []
    private let lock = NSLock()

    public init(initialPresets: [DisplayPreset] = []) {
        self.presets = initialPresets
    }

    public func getAllPresets() -> [DisplayPreset] {
        lock.lock()
        defer { lock.unlock() }
        return presets
    }

    public func addPreset(_ preset: DisplayPreset) {
        lock.lock()
        defer { lock.unlock() }
        presets.append(preset)
    }

    public func removePreset(id: UUID) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard let index = presets.firstIndex(where: { $0.id == id && !$0.isBuiltin }) else {
            return false
        }
        presets.remove(at: index)
        return true
    }

    /// Pure JSON encoding of non-builtin presets
    public func exportUserPresetsJSON() -> Data? {
        lock.lock()
        defer { lock.unlock() }
        let userPresets = presets.filter { !$0.isBuiltin }

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try? encoder.encode(userPresets)
    }

    /// Pure JSON decoding and merging into presets
    public func importUserPresets(from data: Data) -> Bool {
        let decoder = JSONDecoder()
        guard let decoded = try? decoder.decode([DisplayPreset].self, from: data) else {
            return false
        }

        lock.lock()
        defer { lock.unlock() }
        // Keep built-ins, append imported user presets
        let builtins = presets.filter { $0.isBuiltin }
        presets = builtins + decoded.filter { !$0.isBuiltin }
        return true
    }
}
