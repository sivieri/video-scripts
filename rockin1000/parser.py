"""Parse Rockin'1000 tutorial pages."""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Optional
from urllib.parse import urljoin

from bs4 import BeautifulSoup, Tag

BASE_URL = "https://legacy-app.rockin1000.com/d/"
TUTORIAL_URL = BASE_URL + "tutorial.php?idEvento={event_id}&lang=en"


@dataclass
class TutorialFile:
    label: str          # e.g. "Click Track - Full", "Video Tutorial LEFT"
    url: str            # direct download URL (mp3/pdf/mp4) or player page URL
    is_player_page: bool = False  # if True, url points to tutorialsAll_player.php and must be resolved


@dataclass
class Song:
    title: str
    author: str
    files: list[TutorialFile] = field(default_factory=list)


def _clean(text: str) -> str:
    return " ".join(text.split())


def parse_tutorial_page(html: str) -> list[Song]:
    """Parse the main tutorial page HTML and return a list of songs with their files."""
    soup = BeautifulSoup(html, "html.parser")
    songs: list[Song] = []

    # Each song is a "row bg-light m-0" containing a header (h4+p) and a "collapse" body with rows of files.
    for song_row in soup.select("div.row.bg-light"):
        header = song_row.find("h4")
        if not header:
            continue
        title = _clean(header.get_text())
        author_tag = header.find_next("p")
        author = _clean(author_tag.get_text()) if author_tag else ""

        song = Song(title=title, author=author)

        collapse = song_row.find("div", class_="collapse")
        if collapse:
            for file_row in collapse.select("div.row"):
                file_entry = _parse_file_row(file_row)
                if file_entry:
                    song.files.append(file_entry)

        songs.append(song)

    return songs


def _parse_file_row(row: Tag) -> Optional[TutorialFile]:
    """Parse a single file row inside a song block."""
    label_p = row.find("p")
    if not label_p:
        return None
    # Strip out badges (BPM/Key)
    label_copy = BeautifulSoup(str(label_p), "html.parser").p
    for badge in label_copy.find_all(class_="badge"):
        badge.decompose()
    label = _clean(label_copy.get_text())
    if not label:
        return None

    direct_url: Optional[str] = None
    player_url: Optional[str] = None

    for a in row.find_all("a", href=True):
        href = a["href"]
        text_icons = " ".join(a.stripped_strings) + " " + " ".join(
            i.get_text() for i in a.find_all("i")
        )
        # Direct download links open externally with http(s)://...
        if href.startswith("http://") or href.startswith("https://"):
            direct_url = href
        elif "tutorialsAll_player.php" in href:
            player_url = urljoin(BASE_URL, href)

    if direct_url:
        return TutorialFile(label=label, url=direct_url, is_player_page=False)
    if player_url:
        # Only the embedded player exists; we'll have to scrape the player page for the mp4.
        return TutorialFile(label=label, url=player_url, is_player_page=True)
    return None


def extract_video_from_player_page(html: str) -> Optional[str]:
    """Given a tutorialsAll_player.php page, return the embedded <video src='...'> URL."""
    soup = BeautifulSoup(html, "html.parser")
    video = soup.find("video")
    if video and video.get("src"):
        return video["src"]
    # fallback: <source>
    if video:
        source = video.find("source")
        if source and source.get("src"):
            return source["src"]
    return None
