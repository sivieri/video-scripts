#!/bin/bash

# Script to concatenate videos using ffmpeg's concat demuxer
# Usage: ./concatenate_videos.sh <output_filename>

set -e  # Exit on error

# Check if output filename is provided
if [ $# -eq 0 ]; then
    echo "Error: Output filename is required"
    echo "Usage: $0 <output_filename>"
    exit 1
fi

OUTPUT_FILE="$1"
TEMP_LIST="concat_list_$$.txt"  # Use process ID to avoid conflicts

# Common video file extensions
VIDEO_EXTENSIONS=("mp4" "mkv" "avi" "mov" "webm" "flv" "wmv" "m4v" "mpg" "mpeg" "3gp" "ts" "m2ts")

# Build find conditions
find_conditions=()
for ext in "${VIDEO_EXTENSIONS[@]}"; do
    [ ${#find_conditions[@]} -gt 0 ] && find_conditions+=(-o)
    find_conditions+=(-iname "*.${ext}")
done

# Find all video files in current directory, sorted lexicographically
VIDEO_FILES=$(find . -maxdepth 1 -type f \( "${find_conditions[@]}" \) | sort)

# Check if any video files were found
if [ -z "$VIDEO_FILES" ]; then
    echo "Error: No video files found in current directory"
    exit 1
fi

# Count video files
FILE_COUNT=$(echo "$VIDEO_FILES" | wc -l | tr -d ' ')
echo "Found $FILE_COUNT video file(s) to concatenate"

# Create the list file for ffmpeg concat demuxer
echo "Creating temporary list file..."
while IFS= read -r file; do
    # Use relative path (strip ./ prefix if present)
    rel_path="${file#./}"
    echo "file '$rel_path'" >> "$TEMP_LIST"
done <<< "$VIDEO_FILES"

# Execute ffmpeg concatenation
echo "Concatenating videos..."

# Check if ffmpeg succeeded
if ffmpeg -f concat -safe 0 -i "$TEMP_LIST" -c copy "$OUTPUT_FILE"; then
    echo "Successfully created: $OUTPUT_FILE"
else
    echo "Error: ffmpeg failed"
    rm -f "$TEMP_LIST"
    exit 1
fi

# Clean up temporary list file
rm -f "$TEMP_LIST"
echo "Done!"
