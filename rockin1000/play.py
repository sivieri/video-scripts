"""Shuffle and play all mp3 tutorials of an event via mpv, streaming from URLs."""
from __future__ import annotations

import argparse
import random
import shutil
import subprocess
import sys

import requests

from parser import TUTORIAL_URL, parse_tutorial_page
from downloader import url_basename
from config import CONFIG_PATH, resolve_cookie


def main() -> int:
    ap = argparse.ArgumentParser(description="Shuffle-play Rockin'1000 mp3 tutorials with mpv.")
    ap.add_argument("--event-id", "-e", required=True, help="numeric event id (idEvento)")
    ap.add_argument("--cookie", help=f"full Cookie header value (saved to {CONFIG_PATH} and reused if omitted)")
    ap.add_argument("--seed", type=int, default=None, help="optional shuffle seed for reproducible order")
    ap.add_argument("--silence", type=float, default=5.0, help="seconds of silence between tracks (default: 5)")
    ap.add_argument("--dry-run", action="store_true", help="print the shuffled playlist without launching mpv")
    args = ap.parse_args()

    if not args.dry_run and not shutil.which("mpv"):
        print("[ERROR] mpv not found in PATH.", file=sys.stderr)
        return 1

    cookie = resolve_cookie(args.cookie)
    if not cookie:
        print(f"[ERROR] no cookie provided and none saved at {CONFIG_PATH}.", file=sys.stderr)
        return 1

    session = requests.Session()
    session.headers.update({
        "Cookie": cookie,
        "User-Agent": "Mozilla/5.0 (rockin1000-scraper)",
    })

    url = TUTORIAL_URL.format(event_id=args.event_id)
    print(f"Fetching tutorial index: {url}")
    try:
        resp = session.get(url, timeout=60)
        resp.raise_for_status()
    except requests.RequestException as e:
        print(f"[ERROR] failed to fetch tutorial index: {e}", file=sys.stderr)
        return 1

    songs = parse_tutorial_page(resp.text)
    tracks: list[tuple[str, str, str]] = []  # (author, title, url)
    for song in songs:
        for tf in song.files:
            if tf.is_player_page:
                continue
            if url_basename(tf.url).lower().endswith(".mp3"):
                tracks.append((song.author, song.title, tf.url))

    if not tracks:
        print("[ERROR] no mp3 tutorials found.", file=sys.stderr)
        return 2

    if args.seed is not None:
        random.seed(args.seed)
    random.shuffle(tracks)

    print(f"\nPlaylist ({len(tracks)} track(s)):")
    for i, (author, title, _) in enumerate(tracks, 1):
        print(f"  {i:2d}. {author} - {title}")
    print()

    if args.dry_run:
        return 0

    urls = [t[2] for t in tracks]
    cmd = [
        "mpv",
        "--no-video",
        f"--http-header-fields=Cookie: {cookie}",
    ]
    if args.silence > 0:
        cmd.append(f"--af=lavfi=[apad=pad_dur={args.silence}]")
    cmd.extend(urls)
    try:
        return subprocess.call(cmd)
    except KeyboardInterrupt:
        return 130


if __name__ == "__main__":
    raise SystemExit(main())
