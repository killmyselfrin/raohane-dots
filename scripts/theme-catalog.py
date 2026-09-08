#!/usr/bin/env python3
"""Manage Raohane native theme catalogs."""

from __future__ import annotations

import argparse
import json
import os
import re
import tempfile
from pathlib import Path
from typing import Any, Iterable


CATALOG_SCHEMA = 1
NATIVE_FIELDS = (
    "background", "backgroundElevated", "surface", "surfaceRaised",
    "surfaceDeep", "surfaceSubtle", "surfaceHover", "surfacePressed",
    "border", "borderStrong", "borderFaint", "highlight", "text",
    "textMuted", "textFaint", "accent", "accentSecondary", "accentBlue",
    "success", "warning", "critical", "info",
)
HEX_COLOR = re.compile(r"^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$")


def default_catalog_path() -> Path:
    config_home = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
    return config_home / "raohane" / "themes.json"


def slug(value: str) -> str:
    normalized = re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-")
    return normalized or "theme"


def relative_luminance(value: str) -> float:
    rgb = value[-6:]
    channels = [int(rgb[index:index + 2], 16) / 255 for index in (0, 2, 4)]
    converted = [channel / 12.92 if channel <= 0.04045 else ((channel + 0.055) / 1.055) ** 2.4 for channel in channels]
    return 0.2126 * converted[0] + 0.7152 * converted[1] + 0.0722 * converted[2]


def validate_native(document: dict[str, Any], source_name: str) -> dict[str, Any]:
    result = dict(document)
    result["id"] = slug(str(result.get("id") or result.get("name") or Path(source_name).stem))
    result["name"] = str(result.get("name") or result["id"]).strip()
    result["description"] = str(result.get("description") or "Custom Raohane theme")
    result["tone"] = str(result.get("tone") or "Custom")

    for field in NATIVE_FIELDS:
        value = str(result.get(field, ""))
        if not HEX_COLOR.fullmatch(value):
            raise ValueError(f"{source_name}: invalid or missing native token {field}")
        result[field] = value.lower()

    result["dark"] = bool(result.get("dark", relative_luminance(result["background"]) < 0.34))
    result["source"] = str(result.get("source") or "user")
    return result


def presets_from_document(document: Any, source_name: str) -> list[dict[str, Any]]:
    raw_presets = document["presets"] if isinstance(document, dict) and isinstance(document.get("presets"), list) else [document]
    result = []
    for raw in raw_presets:
        if not isinstance(raw, dict):
            raise ValueError(f"{source_name}: theme entry is not an object")
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


def load_sources(path: Path) -> list[dict[str, Any]]:
    if path.is_dir():
        files: Iterable[Path] = sorted(path.glob("*.json"), key=lambda item: item.name.lower())
    elif path.is_file():
        files = [path]
    else:
        raise ValueError(f"Theme source does not exist: {path}")

    presets: list[dict[str, Any]] = []
    for source in files:
        if source.stat().st_size == 0:
            continue
        presets.extend(presets_from_document(read_json(source), str(source)))
    if not presets:
        raise ValueError(f"No JSON themes found in {path}")
    return presets


def read_catalog(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        return []
    document = read_json(path)
    if not isinstance(document, dict) or document.get("schemaVersion") != CATALOG_SCHEMA or not isinstance(document.get("presets"), list):
        raise ValueError(f"{path}: expected a Raohane theme catalog schema v{CATALOG_SCHEMA}")
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
    document = {
        "schemaVersion": CATALOG_SCHEMA,
        "presets": sorted(presets, key=lambda item: (item["name"].lower(), item["id"])),
    }
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

    importer = commands.add_parser("import", help="import native Raohane theme JSON")
    importer.add_argument("source", type=Path)
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
        if args.command == "import":
            incoming = load_sources(args.source.expanduser())
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
