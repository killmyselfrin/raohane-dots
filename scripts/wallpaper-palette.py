#!/usr/bin/env python3
"""Extract a stable, readable accent from a single local wallpaper.

Runs only on an explicit wallpaper change (never a frame loop). A video must
already have an extracted still image; this script never starts video playback.
"""
from __future__ import annotations

import colorsys
import io
import shutil
import subprocess
import sys
from pathlib import Path

VIDEO_SUFFIXES = {".mp4", ".webm", ".mkv", ".mov", ".avi", ".m4v"}


def read_wallpaper(path: Path):
    """Return a tiny RGB image, never a live video decoder or full-size frame."""
    from PIL import Image

    if path.suffix.lower() not in VIDEO_SUFFIXES:
        if path.stat().st_size > 200_000_000:
            return None
        with Image.open(path) as original:
            original.thumbnail((96, 96))
            return original.convert("RGB")

    ffmpeg = shutil.which("ffmpeg")
    if not ffmpeg:
        return None

    # Film wallpapers often fade in from black. Seek a few seconds in; short
    # clips fall back to earlier timestamps. Max decode time is bounded.
    for second in ("5", "1", "0"):
        command = [
            ffmpeg, "-hide_banner", "-loglevel", "error", "-nostdin",
            "-ss", second, "-i", str(path),
            "-frames:v", "1", "-an", "-sn",
            "-vf", "scale=min(320\\,iw):-2",
            "-f", "image2pipe", "-vcodec", "png", "pipe:1",
        ]
        try:
            result = subprocess.run(
                command, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                timeout=8, check=False,
            )
            if result.returncode == 0 and 0 < len(result.stdout) < 4_000_000:
                with Image.open(io.BytesIO(result.stdout)) as frame:
                    frame.thumbnail((96, 96))
                    return frame.convert("RGB")
        except (subprocess.TimeoutExpired, OSError, ValueError):
            continue
    return None


def main() -> int:
    if len(sys.argv) != 2:
        return 2
    path = Path(sys.argv[1])
    if not path.is_file():
        return 2
    try:
        from PIL import Image
        image = read_wallpaper(path)
        if image is None:
            return 2
        counts = image.quantize(colors=20, method=Image.Quantize.MEDIANCUT)
        palette = counts.getpalette()
        swatches = counts.getcolors(maxcolors=96 * 96) or []
    except (ImportError, OSError, ValueError):
        return 2

    best_score = -1.0
    best = (148, 181, 229)
    for amount, index in swatches:
        rgb = palette[index * 3:index * 3 + 3]
        if len(rgb) != 3:
            continue
        r, g, b = (value / 255.0 for value in rgb)
        hue, saturation, value = colorsys.rgb_to_hsv(r, g, b)
        if saturation < 0.20 or value < 0.17 or value > 0.96:
            continue
        # Prefer distinguishable chromatic colors, not the most frequent
        # black/white pixels in wallpaper art.
        score = (amount ** 0.5) * (0.35 + saturation) * (0.50 + value)
        if score > best_score:
            # Limit extremes so the accent remains readable on dark glass.
            saturation = min(0.70, max(0.35, saturation))
            value = min(0.85, max(0.48, value))
            best = tuple(round(channel * 255)
                         for channel in colorsys.hsv_to_rgb(hue, saturation, value))
            best_score = score

    print("#{0:02x}{1:02x}{2:02x}".format(*best), flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
