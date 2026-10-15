import Foundation

/// Lightweight, thread-safe file logger with automatic size capping (default 1MB)
public final class AppLogger: @unchecked Sendable {
    public static let shared = AppLogger()

    public static let maxLogSizeBytes: Int = 1_048_576 // 1 MB cap
    public static let defaultLogDirectoryName: String = "OpenDisplay"
    public static let defaultLogFileName: String = "opendisplay.log"

    private let fileHandle: FileHandle?
    private let logFileURL: URL?
    private let lock = NSLock()
    private let dateFormatter: DateFormatter

    public init(customFileURL: URL? = nil) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        self.dateFormatter = formatter

        let targetURL: URL?
        if let customFileURL {
            targetURL = customFileURL
        } else {
            let logsDir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first?
                .appendingPathComponent("Logs", isDirectory: true)
                .appendingPathComponent(AppLogger.defaultLogDirectoryName, isDirectory: true)
            if let logsDir {
                try? FileManager.default.createDirectory(at: logsDir, withIntermediateDirectories: true)
                targetURL = logsDir.appendingPathComponent(AppLogger.defaultLogFileName)
            } else {
                targetURL = nil
            }
        }

        self.logFileURL = targetURL

        if let targetURL {
            if !FileManager.default.fileExists(atPath: targetURL.path) {
                FileManager.default.createFile(atPath: targetURL.path, contents: nil)
            }
            self.fileHandle = try? FileHandle(forWritingTo: targetURL)
            self.fileHandle?.seekToEndOfFile()
        } else {
            self.fileHandle = nil
        }

        log("AppLogger initialized at \(targetURL?.path ?? "unknown path")")
    }

    deinit {
        try? fileHandle?.close()
    }

    /// Retrieve the absolute path of the current log file
    public var currentLogPath: String? {
        return logFileURL?.path
    }

    /// Write formatted log message with timestamp and auto-rotation if > 1MB
    public func log(_ message: String, file: String = #file, line: Int = #line) {
        lock.lock()
        defer { lock.unlock() }

        let fileName = (file as NSString).lastPathComponent
        let timestamp = dateFormatter.string(from: Date())
        let lineEntry = "[\(timestamp)] [\(fileName):\(line)] \(message)\n"

        // Also print to stdout for interactive debugging
        print(lineEntry, terminator: "")

        guard let data = lineEntry.data(using: .utf8), let handle = fileHandle, let fileURL = logFileURL else {
            return
        }

        // Check file size for 1MB cap
        if let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
           let fileSize = attrs[.size] as? Int, fileSize >= AppLogger.maxLogSizeBytes {
            rotateLog(currentHandle: handle, fileURL: fileURL)
        }

        handle.write(data)
    }

    private func rotateLog(currentHandle: FileHandle, fileURL: URL) {
        try? currentHandle.truncate(atOffset: 0)
        try? currentHandle.seek(toOffset: 0)
        let header = "--- LOG ROTATED (1MB LIMIT EXCEEDED) ---\n"
        if let headerData = header.data(using: .utf8) {
            currentHandle.write(headerData)
        }
    }
}
