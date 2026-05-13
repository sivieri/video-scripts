"""Download tutorial files, detect updates via a per-song manifest."""
from __future__ import annotations

import json
import os
import re
from pathlib import Path
from typing import Optional
from urllib.parse import unquote, urlparse

import requests

from parser import Song, TutorialFile, extract_video_from_player_page

MANIFEST_NAME = ".manifest.json"
_UNSAFE = re.compile(r'[<>:"/\\|?*\x00-\x1f]')


def sanitize(name: str) -> str:
    cleaned = _UNSAFE.sub("_", name).strip().strip(".")
    return cleaned or "_"


def folder_for(song: Song, base: Path) -> Path:
    return base / sanitize(f"{song.author} - {song.title}")


def url_basename(url: str) -> str:
    path = urlparse(url).path
    return unquote(os.path.basename(path))


def _ext(name: str) -> str:
    return os.path.splitext(name)[1].lower()


def _load_manifest(folder: Path) -> dict[str, str]:
    f = folder / MANIFEST_NAME
    if not f.exists():
        return {}
    try:
        return json.loads(f.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}


def _save_manifest(folder: Path, data: dict[str, str]) -> None:
    (folder / MANIFEST_NAME).write_text(
        json.dumps(data, indent=2, sort_keys=True, ensure_ascii=False),
        encoding="utf-8",
    )


def _download(session: requests.Session, url: str, dest: Path) -> None:
    with session.get(url, stream=True, timeout=120) as resp:
        resp.raise_for_status()
        tmp = dest.with_suffix(dest.suffix + ".part")
        with open(tmp, "wb") as fh:
            for chunk in resp.iter_content(chunk_size=64 * 1024):
                if chunk:
                    fh.write(chunk)
        tmp.replace(dest)


def _resolve(session: requests.Session, tf: TutorialFile) -> Optional[str]:
    """Resolve a TutorialFile to a direct download URL (fetching the player page if needed)."""
    if not tf.is_player_page:
        return tf.url
    try:
        resp = session.get(tf.url, timeout=60)
        resp.raise_for_status()
    except requests.RequestException as e:
        print(f"  [WARN] could not fetch player page {tf.url}: {e}")
        return None
    video = extract_video_from_player_page(resp.text)
    if not video:
        print(f"  [WARN] no <video> found on player page {tf.url}")
    return video


def process_song(session: requests.Session, song: Song, base_dir: Path, dry_run: bool = False) -> None:
    folder = folder_for(song, base_dir)
    if not dry_run:
        folder.mkdir(parents=True, exist_ok=True)
    manifest = _load_manifest(folder)
    display = f"{song.author} - {song.title}"
    prefix = "[DRY-RUN] " if dry_run else ""

    for tf in song.files:
        url = _resolve(session, tf)
        if not url:
            continue
        filename = url_basename(url)
        if not filename:
            print(f"  [WARN] cannot derive filename from {url}")
            continue
        key = f"{tf.label}|{_ext(filename)}"
        prev = manifest.get(key)
        dest = folder / filename

        if prev == filename and dest.exists():
            continue  # already up-to-date

        if prev and prev != filename:
            old = folder / prev
            print(f"{prefix}[UPDATED] {display} :: {tf.label} :: {prev} -> {filename}")
            if dry_run:
                continue
            try:
                _download(session, url, dest)
            except requests.RequestException as e:
                print(f"  [ERROR] download failed for {url}: {e}")
                continue
            if old.exists() and old != dest:
                try:
                    old.unlink()
                except OSError as e:
                    print(f"  [WARN] could not remove old file {old}: {e}")
        else:
            print(f"{prefix}[NEW]     {display} :: {tf.label} :: {filename}")
            if dry_run:
                continue
            try:
                _download(session, url, dest)
            except requests.RequestException as e:
                print(f"  [ERROR] download failed for {url}: {e}")
                continue

        manifest[key] = filename
        _save_manifest(folder, manifest)
