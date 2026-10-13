#if os(macOS) && arch(arm64)
import Foundation
import CoreGraphics

/// Controller managing display canvas arrangement and primary display assignment
public enum DisplayArrangementController {

    /// Perform a batch display configuration transaction safely
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

    /// Move display to specific global coordinates
    /// - Parameters:
    ///   - displayID: Target CGDirectDisplayID
    ///   - x: X coordinate in global display space
    ///   - y: Y coordinate in global display space
    public static func setDisplayOrigin(displayID: CGDirectDisplayID, x: Int32, y: Int32) -> Bool {
        return performConfiguration { cfg in
            CGConfigureDisplayOrigin(cfg, displayID, x, y)
        }
    }

    /// Promote a target display to primary display (origin 0,0) and swap previous main display
    /// - Parameters:
    ///   - targetID: New primary display
    ///   - currentMainID: Existing primary display
    ///   - previousTargetOrigin: Origin where target was previously positioned
    public static func swapMainDisplay(
        targetID: CGDirectDisplayID,
        currentMainID: CGDirectDisplayID,
        previousTargetOrigin: CGPoint
    ) -> Bool {
        return performConfiguration { cfg in
            CGConfigureDisplayOrigin(cfg, targetID, ArrangementConstants.originX, ArrangementConstants.originY)
            CGConfigureDisplayOrigin(cfg, currentMainID, Int32(previousTargetOrigin.x), Int32(previousTargetOrigin.y))
        }
    }
}
#endif
