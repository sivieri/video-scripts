#!/bin/bash

# Recursively find video files by duration: either top N longest, or all >= min length.
# Usage:
#   Top N longest:  $0 <folder> --top <N>
#   Min length:     $0 <folder> --min-seconds <seconds>

# Common video file extensions (case-insensitive)
VIDEO_EXTENSIONS=("mp4" "avi" "mov" "mkv" "flv" "wmv" "webm" "m4v" "3gp" "ogv" "ts" "mts" "m2ts")

usage() {
    echo "Usage:"
    echo "  $0 <folder> --top <N>              List top N longest videos"
    echo "  $0 <folder> --min-seconds <secs>   List all videos with duration >= <secs> seconds"
    echo ""
    echo "Examples:"
    echo "  $0 ~/Videos --top 10"
    echo "  $0 ~/Videos --min-seconds 3600    # videos at least 1 hour"
    exit 1
}

# Check arguments
if [ $# -lt 3 ]; then
    usage
fi

SEARCH_DIR="$1"
MODE="$2"
VALUE="$3"

if [ ! -d "$SEARCH_DIR" ]; then
    echo "Error: '$SEARCH_DIR' is not a directory or does not exist."
    exit 1
fi

case "$MODE" in
    --top)
        if ! [[ "$VALUE" =~ ^[0-9]+$ ]] || [ "$VALUE" -lt 1 ]; then
            echo "Error: N for --top must be a positive integer."
            exit 1
        fi
        TOP_N="$VALUE"
        USE_TOP=1
        ;;
    --min-seconds)
        if ! [[ "$VALUE" =~ ^[0-9]+\.?[0-9]*$ ]]; then
            echo "Error: --min-seconds must be a number (seconds)."
            exit 1
        fi
        MIN_SECONDS="$VALUE"
        USE_TOP=0
        ;;
    *)
        echo "Error: expected --top or --min-seconds, got '$MODE'."
        usage
        ;;
esac

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

TAB=$'\t'
format_duration() {
    local d="$1"
    local secs=${d%.*}
    printf '%02d:%02d:%02d' $((secs / 3600)) $(((secs % 3600) / 60)) $((secs % 60))
}

if [ "$USE_TOP" -eq 1 ]; then
    echo ""
    echo "Top $TOP_N longest video(s):"
    echo "------------------------"
    sort -t "$TAB" -k1 -rn "$tmp" | head -n "$TOP_N" | while IFS=$'\t' read -r duration path; do
        printf "%s  %s (%s)\n" "$path" "$duration" "$(format_duration "$duration")"
    done
else
    # Filter by min duration, sort by duration descending
    filtered=$(mktemp)
    trap 'rm -f "$tmp" "$filtered"' EXIT
    awk -v min="$MIN_SECONDS" -F"\t" '$1 >= min' "$tmp" | sort -t "$TAB" -k1 -rn > "$filtered"
    count=$(wc -l < "$filtered" | tr -d ' ')
    echo ""
    if [ "$count" -eq 0 ]; then
        echo "No videos found with duration >= ${MIN_SECONDS} seconds."
    else
        echo "Videos with duration >= ${MIN_SECONDS} seconds (${count} found):"
        echo "------------------------"
        while IFS=$'\t' read -r duration path; do
            printf "%s  %s (%s)\n" "$path" "$duration" "$(format_duration "$duration")"
        done < "$filtered"
    fi
fi
