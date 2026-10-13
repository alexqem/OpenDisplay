import XCTest
@testable import OpenDisplayCore

final class Phase5Tests: XCTestCase {

    func testGammaTableGenerationNormal() throws {
        let table = try GammaDimmingEngine.generateTable(size: 256, level: 1.0, gamma: 1.0)
        XCTAssertEqual(table.count, 256)
        XCTAssertEqual(table.first!, 0.0, accuracy: 0.0001)
        XCTAssertEqual(table.last!, 1.0, accuracy: 0.0001)

        // Monotonically non-decreasing
        for i in 1..<table.count {
            XCTAssertGreaterThanOrEqual(table[i], table[i - 1])
        }
    }

    func testGammaTableGenerationDimmed() throws {
        let table = try GammaDimmingEngine.generateTable(size: 256, level: 0.5, gamma: 1.0)
        XCTAssertEqual(table.count, 256)
        XCTAssertEqual(table.first!, 0.0, accuracy: 0.0001)
        XCTAssertEqual(table.last!, 0.5, accuracy: 0.0001)
    }

    func testGammaTableBlackout() throws {
        let table = try GammaDimmingEngine.generateTable(size: 256, level: 0.0, gamma: 1.0)
        XCTAssertEqual(table.count, 256)
        for val in table {
            XCTAssertEqual(val, 0.0, accuracy: 0.0001)
        }
    }

    func testGammaTableInvalidSizeError() {
        XCTAssertThrowsError(try GammaDimmingEngine.generateTable(size: 1, level: 1.0)) { error in
            XCTAssertEqual(error as? LuminanceError, LuminanceError.invalidTableSize(1))
        }
    }

    func testRestoreGammaCurve() throws {
        // Restore curve must be linear 1.0 curve with exact 0.0 -> 1.0 progression
        let table = try GammaDimmingEngine.generateTable(size: GammaTableConstants.standardTableSize, level: 1.0, gamma: 1.0)
        XCTAssertEqual(table.count, Int(GammaTableConstants.standardTableSize))
        XCTAssertEqual(table.first!, 0.0, accuracy: 0.0001)
        XCTAssertEqual(table.last!, 1.0, accuracy: 0.0001)
        XCTAssertEqual(table[128], 128.0 / 255.0, accuracy: 0.001)
    }

    func testHeadroomMultiplierMath() {
        #if os(macOS) && arch(arm64)
        XCTAssertEqual(XDROverdriveEngine.calculateHeadroomMultiplier(targetNits: 500.0), 1.0, accuracy: 0.01)
        XCTAssertEqual(XDROverdriveEngine.calculateHeadroomMultiplier(targetNits: 1000.0), 2.0, accuracy: 0.01)
        XCTAssertEqual(XDROverdriveEngine.calculateHeadroomMultiplier(targetNits: 1600.0), 3.2, accuracy: 0.01)
        #endif
    }
}
