#!/bin/bash

# This script moves all files from immediate subdirectories to the current directory.
# It assumes a single level of depth as requested.

# Enable dotglob to include hidden files in the expansion
# Enable nullglob to handle empty directories gracefully
shopt -s dotglob nullglob

echo "Starting to move files..."

# Loop through all directories in the current folder
for dir in */; do
    # Check if it is a directory
    if [ -d "$dir" ]; then
        echo "Processing directory: $dir"
        
        # Loop through all files in the subdirectory
        for file in "$dir"*; do
            # Check if it is a file (not a subdirectory)
            if [ -f "$file" ]; then
                # Move the file to the current directory
                # -n: Do not overwrite an existing file
                # -v: Verbose (show what is being done)
                mv -n -v "$file" .
            fi
        done
    fi
done

echo "Operation complete."
