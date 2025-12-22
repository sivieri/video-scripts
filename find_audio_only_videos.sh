#!/bin/bash

# Script to find video files (by extension) that contain only audio, no video stream

# Common video file extensions
VIDEO_EXTENSIONS=("mp4" "avi" "mov" "mkv" "flv" "wmv" "webm" "m4v" "3gp" "ogv" "ts" "mts" "m2ts")

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if ffprobe is available
if ! command -v ffprobe &> /dev/null; then
    echo -e "${RED}Error: ffprobe is not installed or not in PATH${NC}"
    echo "Please install ffmpeg (which includes ffprobe)"
    exit 1
fi

found_count=0

echo "Scanning for video files with no video stream..."
echo ""

# Find all files with video extensions in current directory
for ext in "${VIDEO_EXTENSIONS[@]}"; do
    # Case-insensitive search for files with this extension
    while IFS= read -r file; do
        # Get the filename without path
        filename=$(basename "$file")
        
        # Check if file has a video stream
        has_video=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_type -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null)
        
        # Check if file has an audio stream
        has_audio=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_type -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null)
        
        # If no video stream but has audio stream, report it
        if [ -z "$has_video" ] && [ -n "$has_audio" ]; then
            echo -e "${YELLOW}Found:${NC} $filename (audio-only, no video stream)"
            ((found_count++))
        fi
    done < <(find . -maxdepth 1 -type f -iname "*.${ext}")
done

echo ""
if [ $found_count -eq 0 ]; then
    echo -e "${GREEN}No audio-only video files found.${NC}"
else
    echo -e "${RED}Total found: $found_count file(s)${NC}"
fi

