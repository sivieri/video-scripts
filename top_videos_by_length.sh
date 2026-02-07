#!/bin/bash

# Recursively find the top N video files by duration in a folder.
# Usage: ./top_videos_by_length.sh <folder> <N>
# Example: ./top_videos_by_length.sh /path/to/videos 10

# Common video file extensions (case-insensitive)
VIDEO_EXTENSIONS=("mp4" "avi" "mov" "mkv" "flv" "wmv" "webm" "m4v" "3gp" "ogv" "ts" "mts" "m2ts")

# Check arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <folder> <N>"
    echo "  folder  - Directory to search recursively for video files"
    echo "  N       - Number of longest videos to list (e.g. 10)"
    echo ""
    echo "Example: $0 ~/Videos 20"
    exit 1
fi

SEARCH_DIR="$1"
N="$2"

if [ ! -d "$SEARCH_DIR" ]; then
    echo "Error: '$SEARCH_DIR' is not a directory or does not exist."
    exit 1
fi

if ! [[ "$N" =~ ^[0-9]+$ ]] || [ "$N" -lt 1 ]; then
    echo "Error: N must be a positive integer."
    exit 1
fi

# Check if ffprobe is available
if ! command -v ffprobe &> /dev/null; then
    echo "Error: ffprobe is not installed or not in PATH."
    echo "Please install ffmpeg (which includes ffprobe)."
    exit 1
fi

# Build find conditions: -iname "*.mp4" -o -iname "*.avi" ...
find_conditions=()
for ext in "${VIDEO_EXTENSIONS[@]}"; do
    [ ${#find_conditions[@]} -gt 0 ] && find_conditions+=(-o)
    find_conditions+=(-iname "*.${ext}")
done

# Temporary file for duration + path (duration in seconds, tab, path)
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

echo "Scanning videos in $SEARCH_DIR (this may take a while)..." >&2

# Find all video files and get duration for each
while IFS= read -r -d '' file; do
    duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null)
    if [ -n "$duration" ] && [ "$duration" != "N/A" ]; then
        printf "%s\t%s\n" "$duration" "$file" >> "$tmp"
    fi
done < <(find "$SEARCH_DIR" -type f \( "${find_conditions[@]}" \) -print0 2>/dev/null)

if [ ! -s "$tmp" ]; then
    echo "No video files found in $SEARCH_DIR (or no valid durations)."
    exit 0
fi

# Sort numerically by duration descending, take top N
echo ""
echo "Top $N longest video(s):"
echo "------------------------"
TAB=$'\t'
sort -t "$TAB" -k1 -rn "$tmp" | head -n "$N" | while IFS=$'\t' read -r duration path; do
    # Convert seconds to HH:MM:SS
    hours=$(printf '%02d' $((${duration%.*} / 3600)))
    mins=$(printf '%02d' $(((${duration%.*} % 3600) / 60)))
    secs=$(printf '%02d' $((${duration%.*} % 60)))
    printf "%s  %s (%s:%s:%s)\n" "$path" "$duration" "$hours" "$mins" "$secs"
done
