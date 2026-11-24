#!/usr/bin/env python3
"""Optional Matugen palette adapter for Raohane.

Matugen is asked to generate a dark Material You palette as JSON only. The
--dry-run flag prevents Matugen templates or wallpaper commands from changing
files/wallpaper behind Raohane's own wallpaper pipeline. If Matugen is absent,
returns an unsupported JSON shape, or fails, the existing Raohane palette
extractor remains the fallback.
"""
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

HEX = re.compile(r"^#[0-9a-fA-F]{6}$")


def find_color(value, key: str):
    if isinstance(value, dict):
        for name, child in value.items():
            if str(name).lower() == key:
                if isinstance(child, str) and HEX.fullmatch(child):
                    return child.lower()
                if isinstance(child, dict):
                    for color_key in ("hex", "color", "value"):
                        candidate = child.get(color_key)
                        if isinstance(candidate, str) and HEX.fullmatch(candidate):
                            return candidate.lower()
                    nested = find_color(child, key)
                    if nested:
                        return nested
            nested = find_color(child, key)
            if nested:
                return nested
    elif isinstance(value, list):
        for child in value:
            nested = find_color(child, key)
            if nested:
                return nested
    return None


def find_mode_color(value, key: str, mode: str):
    """Prefer a value nested under a dark-mode branch when the JSON has both."""
    if isinstance(value, dict):
        for name, child in value.items():
            if str(name).lower() in ("dark", "amoled") and isinstance(child, (dict, list)):
                found = find_color(child, key)
                if found:
                    return found
        for child in value.values():
            found = find_mode_color(child, key, mode)
            if found:
                return found
    elif isinstance(value, list):
        for child in value:
            found = find_mode_color(child, key, mode)
            if found:
                return found
    return find_color(value, key)


def matugen_pair(image: Path):
    command = [
        "matugen", "image", str(image),
        "--json", "hex", "--dry-run", "--mode", "dark",
    ]
    result = subprocess.run(command, capture_output=True, text=True, timeout=45, check=False)
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or f"matugen exited with {result.returncode}")
    output = result.stdout.strip()
    start, end = output.find("{"), output.rfind("}")
    if start < 0 or end < start:
        raise ValueError("Matugen did not return a JSON palette")
    payload = json.loads(output[start:end + 1])
    primary = find_mode_color(payload, "primary", "dark")
    secondary = find_mode_color(payload, "secondary", "dark")
    if not primary:
        raise ValueError("Matugen JSON does not contain a primary color")
    if not secondary:
        secondary = find_mode_color(payload, "tertiary", "dark") or primary
    return primary, secondary


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
    if provider == "matugen":
        try:
            pair = matugen_pair(image)
        except (OSError, subprocess.SubprocessError, ValueError, json.JSONDecodeError) as error:
            print(f"[Raohane] Matugen unavailable or failed; using built-in palette: {error}", file=sys.stderr)
            pair = builtin_pair(image, script)
    else:
        pair = builtin_pair(image, script)
    print(*pair)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
