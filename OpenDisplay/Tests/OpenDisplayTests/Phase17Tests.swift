import XCTest
@testable import OpenDisplayCore

final class Phase17Tests: XCTestCase {

    func testAspectRatioCalculation() {
        XCTAssertEqual(ResolutionClassifier.aspectRatioString(width: 3840, height: 2160), "16:9")
        XCTAssertEqual(ResolutionClassifier.aspectRatioString(width: 2560, height: 1440), "16:9")
        XCTAssertEqual(ResolutionClassifier.aspectRatioString(width: 1920, height: 1080), "16:9")
        XCTAssertEqual(ResolutionClassifier.aspectRatioString(width: 3456, height: 2234), "1728:1117")
        XCTAssertEqual(ResolutionClassifier.aspectRatioString(width: 2560, height: 1600), "16:10")
        XCTAssertEqual(ResolutionClassifier.aspectRatioString(width: 3440, height: 1440), "21:9")  // Ultra-wide (43:18 marketing normalized)
        XCTAssertEqual(ResolutionClassifier.aspectRatioString(width: 5120, height: 1440), "32:9")  // Super ultra-wide
        XCTAssertEqual(ResolutionClassifier.aspectRatioString(width: 0, height: 1080), "Unknown")
    }

    func testResolutionClassificationFor4KMonitor() {
        let nativeW = 3840
        let nativeH = 2160

        // 1. Native Retina HiDPI 2x (3840x2160 panel, 1920x1080 point size) -> Recommended HiDPI
        let mode1 = ResolutionClassifier.classify(
            modeNumber: 1,
            pixelWidth: 3840,
            pixelHeight: 2160,
            pointWidth: 1920,
            pointHeight: 1080,
            refreshRate: 60.0,
            nativePixelWidth: nativeW,
            nativePixelHeight: nativeH,
            isCurrent: true
        )
        XCTAssertTrue(mode1.isNative)
        XCTAssertTrue(mode1.isHiDPI)
        XCTAssertTrue(mode1.isRecommended)
        XCTAssertEqual(mode1.tier, .recommendedHiDPI)
        XCTAssertEqual(mode1.scaleFactor, 2.0)
        XCTAssertEqual(mode1.userLabel, "1920 × 1080 (HiDPI) (Native) · 60Hz")
        XCTAssertEqual(mode1.resolutionOnlyLabel, "1920 × 1080 (HiDPI) (Native)")

        // 2. Scaled HiDPI "Looks like 2560x1440" on 4K (pixel buffer 5120x2880 or downscaled) -> Recommended
        let mode2 = ResolutionClassifier.classify(
            modeNumber: 2,
            pixelWidth: 3840,
            pixelHeight: 2160,
            pointWidth: 2560,
            pointHeight: 1440,
            refreshRate: 144.0,
            nativePixelWidth: nativeW,
            nativePixelHeight: nativeH,
            isCurrent: false
        )
        XCTAssertTrue(mode2.isNative)
        XCTAssertTrue(mode2.isHiDPI)
        XCTAssertTrue(mode2.isRecommended)
        XCTAssertEqual(mode2.tier, .recommendedHiDPI)
        XCTAssertEqual(mode2.scaleFactor, 1.5)
        XCTAssertEqual(mode2.userLabel, "2560 × 1440 (HiDPI) (Native) · 144Hz")
        XCTAssertEqual(mode2.resolutionOnlyLabel, "2560 × 1440 (HiDPI) (Native)")

        // 3. Stretched non-native aspect mode (1920x1200 on 16:9 panel) -> Not recommended
        let mode3 = ResolutionClassifier.classify(
            modeNumber: 3,
            pixelWidth: 1920,
            pixelHeight: 1200,
            pointWidth: 1920,
            pointHeight: 1200,
            refreshRate: 60.0,
            nativePixelWidth: nativeW,
            nativePixelHeight: nativeH,
            isCurrent: false
        )
        XCTAssertFalse(mode3.isNative)
        XCTAssertFalse(mode3.isHiDPI)
        XCTAssertFalse(mode3.isRecommended)
        XCTAssertEqual(mode3.tier, .nonNativeAspect)

        // 4. Low resolution 1x native (3840x2160 point width = 3840) -> Native tier
        let mode4 = ResolutionClassifier.classify(
            modeNumber: 4,
            pixelWidth: 3840,
            pixelHeight: 2160,
            pointWidth: 3840,
            pointHeight: 2160,
            refreshRate: 60.0,
            nativePixelWidth: nativeW,
            nativePixelHeight: nativeH,
            isCurrent: false
        )
        XCTAssertTrue(mode4.isNative)
        XCTAssertFalse(mode4.isHiDPI)
        XCTAssertTrue(mode4.isRecommended)
        XCTAssertEqual(mode4.tier, .native)
    }

    func testCLIResolutionParsing() {
        let args1 = ["set-resolution", "-target=1", "-width=2560", "-height=1440", "-hidpi=true"]
        let cmd1 = OpenDisplayCLI.parse(arguments: args1)
        XCTAssertEqual(cmd1, .setResolution(target: "1", width: 2560, height: 1440, isHiDPI: true))

        let args2 = ["resolution", "-width=1920", "-height=1080", "-hidpi=0"]
        let cmd2 = OpenDisplayCLI.parse(arguments: args2)
        XCTAssertEqual(cmd2, .setResolution(target: AutomationConstants.cliDefaultTargetActive, width: 1920, height: 1080, isHiDPI: false))

        let args3 = ["list-resolutions", "-target=2"]
        let cmd3 = OpenDisplayCLI.parse(arguments: args3)
        XCTAssertEqual(cmd3, .listResolutions(target: "2"))
    }
}
