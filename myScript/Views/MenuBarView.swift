import SwiftUI

struct MenuBarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Status
            HStack {
                StatusIndicatorView(state: appState.modelState)
                Spacer()
                if appState.isRecording {
                    Text("\(appState.lastInferenceLatencyMs)ms")
                        .font(.caption2)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            Divider()

            // Record toggle
            Button {
                Task {
                    if appState.isRecording {
                        await appState.stopRecording()
                    } else {
                        await appState.startRecording()
                    }
                }
            } label: {
                HStack {
                    Image(systemName: appState.isRecording ? "stop.circle.fill" : "record.circle")
                        .foregroundStyle(appState.isRecording ? .red : .primary)
                    Text(appState.isRecording ? "Stop Recording" : "Start Recording")
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .disabled(appState.modelState != .ready && !appState.isRecording)

            Divider()

            // Open transcript window
            Button {
                openTranscriptWindow()
            } label: {
                HStack {
                    Image(systemName: "doc.text")
                    Text("Open Transcript")
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)

            // Recent sessions
            if !appState.recentSessions.isEmpty {
                Divider()
                Text("Recent")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)

                ForEach(appState.recentSessions.prefix(3)) { session in
                    Text(session.title)
                        .font(.caption)
                        .padding(.horizontal, 12)
                }
            }

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
        .frame(width: 240)
    }

    private func openTranscriptWindow() {
        NSApp.sendAction(Selector(("showTranscriptWindow:")), to: nil, from: nil)
        // Alternative: use OpenWindowAction environment
        if let window = NSApp.windows.first(where: { $0.title == "Transcript" }) {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
