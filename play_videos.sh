#!/bin/bash

# Script to play videos with mpv
# Default: current directory, 100% speed, shuffled, infinite loop
# Usage: ./play_videos.sh [OPTIONS]

set -e  # Exit on error

# Default values
DIRECTORY="."
EXTENSION=""
SPEED=1.0
SHUFFLE=true

# Function to display usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    -d, --dir DIR      Specify directory (default: current directory)
    -e, --ext EXT      Specify file extension (e.g., mkv, mp4) without the dot
    -s, --slow         Set playback speed to 85% (default: 100%)
    -n, --no-shuffle   Disable shuffle (default: enabled)
    -h, --help         Show this help message

Examples:
    $0                                    # Play all videos in current dir, shuffled, 100% speed
    $0 -d /path/to/videos                 # Play all videos in specified directory
    $0 -e mkv                             # Play only .mkv files in current directory
    $0 -s                                 # Play at 85% speed
    $0 -d /path/to/videos -e mp4 -n  # Play .mp4 files in directory, no shuffle
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

# Build the file list
if [ -n "$EXTENSION" ]; then
    # Remove leading dot if present
    EXTENSION="${EXTENSION#.}"
    # Find files with specific extension
    FILES=$(find "$DIRECTORY" -maxdepth 1 -type f -iname "*.$EXTENSION" 2>/dev/null | sort)
else
    # Common video extensions
    FILES=$(find "$DIRECTORY" -maxdepth 1 -type f \( \
        -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.avi" -o -iname "*.mov" \
        -o -iname "*.webm" -o -iname "*.flv" -o -iname "*.wmv" -o -iname "*.m4v" \
        -o -iname "*.mpg" -o -iname "*.mpeg" -o -iname "*.3gp" -o -iname "*.ts" \
        -o -iname "*.m2ts" \
    \) 2>/dev/null | sort)
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
[ -n "$EXTENSION" ] && echo "Extension: .$EXTENSION" || echo "Extension: all video formats"
echo "Files found: $FILE_COUNT"
echo "Speed: $((SPEED * 100))%"
echo "Shuffle: $([ "$SHUFFLE" = true ] && echo "enabled" || echo "disabled")"
echo "Infinite loop: enabled (always)"
echo ""

# Build and execute mpv command
MPV_ARGS=("--loop=inf" "--speed=$SPEED")

# Add shuffle if enabled
if [ "$SHUFFLE" = true ]; then
    MPV_ARGS+=("--shuffle")
fi

# Add files
MPV_ARGS+=("${FILE_ARRAY[@]}")

# Execute mpv
exec mpv.exe "${MPV_ARGS[@]}"

