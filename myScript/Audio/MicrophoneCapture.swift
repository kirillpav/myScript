import AVFoundation

final class MicrophoneCapture: Sendable {
    typealias SampleCallback = @Sendable ([Float]) -> Void

    private let engine = AVAudioEngine()
    private let targetSampleRate: Double = 16000
    private let onSamples: SampleCallback

    init(onSamples: @escaping SampleCallback) {
        self.onSamples = onSamples
    }

    func start() throws {
        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        guard inputFormat.sampleRate > 0 else {
            throw MicrophoneCaptureError.noInputDevice
        }

        let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: targetSampleRate,
            channels: 1,
            interleaved: false
        )!

        let converter = AVAudioConverter(from: inputFormat, to: targetFormat)

        let callback = onSamples
        let sampleRate = targetSampleRate

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { buffer, _ in
            if let converter {
                let ratio = sampleRate / inputFormat.sampleRate
                let outputFrameCount = AVAudioFrameCount(Double(buffer.frameLength) * ratio)
                guard let outputBuffer = AVAudioPCMBuffer(
                    pcmFormat: targetFormat,
                    frameCapacity: outputFrameCount
                ) else { return }

                var error: NSError?
                var consumed = false
                converter.convert(to: outputBuffer, error: &error) { _, outStatus in
                    if consumed {
                        outStatus.pointee = .noDataNow
                        return nil
                    }
                    consumed = true
                    outStatus.pointee = .haveData
                    return buffer
                }

                if error == nil, let channelData = outputBuffer.floatChannelData {
                    let samples = Array(UnsafeBufferPointer(
                        start: channelData[0],
                        count: Int(outputBuffer.frameLength)
                    ))
                    callback(samples)
                }
            } else {
                // Same format, no conversion needed
                if let channelData = buffer.floatChannelData {
                    let samples = Array(UnsafeBufferPointer(
                        start: channelData[0],
                        count: Int(buffer.frameLength)
                    ))
                    callback(samples)
                }
            }
        }

        engine.prepare()
        try engine.start()
    }

    func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
    }
}

enum MicrophoneCaptureError: LocalizedError {
    case noInputDevice

    var errorDescription: String? {
        switch self {
        case .noInputDevice: "No audio input device available"
        }
    }
}
