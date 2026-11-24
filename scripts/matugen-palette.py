#!/usr/bin/env python3
"""Optional Matugen Material You palette adapter for Raohane.

The adapter emits one compact JSON object on stdout. It never invokes Matugen
templates or wallpaper commands (--dry-run); Raohane remains the only owner of
wallpaper rendering. The built-in extractor remains the fallback.
"""
from __future__ import annotations

import json
import re
import subprocess
import sys
import tempfile
import shutil
from pathlib import Path

HEX = re.compile(r"^#[0-9a-fA-F]{6}$")
VIDEO_SUFFIXES = {".mp4", ".webm", ".mkv", ".mov", ".avi", ".m4v"}
ROLES = (
    "primary", "on_primary", "primary_container", "on_primary_container",
    "secondary", "on_secondary", "secondary_container", "on_secondary_container",
    "tertiary", "on_tertiary", "tertiary_container", "on_tertiary_container",
    "error", "on_error", "error_container", "on_error_container",
    "background", "on_background", "surface", "on_surface",
    "surface_variant", "on_surface_variant", "surface_dim", "surface_bright",
    "surface_container_lowest", "surface_container_low", "surface_container",
    "surface_container_high", "surface_container_highest",
    "outline", "outline_variant", "inverse_surface", "inverse_on_surface",
    "inverse_primary", "scrim", "shadow", "surface_tint",
)


def valid_hex(value):
    return isinstance(value, str) and HEX.fullmatch(value) is not None


def extract_scheme(payload, scheme):
    """Read Matugen v4's colors.dark/light schema; tolerate older nested output."""
    colors = payload.get("colors", payload) if isinstance(payload, dict) else {}
    candidates = []
    if isinstance(colors, dict):
        selected = colors.get(scheme)
        if isinstance(selected, dict):
            candidates.append(selected)
        # Older releases can nest palettes under mode names or scheme labels.
        for key in ("default", "amoled"):
            value = colors.get(key)
            if scheme == "dark" and isinstance(value, dict):
                candidates.append(value)
        if not candidates and all(isinstance(v, str) for v in colors.values()):
            candidates.append(colors)
    result = {}
    for candidate in candidates:
        for role in ROLES:
            value = candidate.get(role)
            if valid_hex(value):
                result[role] = value.lower()
    return result


def matugen_source_image(image: Path, temporary: Path):
    """Convert a video wallpaper to one bounded still frame for Matugen."""
    if image.suffix.lower() not in VIDEO_SUFFIXES:
        return image
    ffmpeg = shutil.which("ffmpeg")
    if not ffmpeg:
        raise RuntimeError("ffmpeg is required for Matugen video wallpaper palettes")
    output = temporary / "wallpaper-frame.png"
    for second in ("5", "1", "0"):
        command = [
            ffmpeg, "-hide_banner", "-loglevel", "error", "-nostdin", "-y",
            "-ss", second, "-i", str(image), "-map", "0:v:0",
            "-frames:v", "1", "-an", "-sn",
            "-vf", "scale=min(1280\\,iw):-2", str(output),
        ]
        try:
            result = subprocess.run(
                command, capture_output=True, timeout=6, check=False,
            )
        except (OSError, subprocess.TimeoutExpired):
            continue
        if result.returncode == 0 and output.is_file() and 0 < output.stat().st_size < 20_000_000:
            return output
    raise RuntimeError("could not extract a representative frame from the video wallpaper")


def matugen_palette(image: Path):
    # Use an isolated empty config: Matugen must not load, execute, or modify
    # templates/hooks/wallpaper commands from the user's personal config.
    with tempfile.TemporaryDirectory(prefix="raohane-matugen-") as temporary:
        temporary_path = Path(temporary)
        config = temporary_path / "config.toml"
        config.write_text("[config]\\n", encoding="utf-8")
        source_image = matugen_source_image(image, temporary_path)
        command = [
            "matugen", "image", str(source_image),
            "--json", "hex", "--dry-run", "--source-color-index", "0", "-c", str(config),
        ]
        result = subprocess.run(command, capture_output=True, text=True, timeout=45, check=False)
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or f"matugen exited with {result.returncode}")
    output = result.stdout.strip()
    start, end = output.find("{"), output.rfind("}")
    if start < 0 or end < start:
        raise ValueError("Matugen did not return a JSON palette")
    payload = json.loads(output[start:end + 1])
    palettes = {mode: extract_scheme(payload, mode) for mode in ("dark", "light")}
    if not palettes["dark"].get("primary") or not palettes["dark"].get("surface"):
        raise ValueError("Matugen JSON is missing the Material You dark scheme")
    if not palettes["light"].get("primary") or not palettes["light"].get("surface"):
        # Older Matugen builds may only emit the requested mode. Keep a safe
        # light-mode fallback rather than applying dark colors to a light preset.
        palettes["light"] = {}
    return palettes


def builtin_pair(image: Path, script: Path):
    result = subprocess.run(
        ["python3", "-E", str(script), "--dual", str(image)],
        capture_output=True, text=True, timeout=45, check=False,
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or "Raohane palette extraction failed")
    match = re.fullmatch(r"\s*(#[0-9a-fA-F]{6})\s+(#[0-9a-fA-F]{6})\s*", result.stdout)
    if not match:
        raise ValueError("Raohane palette extractor returned an invalid color pair")
    return match.group(1).lower(), match.group(2).lower()


def main():
    if len(sys.argv) != 3 or sys.argv[1] not in ("builtin", "matugen"):
        print("usage: matugen-palette.py builtin|matugen IMAGE", file=sys.stderr)
        return 2
    provider, raw_path = sys.argv[1:]
    image = Path(raw_path).expanduser()
    if not image.is_file():
        print("wallpaper image does not exist", file=sys.stderr)
        return 2
    script = Path(__file__).with_name("wallpaper-palette.py")
    palettes = {}
    if provider == "matugen":
        try:
            palettes = matugen_palette(image)
            primary = palettes["dark"]["primary"]
            secondary = palettes["dark"].get("secondary") or palettes["dark"].get("tertiary") or primary
        except (OSError, subprocess.SubprocessError, ValueError, json.JSONDecodeError) as error:
            print(f"[Raohane] Matugen unavailable or failed; using built-in palette: {error}", file=sys.stderr)
            primary, secondary = builtin_pair(image, script)
    else:
        primary, secondary = builtin_pair(image, script)
    print(json.dumps({
        "provider": provider if palettes else "builtin",
        "primary": primary,
        "secondary": secondary,
        "palettes": palettes,
    }, separators=(",", ":")))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
