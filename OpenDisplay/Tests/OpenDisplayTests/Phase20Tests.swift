import XCTest
@testable import OpenDisplayCore

final class Phase20Tests: XCTestCase {

    func testAppLoggerCustomPathAndRotation() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let logFile = tempDir.appendingPathComponent("test.log")
        let logger = AppLogger(customFileURL: logFile)

        XCTAssertEqual(logger.currentLogPath, logFile.path)

        // Write some log messages
        logger.log("Hello OpenDisplay Logger")
        logger.log("Second log line")

        let content = try String(contentsOf: logFile, encoding: .utf8)
        XCTAssertTrue(content.contains("Hello OpenDisplay Logger"))
        XCTAssertTrue(content.contains("Second log line"))
    }
}
