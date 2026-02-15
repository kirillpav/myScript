import Foundation

struct TranscriptSegment: Identifiable, Sendable {
    let id = UUID()
    let timestamp: Date
    let text: String
    let source: AudioSource

    enum AudioSource: String, Sendable {
        case microphone = "Mic"
        case system = "Remote"
        case mixed = "Mixed"
    }

    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: timestamp)
    }

    var displayText: String {
        "[\(formattedTimestamp)] \(text)"
    }
}
