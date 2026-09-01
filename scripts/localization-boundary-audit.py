#!/usr/bin/env python3
"""Validate that every Raohane runtime translation call exists in EN/RU catalogs."""

from __future__ import annotations

import ast
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
CATALOG_DIR = ROOT / "translations"

CALL_RE = re.compile(
    r"(?:\bqsTr|\bRaohaneI18n\.tr)\(\s*(\"(?:\\.|[^\"\\])*\"|'(?:\\.|[^'\\])*')",
    re.DOTALL,
)


def runtime_qml_files() -> list[pathlib.Path]:
    files = sorted((ROOT / "modules" / "raohane").rglob("*.qml"))
    family = ROOT / "panelFamilies" / "RaohaneFamily.qml"
    shell = ROOT / "shell.qml"
    if family.is_file():
        files.append(family)
    if shell.is_file():
        files.append(shell)
    return files


def extract_keys(path: pathlib.Path) -> set[str]:
    text = path.read_text(encoding="utf-8")
    keys: set[str] = set()
    for match in CALL_RE.finditer(text):
        literal = match.group(1)
        try:
            value = ast.literal_eval(literal)
        except (SyntaxError, ValueError):
            continue
        if isinstance(value, str) and value:
            keys.add(value)
    return keys


def load_catalog(locale: str) -> dict[str, str]:
    path = CATALOG_DIR / f"{locale}.json"
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise SystemExit(f"Could not read {path.relative_to(ROOT)}: {error}")
    if not isinstance(value, dict):
        raise SystemExit(f"{path.relative_to(ROOT)} must contain a JSON object")
    return {str(key): str(item) for key, item in value.items()}


def main() -> int:
    locations: dict[str, set[str]] = {}
    for path in runtime_qml_files():
        rel = path.relative_to(ROOT).as_posix()
        for key in extract_keys(path):
            locations.setdefault(key, set()).add(rel)

    english = load_catalog("en_US")
    russian = load_catalog("ru_RU")

    missing_en = sorted(key for key in locations if key not in english)
    missing_ru = sorted(key for key in locations if key not in russian)
    empty_ru = sorted(key for key in locations if key in russian and not russian[key].strip())

    print(f"Raohane runtime localization keys: {len(locations)}")
    print(f"Missing en_US keys: {len(missing_en)}")
    print(f"Missing ru_RU keys: {len(missing_ru)}")
    print(f"Empty ru_RU values: {len(empty_ru)}")

    def report(label: str, keys: list[str]) -> None:
        if not keys:
            return
        print(f"\n{label}:")
        for key in keys:
            where = ", ".join(sorted(locations.get(key, ())))
            print(f"  {json.dumps(key, ensure_ascii=False)}  [{where}]")

    report("Missing en_US", missing_en)
    report("Missing ru_RU", missing_ru)
    report("Empty ru_RU", empty_ru)

    if missing_en or missing_ru or empty_ru:
        return 1

    print("Raohane EN/RU runtime localization coverage: success")
    return 0


if __name__ == "__main__":
    sys.exit(main())
