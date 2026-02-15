import ScreenCaptureKit
import AVFoundation
import CoreMedia

final class SystemAudioCapture: NSObject, Sendable {
    typealias SampleCallback = @Sendable ([Float]) -> Void

    private let onSamples: SampleCallback
    private let stream: SCStream? = nil

    // Use a class-level property to hold the active stream since SCStream isn't Sendable
    private final class StreamHolder: @unchecked Sendable {
        var stream: SCStream?
    }
    private let streamHolder = StreamHolder()

    init(onSamples: @escaping SampleCallback) {
        self.onSamples = onSamples
    }

    func start() async throws {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)

        guard let display = content.displays.first else {
            throw SystemAudioCaptureError.noDisplay
        }

        let filter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])

        let config = SCStreamConfiguration()
        config.capturesAudio = true
        config.sampleRate = 16000
        config.channelCount = 1
        config.excludesCurrentProcessAudio = true
        // Minimal video to satisfy API requirements
        config.width = 2
        config.height = 2
        config.minimumFrameInterval = CMTime(value: 1, timescale: 1)

        let delegate = AudioStreamDelegate(onSamples: onSamples)

        let newStream = SCStream(filter: filter, configuration: config, delegate: nil)
        try newStream.addStreamOutput(delegate, type: .audio, sampleHandlerQueue: .global(qos: .userInteractive))
        try await newStream.startCapture()

        streamHolder.stream = newStream
        // Hold delegate reference so it doesn't get deallocated
        objc_setAssociatedObject(newStream, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
    }

    func stop() async {
        try? await streamHolder.stream?.stopCapture()
        streamHolder.stream = nil
    }
}

private final class AudioStreamDelegate: NSObject, SCStreamOutput, @unchecked Sendable {
    let onSamples: @Sendable ([Float]) -> Void

    init(onSamples: @escaping @Sendable ([Float]) -> Void) {
        self.onSamples = onSamples
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .audio else { return }
        guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return }

        var length = 0
        var dataPointer: UnsafeMutablePointer<Int8>?
        CMBlockBufferGetDataPointer(blockBuffer, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &length, dataPointerOut: &dataPointer)

        guard let dataPointer else { return }

        let floatCount = length / MemoryLayout<Float>.size
        let floatPointer = UnsafeRawPointer(dataPointer).bindMemory(to: Float.self, capacity: floatCount)
        let samples = Array(UnsafeBufferPointer(start: floatPointer, count: floatCount))
        onSamples(samples)
    }
}

enum SystemAudioCaptureError: LocalizedError {
    case noDisplay

    var errorDescription: String? {
        switch self {
        case .noDisplay: "No display available for audio capture"
        }
    }
}
