"""Generate an M3U playlist of all mp3 tutorial URLs for an event."""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

import requests

from parser import TUTORIAL_URL, parse_tutorial_page
from downloader import url_basename
from config import CONFIG_PATH, resolve_cookie


def main() -> int:
    ap = argparse.ArgumentParser(description="Write an M3U playlist of Rockin'1000 mp3 tutorial URLs.")
    ap.add_argument("--event-id", "-e", required=True, help="numeric event id (idEvento)")
    ap.add_argument("--output", "-o", required=True, help="output .m3u file (overwritten if it exists)")
    ap.add_argument("--cookie", help=f"full Cookie header value (saved to {CONFIG_PATH} and reused if omitted)")
    args = ap.parse_args()

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
    lines = ["#EXTM3U"]
    count = 0
    for song in songs:
        for tf in song.files:
            if tf.is_player_page:
                continue
            if url_basename(tf.url).lower().endswith(".mp3"):
                title = f"{song.author} - {song.title}"
                lines.append(f"#EXTINF:-1,{title}")
                lines.append(tf.url)
                count += 1

    if count == 0:
        print("[ERROR] no mp3 tutorials found.", file=sys.stderr)
        return 2

    out = Path(args.output).expanduser().resolve()
    out.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Wrote {count} track(s) to {out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
