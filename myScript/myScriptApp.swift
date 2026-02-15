import SwiftUI

@main
struct myScriptApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environment(appState)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: appState.isRecording ? "waveform.circle.fill" : "waveform.circle")
                    .symbolRenderingMode(.hierarchical)
            }
        }
        .menuBarExtraStyle(.window)

        Window("Transcript", id: "transcript") {
            TranscriptWindowView()
                .environment(appState)
                .task {
                    if appState.modelState == .notLoaded {
                        await appState.loadModel()
                    }
                }
        }
        .defaultSize(width: 600, height: 500)
    }
}
