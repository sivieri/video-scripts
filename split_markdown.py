#!/usr/bin/env python3
"""
Split a markdown file into a folder structure.

With --levels 2,3 (default):
- Level 1 heading: ignored
- Level 2 headings: become folders
- Level 3 headings: become files within their parent level 2 folder

With --levels 1,2:
- Level 1 headings: become folders
- Level 2 headings: become files within their parent level 1 folder
"""

import argparse
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


def parse_markdown(md_file, folder_level, file_level):
    """Parse markdown file and return structured data."""
    with open(md_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    folder_prefix = '#' * folder_level + ' '
    file_prefix = '#' * file_level + ' '

    structure = []
    current_folder = None
    current_file = None
    current_content = []

    for line in lines:
        if line.startswith(folder_prefix) and not line.startswith(folder_prefix + '#'):
            # Save previous file section if exists
            if current_file and current_folder:
                structure.append({
                    'folder': current_folder,
                    'file': current_file,
                    'content': ''.join(current_content).strip()
                })

            current_folder = line[len(folder_prefix):].strip()
            current_file = None
            current_content = []

        elif line.startswith(file_prefix) and not line.startswith(file_prefix + '#'):
            # Save previous file section if exists
            if current_file and current_folder:
                structure.append({
                    'folder': current_folder,
                    'file': current_file,
                    'content': ''.join(current_content).strip()
                })

            current_file = line[len(file_prefix):].strip()
            current_content = []

        else:
            if current_file and current_folder:
                current_content.append(line)

    # Don't forget the last section
    if current_file and current_folder:
        structure.append({
            'folder': current_folder,
            'file': current_file,
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
        folder_name = sanitize_filename(item['folder'])
        folder_path = output_dir / folder_name
        folder_path.mkdir(parents=True, exist_ok=True)

        level3_filename = sanitize_filename(item['file'])
        # Add .md extension if not present
        if not level3_filename.endswith('.md'):
            level3_filename += '.md'
        
        file_path = folder_path / level3_filename
        
        # Write content to file
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(item['content'])
        
        print(f"Created: {file_path}")


def main():
    parser = argparse.ArgumentParser(
        description='Split a markdown file into a folder/file structure based on heading levels.'
    )
    parser.add_argument('markdown_file', help='Path to the markdown file to split')
    parser.add_argument('output_directory', nargs='?', default=None,
                        help='Directory to create structure in (default: current directory)')
    parser.add_argument('--level', type=int, choices=[1, 2], default=2,
                        help='Heading level to use as folders; files use the next level (default: 2)')

    args = parser.parse_args()

    md_file = Path(args.markdown_file)
    if not md_file.exists():
        print(f"Error: File '{md_file}' not found.")
        sys.exit(1)

    folder_level = args.level
    file_level = folder_level + 1

    print(f"Parsing markdown file: {md_file}")
    print(f"Using level {folder_level} headings as folders, level {file_level} headings as files")
    structure = parse_markdown(md_file, folder_level, file_level)

    print(f"\nFound {len(structure)} file sections across {len(set(s['folder'] for s in structure))} folders")
    print(f"Creating folder structure...\n")

    create_structure(structure, args.output_directory)

    print(f"\nDone! Structure created in: {args.output_directory or Path.cwd()}")


if __name__ == '__main__':
    main()

