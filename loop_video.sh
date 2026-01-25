#!/bin/bash

# Script to loop a single video N times using ffmpeg
# Usage: ./loop_video.sh <input_video> <n_times> [output_video]
#
# Notes:
# - ffmpeg's -stream_loop value is "additional loops", so:
#   n_times=1 => -stream_loop 0 (play once)
#   n_times=2 => -stream_loop 1 (play twice), etc.

set -e  # Exit on error

# Help / usage
if [ "$1" = "-h" ] || [ "$1" = "--help" ] || [ $# -eq 0 ]; then
  echo "Usage: $0 <input_video> <n_times> [output_video]"
  echo "Example: $0 input.mp4 3"
  echo "Example: $0 input.mp4 3 custom_output.mp4"
  exit 0
fi

if [ $# -ne 2 ] && [ $# -ne 3 ]; then
  echo "Error: Expected 2 or 3 arguments"
  echo "Usage: $0 <input_video> <n_times> [output_video]"
  exit 1
fi

INPUT_FILE="$1"
N_TIMES="$2"
OUTPUT_FILE="${3:-}"

# Check ffmpeg is available
if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "Error: ffmpeg not found in PATH"
  exit 1
fi

# Check input exists
if [ ! -f "$INPUT_FILE" ]; then
  echo "Error: Input file not found: $INPUT_FILE"
  exit 1
fi

# Validate n_times is an integer >= 1
if ! [[ "$N_TIMES" =~ ^[0-9]+$ ]]; then
  echo "Error: n_times must be a positive integer (>= 1)"
  exit 1
fi
if [ "$N_TIMES" -lt 1 ]; then
  echo "Error: n_times must be >= 1"
  exit 1
fi

LOOP_COUNT=$((N_TIMES - 1))

if [ -z "$OUTPUT_FILE" ]; then
  dir="$(dirname "$INPUT_FILE")"
  filename="$(basename "$INPUT_FILE")"

  if [[ "$filename" == *.* ]]; then
    base="${filename%.*}"
    ext="${filename##*.}"
    OUTPUT_FILE="${dir}/${base}_loop${N_TIMES}.${ext}"
  else
    OUTPUT_FILE="${dir}/${filename}_loop${N_TIMES}"
  fi
fi

echo "Looping '$INPUT_FILE' $N_TIMES time(s) -> '$OUTPUT_FILE' (ffmpeg -stream_loop $LOOP_COUNT)"

# Loop without re-encoding
ffmpeg -stream_loop "$LOOP_COUNT" -i "$INPUT_FILE" -c copy "$OUTPUT_FILE"

echo "Done! Created: $OUTPUT_FILE"
