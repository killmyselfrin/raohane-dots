#!/usr/bin/env python3
"""Raohane Freedesktop thumbnail generator.

Uses only the Python standard library plus Pillow. Video frames are extracted
with ffmpeg when available. The output follows the common
~/.cache/thumbnails/<size>/<md5(file-uri)>.png layout and embeds URI/mtime PNG
metadata so desktop consumers can validate the cache entry.
"""

from __future__ import annotations

import argparse
import hashlib
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Iterable
from urllib.parse import quote

try:
    from PIL import Image, PngImagePlugin
except ImportError as exc:
    raise SystemExit(
        "Pillow is required for Raohane thumbnails (Arch package: python-pillow)."
    ) from exc


SIZE_MAP = {
    "normal": 128,
    "large": 256,
    "x-large": 512,
    "xx-large": 1024,
}

IMAGE_SUFFIXES = {
    ".jpg", ".jpeg", ".png", ".webp", ".avif", ".bmp", ".gif", ".tif", ".tiff", ".svg"
}
VIDEO_SUFFIXES = {".mp4", ".webm", ".mkv", ".mov", ".avi", ".m4v"}


def file_uri(path: Path) -> str:
    return "file://" + quote(str(path.resolve()), safe="/")


def thumbnail_path(path: Path, size_name: str) -> Path:
    uri = file_uri(path)
    digest = hashlib.md5(uri.encode("utf-8"), usedforsecurity=False).hexdigest()
    cache_root = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache"))
    return cache_root / "thumbnails" / size_name / f"{digest}.png"


def cache_is_fresh(source: Path, target: Path) -> bool:
    try:
        return target.is_file() and target.stat().st_mtime >= source.stat().st_mtime
    except OSError:
        return False


def save_thumbnail(image: Image.Image, source: Path, target: Path, size: int) -> None:
    image = image.convert("RGBA") if image.mode not in {"RGB", "RGBA"} else image.copy()
    image.thumbnail((size, size), Image.Resampling.LANCZOS)

    target.parent.mkdir(parents=True, exist_ok=True)
    pnginfo = PngImagePlugin.PngInfo()
    pnginfo.add_text("Thumb::URI", file_uri(source))
    pnginfo.add_text("Thumb::MTime", str(int(source.stat().st_mtime)))
    pnginfo.add_text("Software", "Raohane")

    temporary = target.with_suffix(".png.tmp")
    with temporary.open("wb") as handle:
        image.save(handle, format="PNG", pnginfo=pnginfo, optimize=True)
    os.replace(temporary, target)


def image_thumbnail(source: Path, target: Path, size: int) -> bool:
    try:
        with Image.open(source) as image:
            try:
                image.seek(0)
            except EOFError:
                pass
            save_thumbnail(image, source, target, size)
        return True
    except (OSError, ValueError):
        return False


def extract_video_frame(ffmpeg: str, source: Path, destination: Path, seek_seconds: str, size: int) -> bool:
    command = [
        ffmpeg,
        "-loglevel", "error",
        "-y",
        "-ss", seek_seconds,
        "-i", str(source),
        "-frames:v", "1",
        "-vf", f"scale='min({size},iw)':-2",
        str(destination),
    ]
    completed = subprocess.run(command, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return completed.returncode == 0 and destination.is_file() and destination.stat().st_size > 0


def video_thumbnail(source: Path, target: Path, size: int) -> bool:
    ffmpeg = shutil.which("ffmpeg")
    if not ffmpeg:
        return False

    fd, temp_name = tempfile.mkstemp(prefix="raohane-thumb-", suffix=".png")
    os.close(fd)
    temp = Path(temp_name)
    temp.unlink(missing_ok=True)
    try:
        if not extract_video_frame(ffmpeg, source, temp, "1", size):
            temp.unlink(missing_ok=True)
            if not extract_video_frame(ffmpeg, source, temp, "0", size):
                return False
        with Image.open(temp) as image:
            save_thumbnail(image, source, target, size)
        return True
    except (OSError, ValueError):
        return False
    finally:
        temp.unlink(missing_ok=True)


def generate(source: Path, size_name: str, size: int, only_images: bool) -> bool:
    if not source.is_file():
        return False

    target = thumbnail_path(source, size_name)
    if cache_is_fresh(source, target):
        return True

    suffix = source.suffix.lower()
    if suffix in IMAGE_SUFFIXES:
        return image_thumbnail(source, target, size)
    if not only_images and suffix in VIDEO_SUFFIXES:
        return video_thumbnail(source, target, size)
    return False


def iter_files(directories: Iterable[Path], recursive: bool) -> list[Path]:
    files: list[Path] = []
    for directory in directories:
        if not directory.is_dir():
            raise ValueError(f"{directory} is not a directory")
        iterator = directory.rglob("*") if recursive else directory.glob("*")
        files.extend(path for path in iterator if path.is_file())
    return files


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate Raohane/Freedesktop thumbnails")
    parser.add_argument(
        "-d", "--img_dirs", "--directory",
        dest="directories",
        action="append",
        required=True,
        help="Directory to scan. May be supplied more than once.",
    )
    parser.add_argument("-s", "--size", choices=SIZE_MAP, default="normal")
    parser.add_argument("-w", "--workers", type=int, default=1, help="Accepted for compatibility; generation is deterministic and sequential")
    parser.add_argument("-i", "--only_images", action="store_true")
    parser.add_argument("-r", "--recursive", action="store_true")
    parser.add_argument("--machine_progress", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    size = SIZE_MAP[args.size]
    directories = [Path(value).expanduser() for value in args.directories]

    try:
        files = iter_files(directories, args.recursive)
    except ValueError as exc:
        print(f"[Raohane] {exc}", file=sys.stderr)
        return 2

    total = len(files)
    failures = 0
    supported = IMAGE_SUFFIXES | VIDEO_SUFFIXES
    for index, source in enumerate(files, start=1):
        ok = generate(source, args.size, size, args.only_images)
        if not ok and source.suffix.lower() in supported:
            failures += 1
        if args.machine_progress:
            print(f"PROGRESS {index}/{total} FILE {source}", flush=True)

    if not args.machine_progress:
        print(f"Raohane thumbnails: {total - failures}/{total} processed")

    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
