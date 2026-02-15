import Foundation
import SwiftUI

enum ModelState: Equatable {
    case notLoaded
    case loading
    case ready
    case error(String)

    var label: String {
        switch self {
        case .notLoaded: "Not Loaded"
        case .loading: "Loading..."
        case .ready: "Ready"
        case .error(let msg): "Error: \(msg)"
        }
    }

    var color: Color {
        switch self {
        case .notLoaded: .gray
        case .loading: .orange
        case .ready: .green
        case .error: .red
        }
    }
}

@Observable
@MainActor
final class AppState {
    var modelState: ModelState = .notLoaded
    var isRecording = false
    var liveSegments: [TranscriptSegment] = []
    var lastInferenceLatencyMs: Int = 0
    var currentSession: TranscriptSession?
    var recentSessions: [TranscriptSession] = []

    private var inferenceEngine: WhisperInferenceEngine?
    private var audioPipeline: AudioPipelineCoordinator?

    func loadModel() async {
        guard modelState != .loading else { return }
        modelState = .loading

        do {
            let engine = WhisperInferenceEngine()
            try await engine.loadModel()
            inferenceEngine = engine
            modelState = .ready
        } catch {
            modelState = .error(error.localizedDescription)
        }
    }

    func startRecording() async {
        guard modelState == .ready, !isRecording else { return }

        liveSegments = []
        currentSession = TranscriptSession(startTime: Date(), segments: [])
        isRecording = true

        guard let engine = inferenceEngine else { return }

        let pipeline = AudioPipelineCoordinator(inferenceEngine: engine) { [weak self] segment in
            Task { @MainActor in
                self?.liveSegments.append(segment)
                self?.currentSession?.segments.append(segment)
            }
        }
        audioPipeline = pipeline

        do {
            try await pipeline.start()
        } catch {
            isRecording = false
            modelState = .error("Audio pipeline failed: \(error.localizedDescription)")
        }
    }

    func stopRecording() async {
        guard isRecording else { return }
        isRecording = false

        await audioPipeline?.stop()
        audioPipeline = nil

        if var session = currentSession {
            session.endTime = Date()
            currentSession = session
            recentSessions.insert(session, at: 0)

            let store = TranscriptStore()
            do {
                try store.save(session: session)
            } catch {
                print("Failed to save transcript: \(error)")
            }
        }
    }
}
