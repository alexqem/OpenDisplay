#if os(macOS) && arch(arm64)
import Foundation

/// Bridge to CoreBrightness private framework for Night Shift and True Tone control
public final class NightShiftTrueToneBridge: @unchecked Sendable {
    private let blueLightClient: AnyObject?
    private let trueToneClient: AnyObject?

    public static let shared = NightShiftTrueToneBridge()

    private init() {
        if let blueLightClass = DynamicObjCClass.resolve("CBBlueLightClient") as? NSObject.Type {
            self.blueLightClient = blueLightClass.init()
        } else {
            self.blueLightClient = nil
        }

        if let trueToneClass = DynamicObjCClass.resolve("CBTrueToneClient") as? NSObject.Type {
            self.trueToneClient = trueToneClass.init()
        } else {
            self.trueToneClient = nil
        }
    }

    // MARK: - Night Shift
    public func setNightShift(enabled: Bool) throws {
        guard let client = blueLightClient else {
            throw LuminanceError.coreBrightnessClientUnavailable
        }
        let sel = Selector(("setEnabled:"))
        guard (client as AnyObject).responds(to: sel) else {
            throw LuminanceError.operationFailed(reason: "CBBlueLightClient does not respond to setEnabled:")
        }
        _ = (client as AnyObject).perform(sel, with: enabled)
    }

    public func setNightShiftStrength(_ strength: Float) throws {
        guard let client = blueLightClient else {
            throw LuminanceError.coreBrightnessClientUnavailable
        }
        let sel = Selector(("setStrength:commit:"))
        guard (client as AnyObject).responds(to: sel) else {
            throw LuminanceError.operationFailed(reason: "CBBlueLightClient does not respond to setStrength:commit:")
        }

        typealias SetStrengthFunc = @convention(c) (AnyObject, Selector, Float, Bool) -> Bool
        let imp = (client as AnyObject).method(for: sel)
        let fn = unsafeBitCast(imp, to: SetStrengthFunc.self)
        let clamped = max(0.0, min(1.0, strength))
        _ = fn(client, sel, clamped, true)
    }

    // MARK: - True Tone
    public var isTrueToneSupported: Bool {
        guard let client = trueToneClient else { return false }
        let sel = Selector(("supported"))
        guard (client as AnyObject).responds(to: sel) else { return false }
        typealias QueryFunc = @convention(c) (AnyObject, Selector) -> Bool
        let imp = (client as AnyObject).method(for: sel)
        let fn = unsafeBitCast(imp, to: QueryFunc.self)
        return fn(client, sel)
    }

    public func setTrueTone(enabled: Bool) throws {
        guard let client = trueToneClient else {
            throw LuminanceError.coreBrightnessClientUnavailable
        }
        let sel = Selector(("setEnabled:"))
        guard (client as AnyObject).responds(to: sel) else {
            throw LuminanceError.operationFailed(reason: "CBTrueToneClient does not respond to setEnabled:")
        }
        _ = (client as AnyObject).perform(sel, with: enabled)
    }
}
#endif
