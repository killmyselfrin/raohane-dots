#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

COMMON_QS_PATH_REPLACEMENTS = [
    ('QUICKSHELL_CONFIG_NAME="ii"', 'QUICKSHELL_CONFIG_NAME="raohane"'),
    ('CACHE_DIR="$XDG_CACHE_HOME/quickshell"', 'CACHE_DIR="$XDG_CACHE_HOME/quickshell/$QUICKSHELL_CONFIG_NAME"'),
    ('STATE_DIR="$XDG_STATE_HOME/quickshell"', 'STATE_DIR="$XDG_STATE_HOME/quickshell/$QUICKSHELL_CONFIG_NAME"'),
]

REPLACEMENTS: dict[str, list[tuple[str, str]]] = {
    "modules/common/Config.qml": [
        (
            'property string panelFamily: "ii" // "ii", "waffle"',
            'property string panelFamily: "raohane" // "ii" remains accepted as a temporary compatibility value',
        ),
        (
            '''onLoadFailed: error => {\n            if (error == FileViewError.FileNotFound) {\n                writeAdapter();\n            }\n        }''',
            '''onLoadFailed: error => {\n            if (error == FileViewError.FileNotFound) {\n                // The JsonAdapter defaults are already valid. Do not keep the\n                // entire panel family disabled while the first config write is\n                // completing; a clean standalone Raohane install has no\n                // pre-existing config file.\n                root.ready = true;\n                writeAdapter();\n            }\n        }''',
        ),
    ],
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
    "modules/common/Persistent.qml": [
        (
            'property string fileDir: Directories.state',
            'property string fileDir: Directories.shellState',
        ),
        (
            '''if (error == FileViewError.FileNotFound) {\n                fileWriteTimer.restart();\n            }''',
            '''if (error == FileViewError.FileNotFound) {\n                // Defaults are usable immediately on a clean first run.\n                root.ready = true;\n                fileWriteTimer.restart();\n            }''',
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
        (
            '$HOME/.local/state/quickshell/states.json',
            '${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/raohane/states.json',
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
        ("${illogicalImpulseConfigPath}", "${raohaneConfigPath}"),
        ("$illogicalImpulseConfigPath", "$raohaneConfigPath"),
        *COMMON_QS_PATH_REPLACEMENTS,
    ],
    "scripts/colors/random/random_konachan_wall.sh": [
        (
            'illogicalImpulseConfigPath="$HOME/.config/illogical-impulse/config.json"',
            'raohaneConfigPath="${XDG_CONFIG_HOME:-$HOME/.config}/raohane/config.json"',
        ),
        ("${illogicalImpulseConfigPath}", "${raohaneConfigPath}"),
        ("$illogicalImpulseConfigPath", "$raohaneConfigPath"),
        *COMMON_QS_PATH_REPLACEMENTS,
    ],
    "scripts/colors/applycolor.sh": [
        (
            'CONFIG_FILE="$XDG_CONFIG_HOME/illogical-impulse/config.json"',
            'CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/raohane/config.json"',
        ),
        *COMMON_QS_PATH_REPLACEMENTS,
    ],
    "scripts/colors/switchwall.sh": [
        (
            'SHELL_CONFIG_FILE="$XDG_CONFIG_HOME/illogical-impulse/config.json"',
            'SHELL_CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/raohane/config.json"',
        ),
        *COMMON_QS_PATH_REPLACEMENTS,
    ],
    "scripts/colors/code/material-code-set-color.sh": [
        (
            '${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/user/generated/color.txt',
            '${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/raohane/user/generated/color.txt',
        ),
    ],
    "scripts/kvantum/materialQT.sh": [
        *COMMON_QS_PATH_REPLACEMENTS,
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

    # Individual syntactic forms are optional because upstream changes can
    # already contain a subset of the Raohane replacements. Runtime audits are
    # the strict post-condition.
    for old, new in replacements:
        if old in updated:
            updated = updated.replace(old, new)

    if updated != original:
        path.write_text(updated, encoding="utf-8")
        return True
    return False


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
