#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REPLACEMENTS: dict[str, list[tuple[str, str]]] = {
    "modules/ii/settings/SettingsContent.qml": [
        (
            'Qt.openUrlExternally(`${Directories.config}/illogical-impulse/config.json`);',
            'Qt.openUrlExternally("file://" + Directories.shellConfigPath);',
        ),
        (
            'Quickshell.clipboardText = CF.FileUtils.trimFileProtocol(`${Directories.config}/illogical-impulse/config.json`);',
            'Quickshell.clipboardText = Directories.shellConfigPath;',
        ),
    ],
    "services/LauncherSearch.qml": [
        (
            "// Load user action scripts from ~/.config/illogical-impulse/actions/",
            "// Load user action scripts from ~/.config/raohane/actions/",
        ),
    ],
    "scripts/videos/record.sh": [
        (
            'CONFIG_FILE="$HOME/.config/illogical-impulse/config.json"',
            'CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/raohane/config.json"',
        ),
    ],
    "scripts/hyprland/autostart.py": [
        (
            'with open(f"{os.environ[\'HOME\']}/.config/illogical-impulse/config.json") as f:',
            'config_home = os.environ.get("XDG_CONFIG_HOME", os.path.join(os.environ["HOME"], ".config"))\nwith open(os.path.join(config_home, "raohane", "config.json")) as f:',
        ),
    ],
    "scripts/colors/random/random_osu_wall.sh": [
        (
            'illogicalImpulseConfigPath="$HOME/.config/illogical-impulse/config.json"',
            'raohaneConfigPath="${XDG_CONFIG_HOME:-$HOME/.config}/raohane/config.json"',
        ),
        ("$illogicalImpulseConfigPath", "$raohaneConfigPath"),
        ("${illogicalImpulseConfigPath}", "${raohaneConfigPath}"),
    ],
    "scripts/colors/random/random_konachan_wall.sh": [
        (
            'illogicalImpulseConfigPath="$HOME/.config/illogical-impulse/config.json"',
            'raohaneConfigPath="${XDG_CONFIG_HOME:-$HOME/.config}/raohane/config.json"',
        ),
        ("$illogicalImpulseConfigPath", "$raohaneConfigPath"),
        ("${illogicalImpulseConfigPath}", "${raohaneConfigPath}"),
    ],
    "scripts/colors/applycolor.sh": [
        (
            'CONFIG_FILE="$XDG_CONFIG_HOME/illogical-impulse/config.json"',
            'CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/raohane/config.json"',
        ),
    ],
    "scripts/colors/switchwall.sh": [
        (
            'SHELL_CONFIG_FILE="$XDG_CONFIG_HOME/illogical-impulse/config.json"',
            'SHELL_CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/raohane/config.json"',
        ),
    ],
    "scripts/presets.sh": [
        (
            'CONFIG_DIR="$HOME/.config/illogical-impulse"',
            'CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/raohane"',
        ),
    ],
}


def migrate_file(relative: str, replacements: list[tuple[str, str]]) -> bool:
    path = ROOT / relative
    if not path.is_file():
        raise SystemExit(f"missing migration target: {relative}")

    original = path.read_text(encoding="utf-8")
    updated = original
    changed = False

    for old, new in replacements:
        if old in updated:
            updated = updated.replace(old, new)
            changed = True
        elif new in updated:
            # Already migrated: keep the operation idempotent.
            continue
        else:
            raise SystemExit(f"migration anchor not found in {relative}: {old!r}")

    if changed:
        path.write_text(updated, encoding="utf-8")
    return changed


def main() -> None:
    changed_files: list[str] = []
    for relative, replacements in REPLACEMENTS.items():
        if migrate_file(relative, replacements):
            changed_files.append(relative)

    if changed_files:
        print("Migrated active Raohane runtime paths:")
        for path in changed_files:
            print(f"  {path}")
    else:
        print("Raohane runtime identity migration already applied.")


if __name__ == "__main__":
    main()
