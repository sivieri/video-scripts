"""Scrape and mirror Rockin'1000 tutorial files for an event."""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

import requests

from parser import TUTORIAL_URL, parse_tutorial_page
from downloader import process_song
from config import CONFIG_PATH, resolve_cookie


def build_session(cookie: str) -> requests.Session:
    s = requests.Session()
    s.headers.update({
        "Cookie": cookie,
        "User-Agent": "Mozilla/5.0 (rockin1000-scraper)",
    })
    return s


def main() -> int:
    ap = argparse.ArgumentParser(description="Mirror Rockin'1000 event tutorials.")
    ap.add_argument("--event-id", "-e", required=True, help="numeric event id (idEvento)")
    ap.add_argument("--cookie", help=f"full Cookie header value (saved to {CONFIG_PATH} and reused if omitted)")
    ap.add_argument("--output", "-o", default=".", help="output folder (default: current dir)")
    ap.add_argument("--dry-run", action="store_true", help="show what would be downloaded/updated without writing files")
    args = ap.parse_args()

    cookie = resolve_cookie(args.cookie)
    if not cookie:
        print(f"[ERROR] no cookie provided and none saved at {CONFIG_PATH}.", file=sys.stderr)
        return 1

    out = Path(args.output).expanduser().resolve()
    if not args.dry_run:
        out.mkdir(parents=True, exist_ok=True)

    session = build_session(cookie)
    url = TUTORIAL_URL.format(event_id=args.event_id)

    print(f"Fetching tutorial index: {url}")
    try:
        resp = session.get(url, timeout=60)
        resp.raise_for_status()
    except requests.RequestException as e:
        print(f"[ERROR] failed to fetch tutorial index: {e}", file=sys.stderr)
        return 1

    songs = parse_tutorial_page(resp.text)
    if not songs:
        print("[ERROR] no songs found; cookie may be invalid or page layout changed.", file=sys.stderr)
        return 2

    mode = "Previewing" if args.dry_run else "Saving to"
    print(f"Found {len(songs)} song(s). {mode} {out}\n")
    for song in songs:
        process_song(session, song, out, dry_run=args.dry_run)

    print("\nDone.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
