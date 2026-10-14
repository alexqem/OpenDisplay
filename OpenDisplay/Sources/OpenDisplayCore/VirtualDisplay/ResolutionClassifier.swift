import Foundation
import CoreGraphics

/// Quality and scaling tier of a display mode
public enum ResolutionTier: String, Sendable, CaseIterable {
    case native           = "Native"
    case recommendedHiDPI = "Recommended HiDPI"
    case scaledHiDPI      = "Scaled HiDPI"
    case standard1x       = "Low Resolution (1x)"
    case nonNativeAspect  = "Stretched / Non-Native Aspect"
}

/// Rich descriptor of a display resolution mode
public struct DisplayResolutionDescriptor: Identifiable, Equatable, Sendable {
    public let id: String
    public let modeNumber: Int32
    public let pixelWidth: Int
    public let pixelHeight: Int
    public let pointWidth: Int
    public let pointHeight: Int
    public let scaleFactor: Double
    public let refreshRate: Double
    public let isCurrent: Bool
    public let isNative: Bool
    public let isHiDPI: Bool
    public let isRecommended: Bool
    public let tier: ResolutionTier
    public let aspectRatioString: String

    public init(
        modeNumber: Int32,
        pixelWidth: Int,
        pixelHeight: Int,
        pointWidth: Int,
        pointHeight: Int,
        refreshRate: Double,
        isCurrent: Bool,
        isNative: Bool,
        isRecommended: Bool,
        tier: ResolutionTier,
        aspectRatioString: String
    ) {
        self.id = "\(modeNumber)_\(pixelWidth)x\(pixelHeight)@\(Int(refreshRate.rounded()))Hz"
        self.modeNumber = modeNumber
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
        self.pointWidth = pointWidth
        self.pointHeight = pointHeight
        self.scaleFactor = pointWidth > 0 ? (Double(pixelWidth) / Double(pointWidth)) : 1.0
        self.refreshRate = refreshRate
        self.isCurrent = isCurrent
        self.isNative = isNative
        self.isHiDPI = (pointWidth > 0 && pixelWidth > pointWidth)
        self.isRecommended = isRecommended
        self.tier = tier
        self.aspectRatioString = aspectRatioString
    }

    /// User-facing label: e.g. "2560 × 1440 (HiDPI) - 144Hz ★ Recommended"
    public var userLabel: String {
        let hiDpiBadge = isHiDPI ? " (HiDPI)" : ""
        let nativeBadge = isNative ? " (Native)" : ""
        let rate = "\(Int(refreshRate.rounded()))Hz"
        return "\(pointWidth) × \(pointHeight)\(hiDpiBadge)\(nativeBadge) · \(rate)"
    }
}

/// Pure functional classifier for display resolution modes (100% testable without hardware)
public enum ResolutionClassifier {

    /// Greatest Common Divisor helper to compute aspect ratio
    public static func gcd(_ a: Int, _ b: Int) -> Int {
        var x = abs(a)
        var y = abs(b)
        while y != 0 {
            let temp = y
            y = x % y
            x = temp
        }
        return x
    }

    /// Format aspect ratio as clean string: e.g. "16:9", "16:10", "21:9"
    public static func aspectRatioString(width: Int, height: Int) -> String {
        guard width > 0 && height > 0 else { return "Unknown" }
        let d = gcd(width, height)
        let w = width / d
        let h = height / d

        // Normalize common aspect ratios to marketing standard names
        if (w == 64 && h == 27) || (w == 43 && h == 18) {
            return "21:9"
        }
        if w == 8 && h == 5 {
            return "16:10"
        }
        return "\(w):\(h)"
    }

    /// Classify a display mode given the display's native pixel panel resolution
    public static func classify(
        modeNumber: Int32,
        pixelWidth: Int,
        pixelHeight: Int,
        pointWidth: Int,
        pointHeight: Int,
        refreshRate: Double,
        nativePixelWidth: Int,
        nativePixelHeight: Int,
        isCurrent: Bool
    ) -> DisplayResolutionDescriptor {
        let isNative = (pixelWidth == nativePixelWidth && pixelHeight == nativePixelHeight)
        let isHiDPI = (pointWidth > 0 && pixelWidth > pointWidth)
        let aspect = aspectRatioString(width: pixelWidth, height: pixelHeight)
        let nativeAspect = aspectRatioString(width: nativePixelWidth, height: nativePixelHeight)

        let aspectMatches = (aspect == nativeAspect)

        let tier: ResolutionTier
        let isRecommended: Bool

        if !aspectMatches && nativePixelWidth > 0 && nativePixelHeight > 0 {
            tier = .nonNativeAspect
            isRecommended = false
        } else if isNative && isHiDPI {
            tier = .recommendedHiDPI
            isRecommended = true
        } else if isNative && !isHiDPI {
            tier = .native
            isRecommended = true
        } else if isHiDPI {
            // Check if scaled resolution is within recommended scale range (e.g. perfect 2x or sweet-spot HiDPI)
            let scale = pointWidth > 0 ? (Double(pixelWidth) / Double(pointWidth)) : 1.0
            if abs(scale - ResolutionConstants.standardHiDPIScale) < 0.01 {
                tier = .recommendedHiDPI
                isRecommended = true
            } else if scale >= ResolutionConstants.minRecommendedScale && scale <= ResolutionConstants.maxRecommendedScale {
                tier = .scaledHiDPI
                // Mark clean integral or standard fraction scales as recommended
                isRecommended = true
            } else {
                tier = .scaledHiDPI
                isRecommended = false
            }
        } else {
            tier = .standard1x
            isRecommended = false
        }

        return DisplayResolutionDescriptor(
            modeNumber: modeNumber,
            pixelWidth: pixelWidth,
            pixelHeight: pixelHeight,
            pointWidth: pointWidth,
            pointHeight: pointHeight,
            refreshRate: refreshRate,
            isCurrent: isCurrent,
            isNative: isNative,
            isRecommended: isRecommended,
            tier: tier,
            aspectRatioString: aspect
        )
    }
}
