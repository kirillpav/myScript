import SwiftUI

struct TranscriptWindowView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            // Transcript content
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(appState.liveSegments) { segment in
                            HStack(alignment: .top, spacing: 8) {
                                Text(segment.formattedTimestamp)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 64, alignment: .trailing)

                                Text(segment.text)
                                    .font(.body)
                                    .textSelection(.enabled)
                            }
                            .id(segment.id)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .onChange(of: appState.liveSegments.count) {
                    if let last = appState.liveSegments.last {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            // Bottom toolbar
            HStack {
                StatusIndicatorView(state: appState.modelState)

                if appState.isRecording {
                    Text("\(appState.lastInferenceLatencyMs)ms")
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    Task {
                        if appState.isRecording {
                            await appState.stopRecording()
                        } else {
                            await appState.startRecording()
                        }
                    }
                } label: {
                    Image(systemName: appState.isRecording ? "stop.circle.fill" : "record.circle")
                        .foregroundStyle(appState.isRecording ? .red : .primary)
                }
                .buttonStyle(.plain)
                .disabled(appState.modelState != .ready && !appState.isRecording)

                Button {
                    let text = appState.liveSegments.map(\.displayText).joined(separator: "\n")
                    TranscriptStore.copyToClipboard(text: text)
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.plain)
                .disabled(appState.liveSegments.isEmpty)
                .help("Copy transcript to clipboard")
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .frame(minWidth: 480, minHeight: 360)
    }
}
