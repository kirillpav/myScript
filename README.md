# myScript

On-device AI meeting transcription for macOS. Captures microphone and system audio, transcribes speech in real-time using ExecuTorch + Whisper, and displays a live rolling transcript. Zero data leaves the device.

## Prerequisites

- macOS 14+ (Sonoma)
- Xcode 15+
- Python 3.10+
- Apple Silicon Mac (for Metal acceleration)

## Setup

### 1. Export the Whisper model

```bash
./scripts/setup_env.sh
./scripts/export_whisper.sh
./scripts/download_tokenizer.sh
```

This creates the `.pte` model files and tokenizer in `MeetingScribe/MeetingScribe/Resources/Models/`.

### 2. Build in Xcode

Open `MeetingScribe/MeetingScribe.xcodeproj` and build (Cmd+B).

The project uses ExecuTorch via Swift Package Manager. On first build, SPM will fetch the dependency.

### 3. Run

Grant microphone and screen recording permissions when prompted. The app lives in the menu bar.

## Architecture

```
MicrophoneCapture --> AudioMixer --> AudioChunker --> WhisperInferenceEngine
SystemAudioCapture -/   (additive     (5s window,      (mel -> encoder ->
                        mono mix)      1s overlap)       decoder -> text)
```

- **Audio**: AVAudioEngine (mic) + ScreenCaptureKit (system audio)
- **Inference**: ExecuTorch with Metal (MPS) backend
- **Model**: Whisper Small (~250MB)
- **UI**: SwiftUI MenuBarExtra + transcript window
