#!/usr/bin/env python3

from __future__ import annotations

import colorsys
import io
import math
import pathlib
import sys
import urllib.parse
import urllib.request
from collections import defaultdict

try:
    from PIL import Image
except ImportError:
    raise SystemExit(2)

MAX_REMOTE_BYTES = 12 * 1024 * 1024
THUMBNAIL_SIZE = (96, 96)


def _open_source(source: str) -> Image.Image:
    parsed = urllib.parse.urlparse(source)

    if parsed.scheme in {"http", "https"}:
        request = urllib.request.Request(
            source,
            headers={"User-Agent": "Raohane/cover-accent"},
        )
        with urllib.request.urlopen(request, timeout=5) as response:
            payload = response.read(MAX_REMOTE_BYTES + 1)
        if len(payload) > MAX_REMOTE_BYTES:
            raise ValueError("cover image is too large")
        return Image.open(io.BytesIO(payload))

    if parsed.scheme == "file":
        path = pathlib.Path(urllib.parse.unquote(parsed.path))
    elif parsed.scheme == "":
        path = pathlib.Path(source).expanduser()
    else:
        raise ValueError("unsupported artwork URL")

    return Image.open(path)


def _luma(r: float, g: float, b: float) -> float:
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def _extract_accent(image: Image.Image) -> str | None:
    rgba = image.convert("RGBA")
    rgba.thumbnail(THUMBNAIL_SIZE, Image.Resampling.LANCZOS)

    buckets: dict[tuple[int, int, int], list[float]] = defaultdict(
        lambda: [0.0, 0.0, 0.0, 0.0]
    )
    accepted = 0

    for red, green, blue, alpha in rgba.getdata():
        if alpha < 96:
            continue

        r = red / 255.0
        g = green / 255.0
        b = blue / 255.0
        h, s, v = colorsys.rgb_to_hsv(r, g, b)
        y = _luma(r, g, b)

        # Ignore colors that are unlikely to make a useful UI accent: very
        # dark/light pixels, near-gray typography, borders and neutral backdrops.
        if s < 0.16 or y < 0.07 or y > 0.93:
            continue

        hue_bucket = int(h * 24.0) % 24
        saturation_bucket = min(4, int(s * 5.0))
        value_bucket = min(5, int(v * 6.0))
        key = (hue_bucket, saturation_bucket, value_bucket)

        entry = buckets[key]
        entry[0] += 1.0
        entry[1] += r
        entry[2] += g
        entry[3] += b
        accepted += 1

    if accepted == 0 or not buckets:
        return None

    best_color: tuple[float, float, float] | None = None
    best_score = -math.inf

    for count, red_sum, green_sum, blue_sum in buckets.values():
        r = red_sum / count
        g = green_sum / count
        b = blue_sum / count
        _, saturation, _ = colorsys.rgb_to_hsv(r, g, b)
        y = _luma(r, g, b)
        population = count / accepted
        balance = max(0.0, 1.0 - abs(y - 0.50) / 0.50)

        # Population keeps the result representative while saturation and
        # mid-tone balance favour a vivid color that still works as UI ink.
        score = (
            math.pow(population, 0.46)
            * (0.42 + saturation * 1.38)
            * (0.68 + balance * 0.52)
        )

        if score > best_score:
            best_score = score
            best_color = (r, g, b)

    if best_color is None:
        return None

    r, g, b = best_color
    hue, lightness, saturation = colorsys.rgb_to_hls(r, g, b)

    # Clamp the extracted color into a useful UI range. We preserve hue while
    # avoiding muddy low-saturation colors and retina-searing neon extremes.
    saturation = min(0.86, max(0.34, saturation))
    lightness = min(0.72, max(0.28, lightness))
    r, g, b = colorsys.hls_to_rgb(hue, lightness, saturation)

    return "#{:02x}{:02x}{:02x}".format(
        round(r * 255),
        round(g * 255),
        round(b * 255),
    )


def main() -> int:
    if len(sys.argv) != 2:
        return 2

    source = sys.argv[1].strip()
    if not source:
        return 1

    try:
        with _open_source(source) as image:
            accent = _extract_accent(image)
    except Exception:
        return 1

    if not accent:
        return 1

    print(accent)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
