import Foundation

struct TranscriptSession: Identifiable, Sendable {
    let id = UUID()
    let startTime: Date
    var endTime: Date?
    var segments: [TranscriptSegment]

    var title: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return "Meeting \(formatter.string(from: startTime))"
    }

    var duration: TimeInterval? {
        guard let endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }

    var fullText: String {
        segments.map(\.displayText).joined(separator: "\n")
    }

    var markdownContent: String {
        var lines = [String]()
        lines.append("# \(title)")
        lines.append("")

        let timeFmt = DateFormatter()
        timeFmt.dateFormat = "yyyy-MM-dd HH:mm:ss"
        lines.append("**Start:** \(timeFmt.string(from: startTime))")
        if let endTime {
            lines.append("**End:** \(timeFmt.string(from: endTime))")
        }
        lines.append("")
        lines.append("---")
        lines.append("")

        for segment in segments {
            lines.append(segment.displayText)
        }

        lines.append("")
        return lines.joined(separator: "\n")
    }
}
