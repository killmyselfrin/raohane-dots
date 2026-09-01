#!/usr/bin/env python3
"""Route installed Raohane UI strings through the runtime i18n singleton.

The source tree keeps qsTr() for tooling and translation-key extraction. The
installed Quickshell payload is rewritten after staging so language changes can
be applied live from JSON catalogs without requiring a compiled Qt translator.
"""

from __future__ import annotations

import os
import pathlib
import re
import sys
from urllib.parse import unquote, urlparse

CALL = re.compile(r"\bqsTr\(")


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


def localize(path: pathlib.Path) -> bool:
    text = path.read_text(encoding="utf-8")
    if "qsTr(" not in text or path.name == "RaohaneI18n.qml":
        return False
    updated = CALL.sub("RaohaneI18n.tr(", text)
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
        return 0

    module = runtime / "modules" / "raohane"
    if not module.is_dir() or not (runtime / "shell.qml").is_file():
        print(f"missing installed Raohane runtime: {runtime}", file=sys.stderr)
        return 1

    changed = 0
    for path in sorted(module.glob("*.qml")):
        changed += int(localize(path))

    print(f"[Raohane] Localized runtime surfaces: {changed}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
