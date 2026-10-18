#!/usr/bin/env python3
"""Extract a stable, readable accent from a single local wallpaper.

Runs only on an explicit wallpaper change (never a frame loop). Videos are
sampled from one bounded FFmpeg still frame; no looping player is started.
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
    dual = len(sys.argv) == 3 and sys.argv[1] == "--dual"
    if len(sys.argv) != (3 if dual else 2):
        return 2
    path = Path(sys.argv[2] if dual else sys.argv[1])
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

    candidates = []
    for amount, index in swatches:
        rgb = palette[index * 3:index * 3 + 3]
        if len(rgb) != 3:
            continue
        normalized = tuple(channel / 255.0 for channel in rgb)
        hue, saturation, value = colorsys.rgb_to_hsv(*normalized)
        # Black and white dominate many dark wallpapers but do not produce
        # pleasant flowing colors. Prefer genuine chromatic wallpaper regions.
        if saturation < 0.20 or value < 0.17 or value > 0.96:
            continue
        score = (amount ** 0.5) * (0.35 + saturation) * (0.50 + value)
        candidates.append((score, hue, saturation, value, tuple(rgb)))

    candidates.sort(key=lambda entry: entry[0], reverse=True)

    def readable(entry):
        if entry is None:
            return (148, 181, 229)
        _, hue, saturation, value, _ = entry
        saturation = min(0.70, max(0.35, saturation))
        value = min(0.85, max(0.48, value))
        return tuple(round(channel * 255)
                     for channel in colorsys.hsv_to_rgb(hue, saturation, value))

    first = candidates[0] if candidates else None
    second = None
    if first is not None:
        # Pick a real second visible color, rather than manufacturing an
        # unrelated complement. A second burgundy/gold region is valid even
        # if it covers less area than the main wallpaper tone.
        scored = []
        for entry in candidates[1:]:
            hue_distance = min(abs(entry[1] - first[1]), 1 - abs(entry[1] - first[1]))
            color_distance = sum((entry[4][i] - first[4][i]) ** 2
                                 for i in range(3)) ** 0.5
            if hue_distance < 0.075 and color_distance < 66:
                continue
            diversity = 0.65 + min(0.9, 3.0 * hue_distance + color_distance / 330)
            scored.append((entry[0] * diversity, entry))
        if scored:
            second = max(scored, key=lambda entry: entry[0])[1]
        elif len(candidates) > 1:
            second = candidates[1]

    first_rgb = readable(first)
    second_rgb = readable(second or first)

    def hex_color(rgb):
        return "#{0:02x}{1:02x}{2:02x}".format(*rgb)

    # Backward compatible: callers not requesting --dual receive exactly the
    # original one-color output. Both colors are from the same bounded read.
    print(hex_color(first_rgb) +
          (" " + hex_color(second_rgb) if dual else ""), flush=True)
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
