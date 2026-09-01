#!/usr/bin/env python3
"""Resolve one MPRIS track against LRCLIB and print one compact JSON result.

This helper deliberately uses only Python's standard library so the installed
Raohane runtime does not need curl/jq or a long-lived network daemon.
"""

from __future__ import annotations

import json
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from typing import Any

BASE = "https://lrclib.net/api"
CLIENT = "Raohane/0.10.0-dev (https://github.com/killmyselfrin/raohane-dots)"
TIMEOUT = 6.0


def compact_spaces(value: Any) -> str:
    return re.sub(r"\s+", " ", str(value or "")).strip()


def strip_decorators(value: Any) -> str:
    text = compact_spaces(value)
    text = re.sub(
        r"\s*[\[(](official\s+)?(audio|video|music\s+video|visuali[sz]er|lyrics?|lyric\s+video)[^\])]*[\])]",
        "",
        text,
        flags=re.IGNORECASE,
    )
    text = re.sub(
        r"\s*[|·•]\s*(official\s+)?(audio|video|lyrics?|visuali[sz]er).*$",
        "",
        text,
        flags=re.IGNORECASE,
    )
    return compact_spaces(text)


def clean_artist(value: Any) -> str:
    text = strip_decorators(value)
    text = re.sub(r"\s*[-–—]\s*topic\s*$", "", text, flags=re.IGNORECASE)
    text = re.sub(r"\s*[-–—]\s*vevo\s*$", "", text, flags=re.IGNORECASE)
    text = re.sub(r"\s+topic\s*$", "", text, flags=re.IGNORECASE)
    return compact_spaces(text)


def clean_title(value: Any) -> str:
    return strip_decorators(value)


def clean_album(value: Any) -> str:
    return strip_decorators(value)


def comparable(value: Any) -> str:
    chars: list[str] = []
    for char in compact_spaces(value).casefold().replace("’", "'").replace("‘", "'").replace("`", "'"):
        chars.append(char if char.isalnum() else " ")
    return compact_spaces("".join(chars))


def has_lyrics(record: Any) -> bool:
    if not isinstance(record, dict):
        return False
    return bool(record.get("instrumental")) or bool(str(record.get("syncedLyrics") or "").strip()) or bool(
        str(record.get("plainLyrics") or "").strip()
    )


def artist_matches(record_artist: str, wanted_artist: str) -> bool:
    if record_artist == wanted_artist:
        return True
    return (len(wanted_artist) >= 5 and wanted_artist in record_artist) or (
        len(record_artist) >= 5 and record_artist in wanted_artist
    )


def record_matches(record: Any, meta: dict[str, Any], strict_duration: bool = False) -> bool:
    if not has_lyrics(record):
        return False

    wanted_title = comparable(meta["title"])
    wanted_artist = comparable(meta["artist"])
    record_title = comparable(clean_title(record.get("trackName") or record.get("name") or ""))
    record_artist = comparable(clean_artist(record.get("artistName") or ""))

    if not wanted_title or not wanted_artist:
        return False
    if record_title != wanted_title or not artist_matches(record_artist, wanted_artist):
        return False

    wanted_duration = float(meta.get("duration") or 0)
    record_duration = float(record.get("duration") or 0)
    if strict_duration and wanted_duration > 0 and record_duration > 0:
        return abs(wanted_duration - record_duration) <= 4
    return True


def choose_best(records: Any, meta: dict[str, Any]) -> dict[str, Any] | None:
    if not isinstance(records, list):
        return None

    wanted_duration = float(meta.get("duration") or 0)
    wanted_album = comparable(meta.get("album") or "")
    best: dict[str, Any] | None = None
    best_score = float("inf")

    for record in records:
        if not isinstance(record, dict) or not record_matches(record, meta, False):
            continue

        record_duration = float(record.get("duration") or 0)
        score = 0.0
        if wanted_duration > 0 and record_duration > 0:
            difference = abs(wanted_duration - record_duration)
            if difference > 10:
                continue
            score += difference

        record_album = comparable(clean_album(record.get("albumName") or ""))
        if wanted_album and record_album == wanted_album:
            score -= 4
        if str(record.get("syncedLyrics") or "").strip():
            score -= 2

        if score < best_score:
            best_score = score
            best = record

    return best


def request_json(path: str, params: dict[str, Any]) -> tuple[int, Any]:
    query = urllib.parse.urlencode({key: value for key, value in params.items() if value not in (None, "")})
    url = f"{BASE}{path}?{query}"
    request = urllib.request.Request(
        url,
        headers={
            "Accept": "application/json",
            "User-Agent": CLIENT,
            "Lrclib-Client": CLIENT,
        },
        method="GET",
    )
    try:
        with urllib.request.urlopen(request, timeout=TIMEOUT) as response:
            return int(response.status), json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as error:
        if error.code in (400, 404):
            return int(error.code), None
        raise


def compact_record(record: dict[str, Any]) -> dict[str, Any]:
    return {
        "trackName": str(record.get("trackName") or record.get("name") or ""),
        "artistName": str(record.get("artistName") or ""),
        "albumName": str(record.get("albumName") or ""),
        "duration": float(record.get("duration") or 0),
        "instrumental": bool(record.get("instrumental")),
        "plainLyrics": str(record.get("plainLyrics") or ""),
        "syncedLyrics": str(record.get("syncedLyrics") or ""),
    }


def resolve(meta: dict[str, Any]) -> tuple[str, dict[str, Any] | None]:
    exact = {"artist_name": meta["artist"], "track_name": meta["title"]}
    if 1 <= meta["duration"] <= 3600:
        status, record = request_json("/get", {**exact, "duration": meta["duration"]})
        if status == 200 and record_matches(record, meta, True):
            return "exact-duration", record

    status, record = request_json("/get", exact)
    if status == 200 and record_matches(record, meta, False):
        return "exact", record

    status, records = request_json("/search", exact)
    if status == 200:
        best = choose_best(records, meta)
        if best:
            return "structured-search", best

    status, records = request_json("/search", {"q": f"{meta['artist']} {meta['title']}"})
    if status == 200:
        best = choose_best(records, meta)
        if best:
            return "loose-search", best

    return "not-found", None


def main() -> int:
    if len(sys.argv) < 3:
        print(json.dumps({"ok": False, "status": "invalid-arguments", "error": "artist and title are required"}))
        return 2

    artist = clean_artist(sys.argv[1])
    title = clean_title(sys.argv[2])
    album = clean_album(sys.argv[3] if len(sys.argv) > 3 else "")
    try:
        duration = max(0, int(round(float(sys.argv[4])))) if len(sys.argv) > 4 else 0
    except ValueError:
        duration = 0

    meta = {"artist": artist, "title": title, "album": album, "duration": duration}
    if not artist or not title:
        print(json.dumps({"ok": False, "status": "missing-metadata", "error": "artist/title metadata is incomplete"}))
        return 0

    try:
        status, record = resolve(meta)
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError, OSError) as error:
        print(
            json.dumps(
                {"ok": False, "status": "network-error", "error": compact_spaces(error)},
                ensure_ascii=False,
            )
        )
        return 0

    if record is None:
        print(json.dumps({"ok": False, "status": status, "error": "Lyrics were not found for this track"}, ensure_ascii=False))
        return 0

    print(
        json.dumps(
            {"ok": True, "status": status, "record": compact_record(record)},
            ensure_ascii=False,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
