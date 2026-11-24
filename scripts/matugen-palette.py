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
from pathlib import Path

HEX = re.compile(r"^#[0-9a-fA-F]{6}$")
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


def matugen_palette(image: Path):
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
        except (OSError, subprocess.SubprocessError, ValueError, json.JSONDecodeError) as error:
            print(f"[Raohane] Matugen unavailable or failed; using built-in palette: {error}", file=sys.stderr)
    primary, secondary = builtin_pair(image, script)
    if palettes.get("dark"):
        primary = palettes["dark"].get("primary", primary)
        secondary = palettes["dark"].get("secondary", palettes["dark"].get("tertiary", secondary))
    print(json.dumps({
        "provider": provider if palettes else "builtin",
        "primary": primary,
        "secondary": secondary,
        "palettes": palettes,
    }, separators=(",", ":")))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
