import Foundation

final class AudioChunker: @unchecked Sendable {
    typealias ChunkCallback = @Sendable ([Float]) -> Void

    private let chunkSize: Int      // 5 seconds @ 16kHz = 80000 samples
    private let overlapSize: Int    // 1 second @ 16kHz = 16000 samples
    private let onChunk: ChunkCallback

    private let queue = DispatchQueue(label: "com.myscript.audiochunker")
    private var buffer: [Float] = []

    init(
        sampleRate: Int = 16000,
        chunkDuration: Double = 5.0,
        overlapDuration: Double = 1.0,
        onChunk: @escaping ChunkCallback
    ) {
        self.chunkSize = Int(Double(sampleRate) * chunkDuration)
        self.overlapSize = Int(Double(sampleRate) * overlapDuration)
        self.onChunk = onChunk
    }

    func feed(samples: [Float]) {
        queue.async { [self] in
            buffer.append(contentsOf: samples)

            while buffer.count >= chunkSize {
                let chunk = Array(buffer.prefix(chunkSize))
                onChunk(chunk)
                // Advance by (chunkSize - overlapSize) to maintain overlap
                let advance = chunkSize - overlapSize
                buffer.removeFirst(advance)
            }
        }
    }

    func flush() {
        queue.async { [self] in
            if !buffer.isEmpty {
                // Pad final chunk with zeros if needed
                var chunk = buffer
                if chunk.count < chunkSize {
                    chunk.append(contentsOf: [Float](repeating: 0, count: chunkSize - chunk.count))
                }
                onChunk(chunk)
                buffer.removeAll()
            }
        }
    }

    func reset() {
        queue.async { [self] in
            buffer.removeAll()
        }
    }
}
