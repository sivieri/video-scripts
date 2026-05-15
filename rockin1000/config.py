"""Persisted user config (cookie) stored in the home directory."""
from __future__ import annotations

import json
import os
from pathlib import Path
from typing import Optional

CONFIG_PATH = Path.home() / ".rockin1000.json"


def load_cookie() -> Optional[str]:
    if not CONFIG_PATH.exists():
        return None
    try:
        data = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return None
    cookie = data.get("cookie")
    return cookie if isinstance(cookie, str) and cookie else None


def save_cookie(cookie: str) -> None:
    CONFIG_PATH.write_text(
        json.dumps({"cookie": cookie}, ensure_ascii=False),
        encoding="utf-8",
    )
    try:
        os.chmod(CONFIG_PATH, 0o600)
    except OSError:
        pass


def resolve_cookie(passed: Optional[str]) -> Optional[str]:
    """Return the cookie to use; save it if a new one was passed."""
    if passed:
        save_cookie(passed)
        return passed
    return load_cookie()
