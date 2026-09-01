#!/usr/bin/env python3
"""Route installed Raohane UI strings through the runtime locale singleton.

The source tree keeps qsTr() for tooling and translation-key extraction. The
installed Quickshell payload is rewritten after staging so language changes can
be applied from JSON catalogs without requiring a compiled Qt translator.

Unlike the original bridge, this pass is recursive: services and other native
Raohane submodules can expose user-facing strings too. They resolve translation
through the low-level config-module RaohaneLocale singleton, which avoids a
services -> parent Raohane module dependency cycle.
"""

from __future__ import annotations

import os
import pathlib
import re
import sys
from urllib.parse import unquote, urlparse

CALL = re.compile(r"\bqsTr\(")
CONFIG_IMPORT = "import qs.modules.raohane.config"
SKIPPED_OUTSIDE_RUNTIME = 4
SKIP_NAMES = {"RaohaneI18n.qml", "RaohaneLocale.qml"}


def normalize_path(value: str) -> pathlib.Path:
    text = str(value).strip()
    if text.startswith("file://"):
        text = unquote(urlparse(text).path)
    return pathlib.Path(text).expanduser().resolve()


def expected_runtime() -> pathlib.Path:
    config_home = pathlib.Path(
        os.environ.get("XDG_CONFIG_HOME", pathlib.Path.home() / ".config")
    ).expanduser().resolve()
    return (config_home / "quickshell" / "raohane").resolve()


def ensure_config_import(text: str) -> str:
    if CONFIG_IMPORT in text:
        return text

    lines = text.splitlines()
    last_import = -1
    for index, line in enumerate(lines):
        if line.strip().startswith("import "):
            last_import = index

    if last_import >= 0:
        lines.insert(last_import + 1, CONFIG_IMPORT)
    else:
        insertion = 0
        while insertion < len(lines) and (
            lines[insertion].strip().startswith("pragma ")
            or lines[insertion].strip() == ""
        ):
            insertion += 1
        lines.insert(insertion, CONFIG_IMPORT)

    trailing_newline = text.endswith("\n")
    updated = "\n".join(lines)
    return updated + ("\n" if trailing_newline else "")


def localize(path: pathlib.Path) -> bool:
    text = path.read_text(encoding="utf-8")
    if "qsTr(" not in text or path.name in SKIP_NAMES:
        return False

    updated = CALL.sub("RaohaneLocale.tr(", text)
    updated = ensure_config_import(updated)
    if updated == text:
        return False
    path.write_text(updated, encoding="utf-8")
    return True


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: localize-runtime.py RUNTIME", file=sys.stderr)
        return 2

    runtime = normalize_path(sys.argv[1])
    expected = expected_runtime()
    if runtime != expected:
        print(f"[Raohane] Runtime localization skipped outside installed runtime: {runtime}")
        return SKIPPED_OUTSIDE_RUNTIME

    module = runtime / "modules" / "raohane"
    if not module.is_dir() or not (runtime / "shell.qml").is_file():
        print(f"missing installed Raohane runtime: {runtime}", file=sys.stderr)
        return 1

    changed = 0
    scanned = 0
    for path in sorted(module.rglob("*.qml")):
        scanned += 1
        changed += int(localize(path))

    print(f"[Raohane] Localized runtime QML graph: {changed} changed / {scanned} scanned")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
