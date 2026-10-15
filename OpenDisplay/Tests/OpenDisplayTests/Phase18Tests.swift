import XCTest
@testable import OpenDisplayCore

final class Phase18Tests: XCTestCase {

    func testDisplayItemModelCachedResolutionsDerivation() {
        #if os(macOS) && arch(arm64)
        let item = DisplayItemModel(id: 99, name: "Pro Display XDR")

        let mode1 = DisplayResolutionDescriptor(
            modeNumber: 1,
            pixelWidth: 6016,
            pixelHeight: 3384,
            pointWidth: 3008,
            pointHeight: 1692,
            refreshRate: 60.0,
            isCurrent: true,
            isNative: true,
            isRecommended: true,
            tier: .recommendedHiDPI,
            aspectRatioString: "16:9"
        )

        let mode2 = DisplayResolutionDescriptor(
            modeNumber: 2,
            pixelWidth: 3840,
            pixelHeight: 2160,
            pointWidth: 3840,
            pointHeight: 2160,
            refreshRate: 60.0,
            isCurrent: false,
            isNative: false,
            isRecommended: false,
            tier: .standard1x,
            aspectRatioString: "16:9"
        )

        XCTAssertTrue(item.availableResolutions.isEmpty)
        XCTAssertTrue(item.recommendedResolutions.isEmpty)
        XCTAssertTrue(item.otherResolutions.isEmpty)
        XCTAssertFalse(item.isAdvancedDrawerExpanded)

        // Assign available resolutions -> triggers didSet cache update
        item.availableResolutions = [mode1, mode2]

        XCTAssertEqual(item.availableResolutions.count, 2)
        XCTAssertEqual(item.recommendedResolutions.count, 1)
        XCTAssertEqual(item.otherResolutions.count, 1)
        XCTAssertEqual(item.recommendedResolutions.first?.id, mode1.id)
        XCTAssertEqual(item.otherResolutions.first?.id, mode2.id)

        // Toggle progressive disclosure drawer state
        item.isAdvancedDrawerExpanded = true
        XCTAssertTrue(item.isAdvancedDrawerExpanded)
        #endif
    }
}
