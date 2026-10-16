#if os(macOS) && arch(arm64)
import Foundation

/// Bridge to CoreBrightness private framework for Night Shift and True Tone control
public final class NightShiftTrueToneBridge: @unchecked Sendable {
    private let blueLightClient: AnyObject?
    private let trueToneClient: AnyObject?

    public static let shared = NightShiftTrueToneBridge()

    private init() {
        // CoreBrightness is a private framework; explicitly dlopen it if not loaded
        _ = dlopen("/System/Library/PrivateFrameworks/CoreBrightness.framework/CoreBrightness", RTLD_NOW)

        if let blueLightClass = DynamicObjCClass.resolve("CBBlueLightClient") {
            self.blueLightClient = (blueLightClass as AnyObject).perform(Selector(("new")))?.takeUnretainedValue()
        } else {
            self.blueLightClient = nil
        }

        if let trueToneClass = DynamicObjCClass.resolve("CBTrueToneClient") {
            self.trueToneClient = (trueToneClass as AnyObject).perform(Selector(("new")))?.takeUnretainedValue()
        } else {
            self.trueToneClient = nil
        }
    }

    // MARK: - Night Shift
    public func setNightShift(enabled: Bool) throws {
        guard let client = blueLightClient else {
            throw LuminanceError.coreBrightnessClientUnavailable
        }

        // On macOS Apple Silicon, toggling manual Night Shift requires both setEnabled: and setActive:
        let setEnabledSel = Selector(("setEnabled:"))
        if (client as AnyObject).responds(to: setEnabledSel) {
            typealias SetEnabledFunc = @convention(c) (AnyObject, Selector, Bool) -> Bool
            let imp = (client as AnyObject).method(for: setEnabledSel)
            let fn = unsafeBitCast(imp, to: SetEnabledFunc.self)
            _ = fn(client, setEnabledSel, enabled)
        }

        let setActiveSel = Selector(("setActive:"))
        if (client as AnyObject).responds(to: setActiveSel) {
            typealias SetActiveFunc = @convention(c) (AnyObject, Selector, Bool) -> Bool
            let imp = (client as AnyObject).method(for: setActiveSel)
            let fn = unsafeBitCast(imp, to: SetActiveFunc.self)
            _ = fn(client, setActiveSel, enabled)
        }
    }

    /// Read active Night Shift enabled status
    public var isNightShiftEnabled: Bool {
        guard let client = blueLightClient else { return false }
        let sel = Selector(("getBlueLightStatus:"))
        guard (client as AnyObject).responds(to: sel) else { return false }
        typealias GetStatusRawFunc = @convention(c) (AnyObject, Selector, UnsafeMutableRawPointer) -> Bool
        let imp = (client as AnyObject).method(for: sel)
        let fn = unsafeBitCast(imp, to: GetStatusRawFunc.self)
        var buf = [UInt8](repeating: 0, count: 128)
        let ok = fn(client, sel, &buf)
        // In CBBlueLightStatus struct: byte 0 is enabled, byte 1 is active
        return ok && buf.count > 1 && (buf[0] != 0 || buf[1] != 0)
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
