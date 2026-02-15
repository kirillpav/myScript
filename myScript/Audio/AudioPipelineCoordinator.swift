import Foundation

final class AudioPipelineCoordinator: @unchecked Sendable {
    typealias SegmentCallback = @MainActor @Sendable (TranscriptSegment) -> Void

    private let inferenceEngine: WhisperInferenceEngine
    private let onSegment: SegmentCallback

    private var micCapture: MicrophoneCapture?
    private var systemCapture: SystemAudioCapture?
    private var mixer: AudioMixer?
    private var chunker: AudioChunker?

    private let inferenceQueue = DispatchQueue(label: "com.myscript.inference", qos: .userInitiated)
    private var isRunning = false

    init(inferenceEngine: WhisperInferenceEngine, onSegment: @escaping SegmentCallback) {
        self.inferenceEngine = inferenceEngine
        self.onSegment = onSegment
    }

    func start() async throws {
        guard !isRunning else { return }
        isRunning = true

        let engine = inferenceEngine
        let segmentCallback = onSegment

        let chunker = AudioChunker { chunk in
            Task {
                let startTime = CFAbsoluteTimeGetCurrent()
                do {
                    let text = try await engine.transcribe(audioSamples: chunk)
                    let latencyMs = Int((CFAbsoluteTimeGetCurrent() - startTime) * 1000)

                    if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        let segment = TranscriptSegment(
                            timestamp: Date(),
                            text: text.trimmingCharacters(in: .whitespacesAndNewlines),
                            source: .mixed
                        )
                        await MainActor.run {
                            segmentCallback(segment)
                        }
                        await MainActor.run {
                            // Update latency on AppState if accessible
                            // This is handled by the caller
                            _ = latencyMs
                        }
                    }
                } catch {
                    print("Inference error: \(error)")
                }
            }
        }
        self.chunker = chunker

        let mixer = AudioMixer { samples in
            chunker.feed(samples: samples)
        }
        self.mixer = mixer

        // Start mic capture
        let mic = MicrophoneCapture { samples in
            mixer.feedMicSamples(samples)
        }
        self.micCapture = mic
        try mic.start()

        // Start system audio capture (non-fatal if it fails — needs screen recording permission)
        let sys = SystemAudioCapture { samples in
            mixer.feedSystemSamples(samples)
        }
        self.systemCapture = sys
        do {
            try await sys.start()
        } catch {
            print("System audio capture unavailable: \(error). Continuing with mic only.")
        }
    }

    func stop() async {
        guard isRunning else { return }
        isRunning = false

        micCapture?.stop()
        micCapture = nil

        await systemCapture?.stop()
        systemCapture = nil

        chunker?.flush()
        chunker = nil
        mixer = nil
    }
}
