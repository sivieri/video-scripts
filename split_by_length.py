#!/usr/bin/env python3
"""
Split a markdown file into multiple parts based on a character limit.
The split occurs at the previous newline to avoid cutting sentences.
"""

import sys
from pathlib import Path

def write_part(out_dir, base_name, ext, part_num, lines):
    """Helper function to write a chunk of lines to a new file."""
    out_name = f"{base_name}_part{part_num}{ext}"
    out_path = out_dir / out_name
    
    with open(out_path, 'w', encoding='utf-8') as f:
        f.writelines(lines)
        
    char_count = sum(len(line) for line in lines)
    print(f"Created: {out_name} ({char_count} characters)")

def split_file(input_file, char_limit):
    path = Path(input_file)
    
    if not path.is_file():
        print(f"Error: File '{input_file}' not found.")
        sys.exit(1)

    with open(path, 'r', encoding='utf-8') as f:
        # Read all lines. By keeping newlines intact, we ensure safe splitting.
        lines = f.readlines()

    base_name = path.stem
    ext = path.suffix
    out_dir = path.parent

    current_part = []
    current_length = 0
    part_num = 1

    for line in lines:
        line_length = len(line)
        
        # If adding the next line exceeds the limit and we already have content,
        # we write the current content to a file and start fresh.
        if current_length + line_length > char_limit and current_length > 0:
            write_part(out_dir, base_name, ext, part_num, current_part)
            part_num += 1
            current_part = [line]
            current_length = line_length
        else:
            current_part.append(line)
            current_length += line_length
            
    # Don't forget to write out the final chunk if it has content
    if current_part:
        write_part(out_dir, base_name, ext, part_num, current_part)

    print(f"\nSuccessfully split '{path.name}' into {part_num} part(s).")

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print("Usage: python split_by_length.py <input_file> <char_limit>")
        sys.exit(1)
        
    try:
        limit = int(sys.argv[2])
        if limit <= 0:
            raise ValueError
    except ValueError:
        print("Error: char_limit must be a positive integer.")
        sys.exit(1)
        
    split_file(sys.argv[1], limit)