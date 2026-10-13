#if os(macOS) && arch(arm64)
import Foundation
import QuartzCore
import MetalKit

/// Manages Liquid Retina XDR / HDR Headroom Overdrive to unlock peak 1000–1600 nit brightness
public enum XDROverdriveEngine {

    /// Configure a Metal layer to participate in macOS Extended Dynamic Range (EDR) pipeline
    public static func configureEDRLayer(_ layer: CAMetalLayer) {
        layer.wantsExtendedDynamicRangeContent = true
        layer.pixelFormat = .rgba16Float
        layer.colorspace = CGColorSpace(name: CGColorSpace.extendedLinearSRGB)
    }

    /// Calculate EDR target headroom factor (1.0 = standard SDR 500 nits, up to max potential EDR)
    public static func calculateHeadroomMultiplier(
        targetNits: Float,
        baseSDRNits: Float = XDROverdriveConstants.baseSDRNits
    ) -> Float {
        guard baseSDRNits > 0 else { return XDROverdriveConstants.defaultHeadroomMultiplier }
        let clampedTarget = max(baseSDRNits, min(XDROverdriveConstants.peakXDRNits, targetNits))
        return clampedTarget / baseSDRNits
    }
}
#endif
