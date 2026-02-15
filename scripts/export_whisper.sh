#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="$PROJECT_DIR/myScript/Resources/Models"

cd "$PROJECT_DIR"
source .venv/bin/activate

mkdir -p "$OUTPUT_DIR"

# Use whisper-tiny for fast iteration; swap to whisper-small for better quality
MODEL="openai/whisper-tiny"

echo "Exporting $MODEL to ExecuTorch format (xnnpack backend)..."
optimum-cli export executorch \
  --model "$MODEL" \
  --task automatic-speech-recognition \
  --recipe xnnpack \
  --output_dir "$OUTPUT_DIR/"

echo ""
echo "Exporting mel spectrogram preprocessor..."
python -m executorch.extension.audio.mel_spectrogram \
  --feature_size 80 \
  --sampling_rate 16000 \
  --hop_length 160 \
  --chunk_length 30 \
  --n_fft 400 \
  --max_audio_len 300 \
  --stack_output \
  --output_file "$OUTPUT_DIR/whisper_preprocessor.pte"

echo ""
echo "Done. Model files exported to $OUTPUT_DIR"
ls -lh "$OUTPUT_DIR"/*.pte
