import Foundation
import AppKit

struct TranscriptStore {
    private let transcriptsDirectory: URL

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        transcriptsDirectory = docs.appendingPathComponent("Transcripts", isDirectory: true)
    }

    func save(session: TranscriptSession) throws {
        try FileManager.default.createDirectory(at: transcriptsDirectory, withIntermediateDirectories: true)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH-mm-ss"
        let filename = "transcript_\(formatter.string(from: session.startTime)).md"

        let fileURL = transcriptsDirectory.appendingPathComponent(filename)
        try session.markdownContent.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    func loadSessions() -> [TranscriptSession] {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: transcriptsDirectory, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles) else {
            return []
        }

        return files
            .filter { $0.pathExtension == "md" }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
            .compactMap { parseSession(from: $0) }
    }

    static func copyToClipboard(text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    private func parseSession(from url: URL) -> TranscriptSession? {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return nil }

        let lines = content.components(separatedBy: "\n")
        var segments: [TranscriptSegment] = []
        var startTime = Date()

        for line in lines {
            if line.hasPrefix("**Start:**") {
                let dateStr = line.replacingOccurrences(of: "**Start:** ", with: "")
                let fmt = DateFormatter()
                fmt.dateFormat = "yyyy-MM-dd HH:mm:ss"
                if let date = fmt.date(from: dateStr) {
                    startTime = date
                }
            } else if line.hasPrefix("[") && line.contains("]") {
                // Parse [HH:MM:SS] text lines
                if let closeBracket = line.firstIndex(of: "]") {
                    let timeStr = String(line[line.index(after: line.startIndex)..<closeBracket])
                    let text = String(line[line.index(after: closeBracket)...]).trimmingCharacters(in: .whitespaces)

                    let fmt = DateFormatter()
                    fmt.dateFormat = "HH:mm:ss"
                    let timestamp = fmt.date(from: timeStr) ?? startTime

                    segments.append(TranscriptSegment(timestamp: timestamp, text: text, source: .mixed))
                }
            }
        }

        return TranscriptSession(startTime: startTime, endTime: nil, segments: segments)
    }
}
