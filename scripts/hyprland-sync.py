#!/usr/bin/env python3
"""Persist Raohane-owned keybind and animation preferences into Hyprland.

The native Raohane config remains the source of truth. This helper only owns a
small marked block inside the installer-managed raohane.lua / raohane.conf
snippet, then optionally reloads Hyprland so edits apply immediately.
"""

from __future__ import annotations

import argparse
import json
import os
import pathlib
import re
import shutil
import subprocess
from typing import Any

CONFIG_HOME = pathlib.Path(os.environ.get("XDG_CONFIG_HOME", pathlib.Path.home() / ".config"))
RAOHANE_CONFIG = CONFIG_HOME / "raohane" / "native.json"
HYPR_DIR = CONFIG_HOME / "hypr"
LUA_SNIPPET = HYPR_DIR / "raohane.lua"
LEGACY_SNIPPET = HYPR_DIR / "raohane.conf"

LUA_START = "-- Raohane managed user preferences"
LUA_END = "-- End Raohane managed user preferences"
LEGACY_START = "# Raohane managed user preferences"
LEGACY_END = "# End Raohane managed user preferences"
OLD_LUA_START = "-- Raohane managed core shortcuts"
OLD_LUA_END = "-- End Raohane managed core shortcuts"
OLD_LEGACY_START = "# Raohane managed core shortcuts"
OLD_LEGACY_END = "# End Raohane managed core shortcuts"

DEFAULT_KEYBINDS: dict[str, str] = {
    "closeWindow": "ALT + Q",
    "launcher": "SUPER + R",
    "settings": "SUPER + Escape",
    "controlCenter": "SUPER + C",
    "mediaOverlay": "SUPER + SHIFT + M",
    "screenshot": "SUPER + SHIFT + S",
}

DEFAULT_APPLICATIONS: dict[str, str] = {}
for index in range(1, 5):
    DEFAULT_APPLICATIONS[f"app{index}Name"] = f"Application {index}"
    DEFAULT_APPLICATIONS[f"app{index}Keys"] = ""
    DEFAULT_APPLICATIONS[f"app{index}Command"] = ""

DEFAULT_ANIMATIONS: dict[str, Any] = {
    "enabled": True,
    "windowMs": 240,
    "workspaceMs": 300,
    "layerMs": 220,
    "fadeMs": 170,
    "workspaceDistance": 14,
}

MODIFIER_ALIASES = {
    "SUPER": "SUPER",
    "META": "SUPER",
    "WIN": "SUPER",
    "CTRL": "CTRL",
    "CONTROL": "CTRL",
    "ALT": "ALT",
    "SHIFT": "SHIFT",
}
MODIFIER_ORDER = ("SUPER", "CTRL", "ALT", "SHIFT")


def load_document() -> dict[str, Any]:
    try:
        value = json.loads(RAOHANE_CONFIG.read_text(encoding="utf-8"))
        return value if isinstance(value, dict) else {}
    except (OSError, json.JSONDecodeError):
        return {}


def clamp_number(value: Any, minimum: float, maximum: float, fallback: float) -> float:
    try:
        number = float(value)
    except (TypeError, ValueError):
        return fallback
    return max(minimum, min(maximum, number))


def normalize_combo(value: Any) -> str:
    raw = str(value or "").strip()
    if not raw:
        return ""
    parts = [part.strip() for part in re.split(r"\s*\+\s*", raw) if part.strip()]
    modifiers: list[str] = []
    key = ""
    for part in parts:
        upper = part.upper()
        modifier = MODIFIER_ALIASES.get(upper)
        if modifier:
            if modifier not in modifiers:
                modifiers.append(modifier)
        else:
            key = part
    if not key:
        return ""
    ordered = [modifier for modifier in MODIFIER_ORDER if modifier in modifiers]
    return " + ".join([*ordered, key])


def keybinds_from(document: dict[str, Any]) -> dict[str, str]:
    source = document.get("keybinds")
    source = source if isinstance(source, dict) else {}
    result = {key: normalize_combo(source.get(key, value)) for key, value in DEFAULT_KEYBINDS.items()}
    for key, value in DEFAULT_APPLICATIONS.items():
        if key.endswith("Keys"):
            result[key] = normalize_combo(source.get(key, value))
        else:
            result[key] = str(source.get(key, value) or "").strip()
    return result


def animations_from(document: dict[str, Any]) -> dict[str, Any]:
    source = document.get("animations")
    source = source if isinstance(source, dict) else {}
    return {
        "enabled": bool(source.get("enabled", DEFAULT_ANIMATIONS["enabled"])),
        "windowMs": round(clamp_number(source.get("windowMs"), 80, 1200, 240)),
        "workspaceMs": round(clamp_number(source.get("workspaceMs"), 80, 1600, 300)),
        "layerMs": round(clamp_number(source.get("layerMs"), 80, 1200, 220)),
        "fadeMs": round(clamp_number(source.get("fadeMs"), 60, 1000, 170)),
        "workspaceDistance": round(clamp_number(source.get("workspaceDistance"), 4, 40, 14)),
    }


def lua_string(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def legacy_parts(combo: str) -> tuple[str, str] | None:
    normalized = normalize_combo(combo)
    if not normalized:
        return None
    parts = [part.strip() for part in normalized.split("+")]
    key = parts[-1]
    modifiers = " ".join(part for part in parts[:-1])
    return modifiers, key


def all_managed_combos(config: dict[str, str]) -> list[str]:
    combos = set(DEFAULT_KEYBINDS.values())
    combos.update(value for key, value in config.items() if key in DEFAULT_KEYBINDS and value)
    combos.update(config.get(f"app{index}Keys", "") for index in range(1, 5))
    return sorted(combo for combo in combos if combo)


def lua_unbind_lines(config: dict[str, str]) -> list[str]:
    return [f"hl.unbind({lua_string(combo)})" for combo in all_managed_combos(config)]


def lua_bind_lines(config: dict[str, str]) -> list[str]:
    actions = {
        "closeWindow": ('hl.dsp.window.close()', "Close active window"),
        "launcher": ('hl.dsp.global("quickshell:raohaneLauncherToggle")', "Launcher"),
        "settings": ('hl.dsp.global("quickshell:settingsToggle")', "Settings"),
        "controlCenter": ('hl.dsp.global("quickshell:sidebarRightToggle")', "Control Center"),
        "mediaOverlay": ('hl.dsp.global("quickshell:raohaneMediaOverlayToggle")', "Media overlay"),
        "screenshot": ('hl.dsp.global("quickshell:regionScreenshot")', "Region screenshot"),
    }
    lines: list[str] = []
    seen: set[str] = set()
    for key in DEFAULT_KEYBINDS:
        combo = normalize_combo(config.get(key, ""))
        if not combo or combo in seen:
            continue
        seen.add(combo)
        dispatcher, description = actions[key]
        lines.append(
            f"hl.bind({lua_string(combo)}, {dispatcher}, "
            f"{{ description = {lua_string('Raohane: ' + description)} }})"
        )

    for index in range(1, 5):
        combo = normalize_combo(config.get(f"app{index}Keys", ""))
        command = config.get(f"app{index}Command", "").strip()
        name = config.get(f"app{index}Name", "").strip() or f"Application {index}"
        if not combo or not command or combo in seen:
            continue
        seen.add(combo)
        lines.append(
            f"hl.bind({lua_string(combo)}, hl.dsp.exec_cmd({lua_string(command)}), "
            f"{{ description = {lua_string('Raohane: ' + name)} }})"
        )
    return lines


def lua_animation_lines(config: dict[str, Any]) -> list[str]:
    enabled = bool(config["enabled"])
    lines = [f"hl.config({{ animations = {{ enabled = {'true' if enabled else 'false'} }} }})"]
    if not enabled:
        return lines

    def ds(ms: int) -> str:
        return f"{max(0.5, ms / 100.0):.2f}"

    window_ms = int(config["windowMs"])
    workspace_ms = int(config["workspaceMs"])
    layer_ms = int(config["layerMs"])
    fade_ms = int(config["fadeMs"])
    distance = int(config["workspaceDistance"])

    lines.extend(
        [
            'hl.curve("raohaneEase", { type = "bezier", points = { {0.22, 1.0}, {0.36, 1.0} } })',
            'hl.curve("raohaneFade", { type = "bezier", points = { {0.20, 0.0}, {0.0, 1.0} } })',
            f'hl.animation({{ leaf = "windows", enabled = true, speed = {ds(window_ms)}, bezier = "raohaneEase", style = "popin 96%" }})',
            f'hl.animation({{ leaf = "layers", enabled = true, speed = {ds(layer_ms)}, bezier = "raohaneEase", style = "popin 98%" }})',
            f'hl.animation({{ leaf = "workspaces", enabled = true, speed = {ds(workspace_ms)}, bezier = "raohaneEase", style = "slidefade {distance}%" }})',
            f'hl.animation({{ leaf = "fade", enabled = true, speed = {ds(fade_ms)}, bezier = "raohaneFade" }})',
        ]
    )
    return lines


def legacy_unbind_lines(config: dict[str, str]) -> list[str]:
    lines: list[str] = []
    for combo in all_managed_combos(config):
        parts = legacy_parts(combo)
        if parts:
            modifiers, key = parts
            lines.append(f"unbind = {modifiers}, {key}")
    return lines


def legacy_bind_lines(config: dict[str, str]) -> list[str]:
    actions = {
        "closeWindow": ("killactive", ""),
        "launcher": ("global", "quickshell:raohaneLauncherToggle"),
        "settings": ("global", "quickshell:settingsToggle"),
        "controlCenter": ("global", "quickshell:sidebarRightToggle"),
        "mediaOverlay": ("global", "quickshell:raohaneMediaOverlayToggle"),
        "screenshot": ("global", "quickshell:regionScreenshot"),
    }
    lines: list[str] = []
    seen: set[str] = set()
    for name in DEFAULT_KEYBINDS:
        combo = normalize_combo(config.get(name, ""))
        parts = legacy_parts(combo)
        if not combo or not parts or combo in seen:
            continue
        seen.add(combo)
        modifiers, key = parts
        dispatcher, argument = actions[name]
        lines.append(f"bind = {modifiers}, {key}, {dispatcher}, {argument}")

    for index in range(1, 5):
        combo = normalize_combo(config.get(f"app{index}Keys", ""))
        command = config.get(f"app{index}Command", "").strip()
        parts = legacy_parts(combo)
        if not combo or not command or not parts or combo in seen:
            continue
        seen.add(combo)
        modifiers, key = parts
        lines.append(f"bind = {modifiers}, {key}, exec, {command}")
    return lines


def legacy_animation_lines(config: dict[str, Any]) -> list[str]:
    if not config["enabled"]:
        return ["animations {", "    enabled = false", "}"]

    def ds(ms: int) -> str:
        return f"{max(0.5, ms / 100.0):.2f}"

    window_ms = int(config["windowMs"])
    workspace_ms = int(config["workspaceMs"])
    layer_ms = int(config["layerMs"])
    fade_ms = int(config["fadeMs"])
    distance = int(config["workspaceDistance"])

    return [
        "animations {",
        "    enabled = true",
        "    bezier = raohaneEase, 0.22, 1.0, 0.36, 1.0",
        "    bezier = raohaneFade, 0.20, 0.0, 0.0, 1.0",
        f"    animation = windows, 1, {ds(window_ms)}, raohaneEase, popin 96%",
        f"    animation = layers, 1, {ds(layer_ms)}, raohaneEase, popin 98%",
        f"    animation = workspaces, 1, {ds(workspace_ms)}, raohaneEase, slidefade {distance}%",
        f"    animation = fade, 1, {ds(fade_ms)}, raohaneFade",
        "}",
    ]


def strip_marked_blocks(text: str, markers: list[tuple[str, str]]) -> str:
    output: list[str] = []
    active_end: str | None = None
    starts = {start: end for start, end in markers}
    for line in text.splitlines():
        stripped = line.strip()
        if active_end is None and stripped in starts:
            active_end = starts[stripped]
            continue
        if active_end is not None:
            if stripped == active_end:
                active_end = None
            continue
        output.append(line)
    return "\n".join(output).rstrip()


def replace_block(
    path: pathlib.Path,
    start: str,
    end: str,
    old_start: str,
    old_end: str,
    block_lines: list[str],
) -> None:
    if not path.exists():
        return
    text = path.read_text(encoding="utf-8")
    clean = strip_marked_blocks(text, [(start, end), (old_start, old_end)])
    block = "\n".join([start, *block_lines, end])
    content = clean + "\n\n" + block + "\n"
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(content, encoding="utf-8")
    temporary.replace(path)


def sync() -> pathlib.Path | None:
    document = load_document()
    keybinds = keybinds_from(document)
    animations = animations_from(document)

    if LUA_SNIPPET.exists():
        lines = [
            "-- Generated from ~/.config/raohane/native.json; edit through Raohane Settings.",
            *lua_unbind_lines(keybinds),
            *lua_bind_lines(keybinds),
            "",
            *lua_animation_lines(animations),
        ]
        replace_block(LUA_SNIPPET, LUA_START, LUA_END, OLD_LUA_START, OLD_LUA_END, lines)
        return LUA_SNIPPET

    if LEGACY_SNIPPET.exists():
        lines = [
            "# Generated from ~/.config/raohane/native.json; edit through Raohane Settings.",
            *legacy_unbind_lines(keybinds),
            *legacy_bind_lines(keybinds),
            "",
            *legacy_animation_lines(animations),
        ]
        replace_block(
            LEGACY_SNIPPET,
            LEGACY_START,
            LEGACY_END,
            OLD_LEGACY_START,
            OLD_LEGACY_END,
            lines,
        )
        return LEGACY_SNIPPET

    return None


def reload_hyprland() -> bool:
    if not shutil.which("hyprctl") or not os.environ.get("HYPRLAND_INSTANCE_SIGNATURE"):
        return False
    result = subprocess.run(
        ["hyprctl", "reload"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    return result.returncode == 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Sync Raohane Hyprland preferences")
    parser.add_argument("--apply", action="store_true", help="reload Hyprland after updating the managed snippet")
    parser.add_argument("--print-path", action="store_true", help="print the managed snippet path")
    args = parser.parse_args()

    path = sync()
    if args.print_path and path:
        print(path)
    if args.apply and path:
        reload_hyprland()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
