#!/usr/bin/env python3
"""Manage Raohane native theme catalogs.

Source palettes are converted into Raohane's complete token schema. The shell
never imports or executes another shell's runtime.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import tempfile
from pathlib import Path
from typing import Any, Iterable


CATALOG_SCHEMA = 1
HEX_COLOR = re.compile(r"^#[0-9a-fA-F]{6}$")
NATIVE_FIELDS = (
    "background", "backgroundElevated", "surface", "surfaceRaised",
    "surfaceDeep", "surfaceSubtle", "surfaceHover", "surfacePressed",
    "border", "borderStrong", "borderFaint", "highlight", "text",
    "textMuted", "textFaint", "accent", "accentSecondary", "accentBlue",
    "success", "warning", "critical", "info",
)


def default_catalog_path() -> Path:
    config_home = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
    return config_home / "raohane" / "themes.json"


def slug(value: str) -> str:
    normalized = re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-")
    return normalized or "theme"


def color(value: Any, fallback: str) -> str:
    candidate = str(value or "").strip()
    return candidate.lower() if HEX_COLOR.fullmatch(candidate) else fallback.lower()


def alpha(value: str, opacity: str) -> str:
    return f"#{opacity}{value.lstrip('#')}"


def relative_luminance(value: str) -> float:
    channels = [int(value[index:index + 2], 16) / 255 for index in (1, 3, 5)]
    converted = [channel / 12.92 if channel <= 0.04045 else ((channel + 0.055) / 1.055) ** 2.4 for channel in channels]
    return 0.2126 * converted[0] + 0.7152 * converted[1] + 0.0722 * converted[2]


def serpantinum_to_raohane(document: dict[str, Any], source_name: str) -> dict[str, Any]:
    palette = document.get("colors")
    if not isinstance(palette, dict):
        raise ValueError(f"{source_name}: missing Serpantinum colors object")

    name = str(document.get("name") or Path(source_name).stem).strip()
    base = color(palette.get("base"), "#17181b")
    mantle = color(palette.get("mantle"), base)
    crust = color(palette.get("crust"), mantle)
    surface0 = color(palette.get("surface0"), mantle)
    surface1 = color(palette.get("surface1"), surface0)
    surface2 = color(palette.get("surface2"), surface1)
    overlay0 = color(palette.get("overlay0"), surface2)
    overlay1 = color(palette.get("overlay1"), overlay0)
    overlay2 = color(palette.get("overlay2"), overlay1)
    text = color(palette.get("text"), "#eceff4")
    subtext0 = color(palette.get("subtext0"), overlay2)
    subtext1 = color(palette.get("subtext1"), subtext0)
    accent = color(palette.get("mauve"), color(palette.get("blue"), "#8296b5"))
    dark = relative_luminance(base) < 0.34

    return {
        "id": f"serp-{slug(name)}",
        "name": name,
        "description": "Serpantinum palette adapted to Raohane's native surface system",
        "tone": "Serpantinum · Dark" if dark else "Serpantinum · Light",
        "dark": dark,
        "source": "ilyamiro/serpantinum",
        "sourceTheme": name,
        "background": base,
        "backgroundElevated": surface0,
        "surface": alpha(surface0, "dc"),
        "surfaceRaised": alpha(surface1, "ee"),
        "surfaceDeep": alpha(crust, "f2"),
        "surfaceSubtle": alpha(surface0, "8f"),
        "surfaceHover": alpha(surface1, "df"),
        "surfacePressed": alpha(surface2, "e8"),
        "border": alpha(overlay0, "2e"),
        "borderStrong": alpha(overlay1, "50"),
        "borderFaint": alpha(overlay0, "18"),
        "highlight": alpha(overlay2, "38" if dark else "70"),
        "text": text,
        "textMuted": subtext1,
        "textFaint": subtext0,
        "accent": accent,
        "accentSecondary": color(palette.get("blue"), accent),
        "accentBlue": color(palette.get("sapphire"), color(palette.get("blue"), accent)),
        "success": color(palette.get("green"), "#719181"),
        "warning": color(palette.get("yellow"), "#b69b6f"),
        "critical": color(palette.get("red"), "#bd7479"),
        "info": color(palette.get("blue"), accent),
    }


def validate_native(document: dict[str, Any], source_name: str) -> dict[str, Any]:
    result = dict(document)
    result["id"] = slug(str(result.get("id") or result.get("name") or Path(source_name).stem))
    result["name"] = str(result.get("name") or result["id"]).strip()
    result["description"] = str(result.get("description") or "Custom Raohane theme")
    result["tone"] = str(result.get("tone") or "Custom")
    fallback_background = color(result.get("background"), "#17181b")
    result["dark"] = bool(result.get("dark", relative_luminance(fallback_background) < 0.34))
    for field in NATIVE_FIELDS:
        value = str(result.get(field, ""))
        if not re.fullmatch(r"#[0-9a-fA-F]{6}|#[0-9a-fA-F]{8}", value):
            raise ValueError(f"{source_name}: invalid or missing native token {field}")
        result[field] = value.lower()
    return result


def presets_from_document(document: Any, source_name: str, serpantinum: bool) -> list[dict[str, Any]]:
    raw_presets = document["presets"] if isinstance(document, dict) and isinstance(document.get("presets"), list) else [document]
    result = []
    for raw in raw_presets:
        if not isinstance(raw, dict):
            raise ValueError(f"{source_name}: theme entry is not an object")
        if serpantinum or isinstance(raw.get("colors"), dict):
            result.append(serpantinum_to_raohane(raw, source_name))
        else:
            result.append(validate_native(raw, source_name))
    return result


def read_json(path: Path) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ValueError(f"{path}: {error}") from error


def parse_inline_preset(payload: str, source_name: str) -> dict[str, Any]:
    try:
        document = json.loads(payload)
    except json.JSONDecodeError as error:
        raise ValueError(f"{source_name}: invalid JSON: {error}") from error
    if not isinstance(document, dict):
        raise ValueError(f"{source_name}: theme entry is not an object")
    return validate_native(document, source_name)


def load_sources(path: Path, serpantinum: bool) -> list[dict[str, Any]]:
    is_directory = path.is_dir()
    if is_directory:
        files: Iterable[Path] = sorted(path.glob("*.json"), key=lambda item: item.name.lower())
    elif path.is_file():
        files = [path]
    else:
        raise ValueError(f"Theme source does not exist: {path}")

    presets: list[dict[str, Any]] = []
    for source in files:
        if is_directory and source.stat().st_size == 0:
            continue
        document = read_json(source)
        if serpantinum and is_directory and (not isinstance(document, dict) or not isinstance(document.get("colors"), dict)):
            continue
        presets.extend(presets_from_document(document, str(source), serpantinum))
    if not presets:
        raise ValueError(f"No JSON themes found in {path}")
    return presets


def read_catalog(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        return []
    document = read_json(path)
    if not isinstance(document, dict) or not isinstance(document.get("presets"), list):
        raise ValueError(f"{path}: expected a Raohane theme catalog")
    return [validate_native(item, str(path)) for item in document["presets"]]


def atomic_write_text(path: Path, payload: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    temporary = Path(temporary_name)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
            handle.write(payload)
        temporary.replace(path)
    finally:
        if temporary.exists():
            temporary.unlink()


def write_catalog(path: Path, presets: list[dict[str, Any]]) -> None:
    document = {"schemaVersion": CATALOG_SCHEMA, "presets": sorted(presets, key=lambda item: (item["name"].lower(), item["id"]))}
    atomic_write_text(path, json.dumps(document, ensure_ascii=False, indent=2) + "\n")


def write_preset(path: Path, preset: dict[str, Any]) -> None:
    atomic_write_text(path, json.dumps(preset, ensure_ascii=False, indent=2) + "\n")


def merge_presets(existing: list[dict[str, Any]], incoming: list[dict[str, Any]]) -> list[dict[str, Any]]:
    merged = {preset["id"]: preset for preset in existing}
    merged.update({preset["id"]: preset for preset in incoming})
    return list(merged.values())


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Manage Raohane native theme catalogs")
    parser.add_argument("--catalog", type=Path, default=default_catalog_path(), help="catalog path")
    commands = parser.add_subparsers(dest="command", required=True)

    importer = commands.add_parser("import", help="import native or palette JSON")
    importer.add_argument("source", type=Path)
    serpantinum = commands.add_parser("import-serpantinum", help="convert Serpantinum theme JSON")
    serpantinum.add_argument("source", type=Path)
    commands.add_parser("list", help="list custom themes")
    remover = commands.add_parser("remove", help="remove a custom theme")
    remover.add_argument("theme_id")
    exporter = commands.add_parser("export", help="export one custom theme")
    exporter.add_argument("theme_id")
    exporter.add_argument("destination", type=Path)
    upserter = commands.add_parser("upsert-json", help="validate and save one inline native theme")
    upserter.add_argument("preset_json")
    inline_exporter = commands.add_parser("export-json", help="validate and export one inline native theme")
    inline_exporter.add_argument("preset_json")
    inline_exporter.add_argument("destination", type=Path)
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    catalog = args.catalog.expanduser()
    try:
        existing = read_catalog(catalog)
        if args.command in {"import", "import-serpantinum"}:
            incoming = load_sources(args.source.expanduser(), args.command == "import-serpantinum")
            write_catalog(catalog, merge_presets(existing, incoming))
            print(f"[Raohane] Imported {len(incoming)} theme(s) into {catalog}")
            return 0
        if args.command == "upsert-json":
            preset = parse_inline_preset(args.preset_json, "inline Raohane preset")
            write_catalog(catalog, merge_presets(existing, [preset]))
            print(f"[Raohane] Saved {preset['id']} into {catalog}")
            return 0
        if args.command == "list":
            for preset in sorted(existing, key=lambda item: item["name"].lower()):
                print(f"{preset['id']}\t{preset['name']}\t{preset.get('tone', 'Custom')}")
            return 0
        if args.command == "remove":
            remaining = [preset for preset in existing if preset["id"] != args.theme_id]
            if len(remaining) == len(existing):
                raise ValueError(f"Theme not found: {args.theme_id}")
            write_catalog(catalog, remaining)
            print(f"[Raohane] Removed {args.theme_id} from {catalog}")
            return 0
        if args.command == "export":
            preset = next((item for item in existing if item["id"] == args.theme_id), None)
            if preset is None:
                raise ValueError(f"Theme not found: {args.theme_id}")
            destination = args.destination.expanduser()
            write_preset(destination, preset)
            print(f"[Raohane] Exported {args.theme_id} to {destination}")
            return 0
        if args.command == "export-json":
            preset = parse_inline_preset(args.preset_json, "inline Raohane preset")
            destination = args.destination.expanduser()
            write_preset(destination, preset)
            print(f"[Raohane] Exported {preset['id']} to {destination}")
            return 0
    except ValueError as error:
        parser.error(str(error))
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
