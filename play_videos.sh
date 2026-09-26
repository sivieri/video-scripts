#!/bin/bash

# Script to play videos with mpv
# Default: current directory (recursive), 100% speed, 80% volume, shuffled, infinite loop
# Usage: ./play_videos.sh [OPTIONS]

set -e  # Exit on error

# Default values
DIRECTORIES=()
INPUT_FILES=()
EXTENSION=""
SPEED=1.0
SHUFFLE=true

# Function to display usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    -d, --dir DIR...   Specify one or more directories (default: current directory, recursive)
    -f, --files FILE...  Specify one or more files to play
    -e, --ext EXT      Specify file extension (e.g., mkv, mp4) without the dot
    -s, --slow         Set playback speed to 85% (default: 100%)
    -n, --no-shuffle   Disable shuffle (default: enabled)
    -h, --help         Show this help message

Examples:
    $0                                    # Play all videos in current dir (recursive), shuffled, 100% speed
    $0 -d /path/to/videos                 # Play all videos in specified directory (recursive)
    $0 -d dir1 dir2 dir3                  # Play all videos in several directories (recursive)
    $0 -f a.mp4 b.mkv                     # Play only the given files
    $0 -d dir1 -f extra.mp4               # Play videos in dir1 plus extra.mp4
    $0 -e mkv                             # Play only .mkv files in current directory (recursive)
    $0 -s                                 # Play at 85% speed
    $0 -d /path/to/videos -e mp4 -n  # Play .mp4 files in directory (recursive), no shuffle
EOF
    exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dir|-f|--files)
            OPT="$1"
            shift
            if [[ $# -eq 0 || "$1" == -* ]]; then
                echo "Error: $OPT requires at least one argument"
                exit 1
            fi
            while [[ $# -gt 0 && "$1" != -* ]]; do
                if [[ "$OPT" == "-d" || "$OPT" == "--dir" ]]; then
                    DIRECTORIES+=("$1")
                else
                    INPUT_FILES+=("$1")
                fi
                shift
            done
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

if [ ${#DIRECTORIES[@]} -eq 0 ] && [ ${#INPUT_FILES[@]} -eq 0 ]; then
    DIRECTORIES=(".")
fi

# Validate directories
for DIRECTORY in "${DIRECTORIES[@]}"; do
    if [ ! -d "$DIRECTORY" ]; then
        echo "Error: Directory '$DIRECTORY' does not exist"
        exit 1
    fi
done

for FILE in "${INPUT_FILES[@]}"; do
    if [ ! -f "$FILE" ]; then
        echo "Error: File '$FILE' does not exist"
        exit 1
    fi
done

# Build the file list
if [ -n "$EXTENSION" ]; then
    # Remove leading dot if present
    EXTENSION="${EXTENSION#.}"
    EXTENSION_PATTERN="$EXTENSION"
else
    EXTENSION_PATTERN="mp4|mkv|avi|mov|webm|flv|wmv|m4v|mpg|mpeg|3gp|ts|m2ts"
fi

FILES=$(
    {
        [ ${#DIRECTORIES[@]} -gt 0 ] && find "${DIRECTORIES[@]}" -type f 2>/dev/null | sort
        printf '%s\n' "${INPUT_FILES[@]}"
    } | grep -iE "\.($EXTENSION_PATTERN)\$" | awk '!seen[$0]++'
)

# Check if any files were found
if [ -z "$FILES" ]; then
    echo "Error: No video files found"
    [ ${#DIRECTORIES[@]} -gt 0 ] && echo "  Directories: ${DIRECTORIES[*]}"
    [ ${#INPUT_FILES[@]} -gt 0 ] && echo "  Files given: ${#INPUT_FILES[@]}"
    [ -n "$EXTENSION" ] && echo "  Extension: .$EXTENSION"
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
[ ${#DIRECTORIES[@]} -gt 0 ] && echo "Directories: ${DIRECTORIES[*]}"
[ ${#INPUT_FILES[@]} -gt 0 ] && echo "Files given: ${#INPUT_FILES[@]}"
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
exec mpv "${MPV_ARGS[@]}"
