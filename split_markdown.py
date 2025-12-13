#!/usr/bin/env python3
"""
Split a markdown file into a folder structure:
- Level 1 heading: ignored
- Level 2 headings: become folders
- Level 3 headings: become files within their parent level 2 folder
"""

import os
import re
import sys
from pathlib import Path


def sanitize_filename(name):
    """Convert a heading title to a filesystem-safe filename."""
    # Remove or replace invalid characters
    name = re.sub(r'[<>:"/\\|?*]', '', name)
    # Replace multiple spaces with single space
    name = re.sub(r'\s+', ' ', name)
    # Strip leading/trailing spaces and dots
    name = name.strip(' .')
    # Limit length (filesystem dependent, but 255 is safe)
    if len(name) > 200:
        name = name[:200]
    return name


def parse_markdown(md_file):
    """Parse markdown file and return structured data."""
    with open(md_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    structure = []
    current_level2 = None
    current_level3 = None
    current_content = []
    
    for line in lines:
        # Check for level 1 heading (ignore it)
        if line.startswith('# '):
            continue
        
        # Check for level 2 heading
        elif line.startswith('## '):
            # Save previous level 3 if exists
            if current_level3 and current_level2:
                structure.append({
                    'level2': current_level2,
                    'level3': current_level3,
                    'content': ''.join(current_content).strip()
                })
            
            # Start new level 2
            current_level2 = line[3:].strip()
            current_level3 = None
            current_content = []
        
        # Check for level 3 heading
        elif line.startswith('### '):
            # Save previous level 3 if exists
            if current_level3 and current_level2:
                structure.append({
                    'level2': current_level2,
                    'level3': current_level3,
                    'content': ''.join(current_content).strip()
                })
            
            # Start new level 3
            current_level3 = line[4:].strip()
            current_content = []
        
        # Regular content line
        else:
            if current_level3 and current_level2:
                current_content.append(line)
    
    # Don't forget the last level 3
    if current_level3 and current_level2:
        structure.append({
            'level2': current_level2,
            'level3': current_level3,
            'content': ''.join(current_content).strip()
        })
    
    return structure


def create_structure(structure, output_dir=None):
    """Create folder and file structure from parsed data."""
    if output_dir is None:
        output_dir = Path.cwd()
    else:
        output_dir = Path(output_dir)
    
    output_dir.mkdir(parents=True, exist_ok=True)
    
    for item in structure:
        # Create level 2 folder
        level2_folder = sanitize_filename(item['level2'])
        folder_path = output_dir / level2_folder
        folder_path.mkdir(parents=True, exist_ok=True)
        
        # Create level 3 file
        level3_filename = sanitize_filename(item['level3'])
        # Add .md extension if not present
        if not level3_filename.endswith('.md'):
            level3_filename += '.md'
        
        file_path = folder_path / level3_filename
        
        # Write content to file
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(item['content'])
        
        print(f"Created: {file_path}")


def main():
    if len(sys.argv) < 2:
        print("Usage: split_markdown.py <markdown_file> [output_directory]")
        print("  markdown_file: Path to the markdown file to split")
        print("  output_directory: Optional directory to create structure in (default: current directory)")
        sys.exit(1)
    
    md_file = Path(sys.argv[1])
    if not md_file.exists():
        print(f"Error: File '{md_file}' not found.")
        sys.exit(1)
    
    output_dir = sys.argv[2] if len(sys.argv) > 2 else None
    
    print(f"Parsing markdown file: {md_file}")
    structure = parse_markdown(md_file)
    
    print(f"\nFound {len(structure)} level 3 sections across {len(set(s['level2'] for s in structure))} level 2 sections")
    print(f"Creating folder structure...\n")
    
    create_structure(structure, output_dir)
    
    print(f"\nDone! Structure created in: {output_dir or Path.cwd()}")


if __name__ == '__main__':
    main()

