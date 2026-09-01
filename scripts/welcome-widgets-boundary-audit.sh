#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'welcome-widgets-boundary-audit: %s\n' "$*" >&2
  exit 1
}

for path in \
  modules/raohane/RaohaneWelcome.qml \
  modules/raohane/RaohaneWidgetStudio.qml \
  modules/raohane/RaohaneDesktopCanvas.qml \
  modules/raohane/RaohaneDesktopWidget.qml \
  modules/raohane/RaohaneState.qml \
  modules/raohane/config/RaohaneConfig.qml \
  defaults/native.json; do
  [[ -f "$path" ]] || fail "missing native welcome/widget path: $path"
done

for surface in RaohaneWelcome RaohaneWidgetStudio; do
  rg -q "^${surface} .*${surface}\.qml$" modules/raohane/qmldir \
    || fail "$surface is not registered in the native module"
  rg -q "component:[[:space:]]*${surface}[[:space:]]*\{" panelFamilies/RaohaneFamily.qml \
    || fail "$surface is not loaded by RaohaneFamily"
done
rg -q '^RaohaneDesktopWidget .*RaohaneDesktopWidget\.qml$' modules/raohane/qmldir \
  || fail 'desktop widget delegate is not registered'

for contract in \
  'property bool welcomeCompleted: false' \
  'property var desktopWidgets:' \
  'function sanitizeDesktopWidgets' \
  'function addDesktopWidget' \
  'function removeDesktopWidget' \
  'function moveDesktopWidget' \
  'function resetDesktopWidgets' \
  'welcomeCompleted: root\.welcomeCompleted' \
  'widgets: root\.sanitizeDesktopWidgets'; do
  rg -q "$contract" modules/raohane/config/RaohaneConfig.qml \
    || fail "native config lost contract: $contract"
done

python3 - defaults/native.json <<'PY' || fail 'native defaults lost welcome/widget schema'
import json
import pathlib
import sys

data = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
assert data["schemaVersion"] == 11
assert data["features"]["welcomeCompleted"] is False
widgets = data["desktop"]["widgets"]
assert [item["type"] for item in widgets] == ["clock", "context"]
assert all({"id", "type", "screen", "x", "y"} <= item.keys() for item in widgets)
PY

for contract in \
  'property bool welcomeOpen: false' \
  'property bool widgetStudioOpen: false' \
  'case "welcome": return welcomeOpen' \
  'case "widgetStudio": return widgetStudioOpen' \
  'function beginDesktopWidgetEdit' \
  'function endDesktopWidgetEdit'; do
  rg -q "$contract" modules/raohane/RaohaneState.qml \
    || fail "coordinated state lost contract: $contract"
done

welcome='modules/raohane/RaohaneWelcome.qml'
for contract in \
  'function maybeOpen' \
  '!RaohaneConfig\.welcomeCompleted' \
  'RaohaneConfig\.welcomeCompleted = true' \
  'RaohaneConfig\.saveNow\(\)' \
  'target: "welcome"' \
  'RaohaneTheme\.presets\.slice' \
  'RaohaneConfig\.barVertical' \
  'RaohaneConfig\.dockEnabled'; do
  rg -q "$contract" "$welcome" || fail "welcome flow lost contract: $contract"
done

studio='modules/raohane/RaohaneWidgetStudio.qml'
for widget_type in clock context media system; do
  rg -q "type: \"${widget_type}\"" "$studio" \
    || fail "Widget Studio lost ${widget_type} catalog face"
done
rg -q 'target: "widgetStudio"' "$studio" || fail 'Widget Studio IPC is missing'
rg -q 'RaohaneState\.beginDesktopWidgetEdit' "$studio" || fail 'Widget Studio does not enter coordinated arrange mode'

canvas='modules/raohane/RaohaneDesktopCanvas.qml'
for contract in \
  'target: "desktopWidgets"' \
  'WlrLayershell\.layer: RaohaneState\.desktopWidgetEditMode' \
  'wallpaperHideWhenFullscreen && fullscreenActive' \
  'String\(widget\.screen' \
  'delegate: RaohaneDesktopWidget'; do
  rg -q "$contract" "$canvas" || fail "desktop canvas lost contract: $contract"
done

widget='modules/raohane/RaohaneDesktopWidget.qml'
for contract in \
  'RaohaneConfig\.moveDesktopWidget' \
  'RaohaneConfig\.removeDesktopWidget' \
  'RaohaneContext\.' \
  'RaohaneMedia\.' \
  'RaohaneSystemInfo\.'; do
  rg -q "$contract" "$widget" || fail "desktop widget lost native dependency: $contract"
done

rg -q 'raohane welcome' README.md || fail 'README does not expose the welcome command'
rg -q 'raohane widgets open' README.md || fail 'README does not expose Widget Studio'
rg -q 'ipc welcome open' scripts/raohane || fail 'CLI welcome route is missing'
rg -q 'ipc desktopWidgets open' scripts/raohane || fail 'CLI widget route is missing'

if rg -n '^import qs\.modules\.ii|^import qs\.modules\.common|\bWidgetRegistry\b|\bWidgetLoader\b' \
  "$welcome" "$studio" "$canvas" "$widget"; then
  fail 'welcome/widget runtime resolves a retired or Serpantinum widget framework'
fi

printf 'welcome-widgets-boundary-audit: first-run persistence, native widget faces, per-monitor placement, arrange mode and CLI routes are valid\n'
