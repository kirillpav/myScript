import Foundation

final class AudioMixer: Sendable {
    typealias SampleCallback = @Sendable ([Float]) -> Void

    private let onMixedSamples: SampleCallback

    init(onMixedSamples: @escaping SampleCallback) {
        self.onMixedSamples = onMixedSamples
    }

    func feedMicSamples(_ samples: [Float]) {
        // In MVP mode, mic samples pass through directly
        onMixedSamples(samples)
    }

    func feedSystemSamples(_ samples: [Float]) {
        // In MVP mode, system samples pass through directly
        onMixedSamples(samples)
    }
}
