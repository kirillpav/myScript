#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="$PROJECT_DIR/myScript/Resources/Models"

mkdir -p "$OUTPUT_DIR"

echo "Downloading Whisper tokenizer..."
curl -L "https://huggingface.co/openai/whisper-small/resolve/main/tokenizer.json" \
  -o "$OUTPUT_DIR/tokenizer.json"

echo "Done. Tokenizer saved to $OUTPUT_DIR/tokenizer.json"
ls -lh "$OUTPUT_DIR/tokenizer.json"
