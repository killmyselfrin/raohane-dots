#!/usr/bin/env python3
"""Convert a small, safe subset of the inherited shell config to Raohane v10.

The old configuration contains hundreds of settings for components Raohane no
longer loads. Importing that document verbatim into native.json is therefore
incorrect. This converter starts from Raohane's native defaults and only copies
settings that have a direct native equivalent.
"""

from __future__ import annotations

import argparse
import copy
import json
from pathlib import Path
from typing import Any


def load_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise SystemExit(f"Could not read {path}: {exc}") from exc
    if not isinstance(value, dict):
        raise SystemExit(f"Expected a JSON object in {path}")
    return value


def nested(data: dict[str, Any], *keys: str) -> Any:
    current: Any = data
    for key in keys:
        if not isinstance(current, dict) or key not in current:
            return None
        current = current[key]
    return current


def assign(target: dict[str, Any], section: str, key: str, value: Any) -> None:
    if value is None:
        return
    bucket = target.setdefault(section, {})
    if isinstance(bucket, dict):
        bucket[key] = value


def main() -> int:
    parser = argparse.ArgumentParser(description="Migrate supported legacy settings to Raohane native schema")
    parser.add_argument("legacy", type=Path)
    parser.add_argument("defaults", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    legacy = load_json(args.legacy)
    native_defaults = load_json(args.defaults)
    native = copy.deepcopy(native_defaults)

    # Wallpaper/background settings with direct Raohane equivalents.
    assign(native, "wallpaper", "path", nested(legacy, "background", "wallpaperPath"))
    assign(native, "wallpaper", "directory", nested(legacy, "background", "autoWallpaper", "folder"))
    assign(native, "wallpaper", "hideWhenFullscreen", nested(legacy, "background", "hideWhenFullscreen"))

    # OSD timeout has the same semantic meaning in both configurations.
    assign(native, "osd", "timeout", nested(legacy, "osd", "timeout"))

    # Application launch commands are safe to preserve when explicitly set.
    apps = legacy.get("apps")
    if isinstance(apps, dict):
        for old_key, native_key in (
            ("network", "network"),
            ("networkEthernet", "networkEthernet"),
            ("bluetooth", "bluetooth"),
            ("taskManager", "taskManager"),
            ("changePassword", "changePassword"),
        ):
            value = apps.get(old_key)
            if isinstance(value, str) and value.strip():
                assign(native, "apps", native_key, value)

    native["schemaVersion"] = 12
    args.output.parent.mkdir(parents=True, exist_ok=True)
    temporary = args.output.with_suffix(args.output.suffix + ".tmp")
    temporary.write_text(json.dumps(native, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    temporary.replace(args.output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
