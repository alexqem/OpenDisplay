#if os(macOS) && arch(arm64)
import Foundation
import ScreenCaptureKit
import CoreMedia
import CoreVideo

/// Observational state of the PiP capture stream
public enum PipStreamState: String, Sendable {
    case idle
    case capturing
    case stopped
    case failed
}

/// Constants for PiP stream sizing and pixel formats
public enum PipConstants {
    public static let defaultWidth: Int = 1920
    public static let defaultHeight: Int = 1080
    public static let defaultFrameRate: Int = 60
    public static let pixelFormat: OSType = kCVPixelFormatType_32BGRA
    public static let queueDepth: Int = 5
}

/// Configuration options for real-time Picture-in-Picture streaming
public struct PipStreamOptions: Sendable {
    public let width: Int
    public let height: Int
    public let frameRate: Int
    public let showsCursor: Bool

    public init(
        width: Int = PipConstants.defaultWidth,
        height: Int = PipConstants.defaultHeight,
        frameRate: Int = PipConstants.defaultFrameRate,
        showsCursor: Bool = true
    ) {
        self.width = width
        self.height = height
        self.frameRate = frameRate
        self.showsCursor = showsCursor
    }
}

/// Real-time screen and window capture engine using ScreenCaptureKit
@available(macOS 12.3, *)
public final class PipCaptureEngine: NSObject, SCStreamOutput, @unchecked Sendable {
    private var stream: SCStream?
    public private(set) var state: PipStreamState = .idle
    public var onFrame: (@Sendable (CVImageBuffer) -> Void)?

    /// Start streaming a physical or virtual display
    public func startCapture(display: SCDisplay, options: PipStreamOptions = PipStreamOptions()) async throws {
        let filter = SCContentFilter(display: display, excludingWindows: [])
        let config = SCStreamConfiguration()
        config.width = options.width
        config.height = options.height
        config.minimumFrameInterval = CMTime(value: 1, timescale: CMTimeScale(options.frameRate))
        config.showsCursor = options.showsCursor
        config.pixelFormat = PipConstants.pixelFormat
        config.queueDepth = PipConstants.queueDepth

        do {
            let scStream = SCStream(filter: filter, configuration: config, delegate: nil)
            try scStream.addStreamOutput(self, type: .screen, sampleHandlerQueue: .main)
            try await scStream.startCapture()
            self.stream = scStream
            self.state = .capturing
        } catch {
            self.state = .failed
            throw error
        }
    }

    /// Stop capture stream
    public func stopCapture() async throws {
        try await stream?.stopCapture()
        stream = nil
        state = .stopped
    }

    deinit {
        if let activeStream = stream {
            Task {
                try? await activeStream.stopCapture()
            }
        }
    }

    // MARK: - SCStreamOutput
    public func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen, let imageBuffer = sampleBuffer.imageBuffer else { return }
        onFrame?(imageBuffer)
    }
}
#endif
