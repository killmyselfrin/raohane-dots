#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'multimonitor-boundary-audit: %s\n' "$*" >&2
  exit 1
}

focused_surfaces=(
  modules/raohane/RaohaneLauncher.qml
  modules/raohane/RaohaneControlCenter.qml
  modules/raohane/RaohaneSettings.qml
  modules/raohane/RaohaneSidebarLeft.qml
  modules/raohane/RaohaneMediaOverlay.qml
  modules/raohane/RaohaneOverview.qml
  modules/raohane/RaohaneOverlay.qml
  modules/raohane/RaohaneOnScreenKeyboard.qml
  modules/raohane/RaohaneScreenTranslator.qml
  modules/raohane/RaohaneWallpaperSelector.qml
  modules/raohane/RaohaneSessionScreen.qml
  modules/raohane/RaohanePolkit.qml
  modules/raohane/RaohaneDropShelfPanel.qml
)

for file in "${focused_surfaces[@]}"; do
  [[ -f "$file" ]] || fail "missing focused-screen surface: $file"
  rg -q '^import Quickshell\.Hyprland$' "$file" \
    || fail "$file does not import Quickshell.Hyprland"
  rg -q 'readonly property var focusedScreen:[[:space:]]*Quickshell\.screens\.find\(' "$file" \
    || fail "$file does not resolve a focused Quickshell screen"
  rg -q 'Hyprland\.focusedMonitor\?\.name' "$file" \
    || fail "$file does not anchor focusedScreen to Hyprland.focusedMonitor"
  rg -q '\?\?[[:space:]]*Quickshell\.screens\[0\]' "$file" \
    || fail "$file lost its safe primary-screen fallback"
  rg -q 'screen:[[:space:]]*root\.focusedScreen' "$file" \
    || fail "$file PanelWindow is not bound to the focused screen"
done

# Desktop menu keeps the concrete invocation screen in RaohaneState because its
# popup position is tied to a pointer/desktop coordinate rather than only focus.
desktop_menu='modules/raohane/RaohaneDesktopMenu.qml'
[[ -f "$desktop_menu" ]] || fail "missing desktop menu: $desktop_menu"
rg -q 'Hyprland\.focusedMonitor\?\.name' "$desktop_menu" \
  || fail 'desktop menu no longer resolves its invocation monitor'
rg -q 'RaohaneState\.desktopMenuScreen[[:space:]]*=[[:space:]]*screen' "$desktop_menu" \
  || fail 'desktop menu no longer stores its invocation screen'
rg -q 'screen:[[:space:]]*RaohaneState\.desktopMenuScreen' "$desktop_menu" \
  || fail 'desktop menu window is not pinned to its invocation screen'

# Per-monitor surfaces use Variants/monitor models instead of a focused-screen
# overlay. Do not force the focused-screen contract onto those families.
for file in \
  modules/raohane/RaohaneBackground.qml \
  modules/raohane/RaohaneBar.qml \
  modules/raohane/RaohaneVerticalBar.qml \
  modules/raohane/RaohaneScreenFrame.qml; do
  [[ -f "$file" ]] || fail "missing per-monitor surface: $file"
done

printf 'multimonitor-boundary-audit: focused overlays and desktop menu are pinned to the intended Hyprland monitor\n'
