import Foundation
import CoreGraphics

/// Pure functional generator and hardware applier for gamma LUT transfer tables
public enum GammaDimmingEngine {

    /// Compute normalized gamma transfer curve (100% testable offline)
    /// level: 0.0 (complete blackout) to 1.0 (normal brightness)
    public static func generateTable(
        size: UInt32 = GammaTableConstants.standardTableSize,
        level: Float,
        gamma: Float = 1.0
    ) throws -> [Float] {
        guard size >= 2 else {
            throw LuminanceError.invalidTableSize(size)
        }

        let clampedLevel = max(0.0, min(1.0, level))
        var table = [Float](repeating: 0.0, count: Int(size))
        let maxIndex = Float(size - 1)

        for i in 0..<Int(size) {
            let normalized = Float(i) / maxIndex
            let powered = pow(normalized, gamma)
            table[i] = powered * clampedLevel
        }

        return table
    }

    #if os(macOS) && arch(arm64)
    /// Apply appearance presets (Standard, Inverted, Grayscale, Inverted Grayscale) via gamma transfer tables
    public static func applyAppearancePreset(displayID: CGDirectDisplayID, preset: DisplayAppearancePreset) throws {
        let size = GammaTableConstants.standardTableSize
        let maxIndex = Float(size - 1)
        var redTable = [Float](repeating: 0.0, count: Int(size))
        var greenTable = [Float](repeating: 0.0, count: Int(size))
        var blueTable = [Float](repeating: 0.0, count: Int(size))

        switch preset {
        case .standard:
            try restoreGamma(displayID: displayID)
            return

        case .inverted:
            for i in 0..<Int(size) {
                let val = 1.0 - (Float(i) / maxIndex)
                redTable[i] = val
                greenTable[i] = val
                blueTable[i] = val
            }

        case .grayscale:
            for i in 0..<Int(size) {
                let val = Float(i) / maxIndex
                redTable[i] = val
                greenTable[i] = val
                blueTable[i] = val
            }

        case .invertedGrayscale:
            for i in 0..<Int(size) {
                let val = 1.0 - (Float(i) / maxIndex)
                redTable[i] = val
                greenTable[i] = val
                blueTable[i] = val
            }
        }

        let status = CGSetDisplayTransferByTable(
            displayID,
            size,
            &redTable,
            &greenTable,
            &blueTable
        )
        guard status == .success else {
            throw LuminanceError.gammaApplicationFailed(status.rawValue)
        }
    }

    /// Apply software dimming below 0% hardware brightness via hardware gamma tables
    public static func applyGammaDimming(
        displayID: CGDirectDisplayID,
        level: Float
    ) throws {
        let table = try generateTable(size: GammaTableConstants.standardTableSize, level: level)

        var redTable = table
        var greenTable = table
        var blueTable = table

        let status = CGSetDisplayTransferByTable(
            displayID,
            GammaTableConstants.standardTableSize,
            &redTable,
            &greenTable,
            &blueTable
        )

        guard status == .success else {
            throw LuminanceError.gammaApplicationFailed(status.rawValue)
        }
    }

    /// Restore neutral 1.0 linear gamma curve (used on wake, display change, or reset)
    public static func restoreGamma(displayID: CGDirectDisplayID) throws {
        try applyGammaDimming(displayID: displayID, level: 1.0)
    }
    #endif
}
