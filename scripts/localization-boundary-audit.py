#!/usr/bin/env python3
"""Validate Russian coverage for every user-facing Raohane runtime translation call.

English source literals in QML are canonical. Russian resolution is layered:
legacy translations/ru_RU.json first, then all Raohane-owned runtime catalog
fragments under translations/raohane/.
"""

from __future__ import annotations

import ast
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
CATALOG_DIR = ROOT / "translations"

CALL_RE = re.compile(
    r"(?:\bqsTr|\bRaohaneI18n\.tr|\bRaohaneLocale\.tr)\(\s*(\"(?:\\.|[^\"\\])*\"|'(?:\\.|[^'\\])*')",
    re.DOTALL,
)
PLACEHOLDER_RE = re.compile(r"%\d+")


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


def load_json(path: pathlib.Path) -> dict[str, str]:
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

    russian = load_json(CATALOG_DIR / "ru_RU.json")
    runtime_overlay: dict[str, str] = {}
    fragment_paths = sorted((CATALOG_DIR / "raohane").glob("ru_RU*.json"))
    if not fragment_paths:
        raise SystemExit("No Raohane Russian runtime catalogs found")
    for path in fragment_paths:
        fragment = load_json(path)
        duplicates = sorted(set(runtime_overlay).intersection(fragment))
        if duplicates:
            raise SystemExit(
                f"Duplicate Raohane Russian keys in {path.relative_to(ROOT)}: "
                + ", ".join(duplicates[:20])
            )
        runtime_overlay.update(fragment)
    russian.update(runtime_overlay)

    missing = sorted(key for key in locations if key not in russian)
    empty = sorted(key for key in locations if key in russian and not russian[key].strip())
    placeholder_errors = sorted(
        key
        for key in locations
        if key in russian
        and sorted(PLACEHOLDER_RE.findall(key)) != sorted(PLACEHOLDER_RE.findall(russian[key]))
    )

    print(f"Raohane runtime localization keys: {len(locations)}")
    print(f"Russian runtime catalog fragments: {len(fragment_paths)}")
    print(f"Russian runtime overlay keys: {len(runtime_overlay)}")
    print(f"Missing Russian keys: {len(missing)}")
    print(f"Empty Russian values: {len(empty)}")
    print(f"Placeholder mismatches: {len(placeholder_errors)}")

    def report(label: str, keys: list[str]) -> None:
        if not keys:
            return
        print(f"\n{label}:")
        for key in keys:
            where = ", ".join(sorted(locations.get(key, ())))
            print(f"  {json.dumps(key, ensure_ascii=False)}  [{where}]")

    report("Missing Russian", missing)
    report("Empty Russian", empty)
    report("Placeholder mismatch", placeholder_errors)

    if missing or empty or placeholder_errors:
        return 1

    print("Raohane Russian runtime localization coverage: success")
    return 0


if __name__ == "__main__":
    sys.exit(main())
