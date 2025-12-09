#!/bin/bash

# Script to play videos with mpv
# Default: current directory (recursive), 100% speed, 80% volume, shuffled, infinite loop
# Usage: ./play_videos.sh [OPTIONS]

set -e  # Exit on error

# Default values
DIRECTORY="."
EXTENSION=""
SPEED=1.0
SHUFFLE=true
EXCLUDE_DIRS=()

# Function to display usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    -d, --dir DIR      Specify directory (default: current directory, recursive)
    -x, --exclude DIR  Exclude directory from search (can be repeated)
    -e, --ext EXT      Specify file extension (e.g., mkv, mp4) without the dot
    -s, --slow         Set playback speed to 85% (default: 100%)
    -n, --no-shuffle   Disable shuffle (default: enabled)
    -h, --help         Show this help message

Examples:
    $0                                    # Play all videos in current dir (recursive), shuffled, 100% speed
    $0 -d /path/to/videos                 # Play all videos in specified directory (recursive)
    $0 -x /path/to/exclude                # Play all videos except those in excluded directory
    $0 -x dir1 -x dir2                    # Play all videos excluding multiple directories
    $0 -e mkv                             # Play only .mkv files in current directory (recursive)
    $0 -s                                 # Play at 85% speed
    $0 -d /path/to/videos -e mp4 -n  # Play .mp4 files in directory (recursive), no shuffle
EOF
    exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dir)
            DIRECTORY="$2"
            shift 2
            ;;
        -x|--exclude)
            EXCLUDE_DIRS+=("$2")
            shift 2
            ;;
        -e|--ext)
            EXTENSION="$2"
            shift 2
            ;;
        -s|--slow)
            SPEED=0.85
            shift
            ;;
        -n|--no-shuffle)
            SHUFFLE=false
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Validate directory
if [ ! -d "$DIRECTORY" ]; then
    echo "Error: Directory '$DIRECTORY' does not exist"
    exit 1
fi

# Normalize search directory path
SEARCH_DIR=$(cd "$DIRECTORY" && pwd)

# Build exclude patterns for find command
# find's -path matches the full path from the starting directory
EXCLUDE_PATTERNS=()
for exclude_dir in "${EXCLUDE_DIRS[@]}"; do
    if [[ "$exclude_dir" = /* ]]; then
        # Absolute path - use as-is
        EXCLUDE_PATTERNS+=("$exclude_dir")
    else
        # Relative path - resolve relative to search directory
        EXCLUDE_PATTERNS+=("$SEARCH_DIR/$exclude_dir")
    fi
done

# Build the file list
if [ -n "$EXTENSION" ]; then
    # Remove leading dot if present
    EXTENSION="${EXTENSION#.}"
    # Find files with specific extension (recursive), excluding specified directories
    if [ ${#EXCLUDE_PATTERNS[@]} -gt 0 ]; then
        FIND_ARGS=("$SEARCH_DIR")
        FIND_ARGS+=("(")
        for pattern in "${EXCLUDE_PATTERNS[@]}"; do
            FIND_ARGS+=(-path "$pattern" -prune -o)
        done
        FIND_ARGS+=(-type f -iname "*.$EXTENSION" -print)
        FIND_ARGS+=(")")
        FILES=$(find "${FIND_ARGS[@]}" 2>/dev/null | sort)
    else
        FILES=$(find "$SEARCH_DIR" -type f -iname "*.$EXTENSION" 2>/dev/null | sort)
    fi
else
    # Common video extensions (recursive), excluding specified directories
    if [ ${#EXCLUDE_PATTERNS[@]} -gt 0 ]; then
        FIND_ARGS=("$SEARCH_DIR")
        FIND_ARGS+=("(")
        for pattern in "${EXCLUDE_PATTERNS[@]}"; do
            FIND_ARGS+=(-path "$pattern" -prune -o)
        done
        FIND_ARGS+=(-type f \( \
            -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.avi" -o -iname "*.mov" \
            -o -iname "*.webm" -o -iname "*.flv" -o -iname "*.wmv" -o -iname "*.m4v" \
            -o -iname "*.mpg" -o -iname "*.mpeg" -o -iname "*.3gp" -o -iname "*.ts" \
            -o -iname "*.m2ts" \
        \) -print)
        FIND_ARGS+=(")")
        FILES=$(find "${FIND_ARGS[@]}" 2>/dev/null | sort)
    else
        FILES=$(find "$SEARCH_DIR" -type f \( \
            -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.avi" -o -iname "*.mov" \
            -o -iname "*.webm" -o -iname "*.flv" -o -iname "*.wmv" -o -iname "*.m4v" \
            -o -iname "*.mpg" -o -iname "*.mpeg" -o -iname "*.3gp" -o -iname "*.ts" \
            -o -iname "*.m2ts" \
        \) 2>/dev/null | sort)
    fi
fi

# Check if any files were found
if [ -z "$FILES" ]; then
    echo "Error: No video files found"
    [ -n "$EXTENSION" ] && echo "  Directory: $DIRECTORY" && echo "  Extension: .$EXTENSION" || echo "  Directory: $DIRECTORY"
    exit 1
fi

# Count files
FILE_COUNT=$(echo "$FILES" | wc -l | tr -d ' ')

# Build array to handle filenames with spaces properly
FILE_ARRAY=()
while IFS= read -r line; do
    [ -n "$line" ] && FILE_ARRAY+=("$line")
done <<< "$FILES"

# Display info
echo "Playing videos with mpv..."
echo "Directory: $DIRECTORY"
[ ${#EXCLUDE_DIRS[@]} -gt 0 ] && echo "Excluded: ${EXCLUDE_DIRS[*]}"
[ -n "$EXTENSION" ] && echo "Extension: .$EXTENSION" || echo "Extension: all video formats"
echo "Files found: $FILE_COUNT"
echo "Speed: $(awk "BEGIN {print $SPEED * 100}")%"
echo "Volume: 80% (always)"
echo "Shuffle: $([ "$SHUFFLE" = true ] && echo "enabled" || echo "disabled")"
echo "Infinite loop: enabled (always)"
echo ""

# Build and execute mpv command
MPV_ARGS=("--loop=inf" "--volume=80" "--speed=$SPEED")

# Add shuffle if enabled
if [ "$SHUFFLE" = true ]; then
    MPV_ARGS+=("--shuffle")
fi

# Add files
MPV_ARGS+=("${FILE_ARRAY[@]}")

# Execute mpv
exec mpv.exe "${MPV_ARGS[@]}"
