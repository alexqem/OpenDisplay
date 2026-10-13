#if os(macOS) && arch(arm64)
import Foundation
import CoreGraphics

/// Controller providing display mirroring / cloning capabilities via CoreGraphics
public enum DisplayMirrorController {

    /// Safe execution of display configuration transactions
    private static func performConfiguration(_ block: (CGDisplayConfigRef) -> Void) -> Bool {
        var config: CGDisplayConfigRef?
        guard CGBeginDisplayConfiguration(&config) == .success, let cfg = config else {
            return false
        }

        block(cfg)

        let result = CGCompleteDisplayConfiguration(cfg, .forSession)
        if result != .success {
            CGCancelDisplayConfiguration(cfg)
            return false
        }
        return true
    }

    /// Check if target display is currently mirroring another display
    public static func mirrorSource(for displayID: CGDirectDisplayID) -> CGDirectDisplayID? {
        let source = CGDisplayMirrorsDisplay(displayID)
        guard source != MirrorConstants.nullDirectDisplay else { return nil }
        return source
    }

    /// Check if target display is actively mirroring
    public static func isMirroring(_ displayID: CGDirectDisplayID) -> Bool {
        return mirrorSource(for: displayID) != nil
    }

    /// Check if display is acting as a mirror source (at least one online display mirrors it)
    public static func isMirrorSource(_ displayID: CGDirectDisplayID) -> Bool {
        var count: UInt32 = 0
        CGGetOnlineDisplayList(0, nil, &count)
        guard count > 0 else { return false }
        var ids = [CGDirectDisplayID](repeating: 0, count: Int(count))
        CGGetOnlineDisplayList(count, &ids, &count)
        return ids.contains { $0 != displayID && CGDisplayMirrorsDisplay($0) == displayID }
    }

    /// Configure target display to mirror source display
    public static func enableMirror(sourceID: CGDirectDisplayID, targetID: CGDirectDisplayID) -> Bool {
        guard sourceID != targetID else { return false }
        return performConfiguration { cfg in
            CGConfigureDisplayMirrorOfDisplay(cfg, targetID, sourceID)
        }
    }

    /// Disable mirroring on display (return to extended desktop mode)
    public static func disableMirror(for displayID: CGDirectDisplayID) -> Bool {
        return performConfiguration { cfg in
            CGConfigureDisplayMirrorOfDisplay(cfg, displayID, MirrorConstants.nullDirectDisplay)
        }
    }
}
#endif
