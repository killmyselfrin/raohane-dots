#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'desktop-widget-boundary-audit: %s\n' "$*" >&2
  exit 1
}

canvas='modules/raohane/RaohaneDesktopCanvas.qml'
widgets='modules/raohane/RaohaneDesktopWidgets.qml'
studio='modules/raohane/RaohaneWidgetStudio.qml'
settings='modules/raohane/RaohaneSettingsContentV3.qml'
registry='modules/raohane/RaohaneSettingsPageRegistry.qml'
search='modules/raohane/RaohaneSettingsSearch.qml'
config='modules/raohane/config/RaohaneConfig.qml'
defaults='defaults/native.json'

for path in "$canvas" "$widgets" "$studio" "$settings" "$registry" "$search" "$config" "$defaults"; do
  [[ -f "$path" ]] || fail "missing native widget path: $path"
done

rg -q 'RaohaneSettingsPageRegistry\.searchEntries\(\)' "$search" \
  || fail 'Settings search is not driven by the native page registry'
rg -q 'key:[[:space:]]*"widgets".*source:[[:space:]]*"RaohaneWidgetStudio\.qml"' "$registry" \
  || fail 'Settings registry does not declaratively route the visual Widget Studio'
rg -q 'source:[[:space:]]*root\.currentPageInfo\?\.source' "$settings" \
  || fail 'Settings shell does not load widget pages through registry sources'

for property_name in desktopWidgetsLayout desktopWidgetsScale desktopWidgetsOpacity; do
  rg -q "property (string|real) ${property_name}:" "$config" \
    || fail "native config is missing $property_name"
  rg -q "on${property_name^}Changed:[[:space:]]*scheduleSave\(\)" "$config" \
    || fail "$property_name is not persisted"
  rg -q "key:[[:space:]]*\"${property_name}\"" "$registry" \
    || fail "Settings registry/search schema does not expose $property_name"
done

rg -q 'readonly property var layouts:' "$studio" \
  || fail 'Widget Studio is missing native composition presets'
rg -q 'desktopWidgetsLayout === modelData\.key' "$studio" \
  || fail 'Widget Studio presets are not connected to native config'

properties=(
  desktopWidgetsEnabled desktopWidgetClock desktopWidgetContext
  desktopWidgetSystem desktopWidgetMotto desktopWidgetsCompact
)
for property_name in "${properties[@]}"; do
  rg -q "property bool ${property_name}:" "$config" \
    || fail "native config is missing $property_name"
  rg -q "on${property_name^}Changed:[[:space:]]*scheduleSave\(\)" "$config" \
    || fail "$property_name is not persisted"
  rg -q "key:[[:space:]]*\"${property_name}\"" "$registry" \
    || fail "Settings registry does not expose $property_name"
done

jq -e '
  .schemaVersion == 12 and
  (.desktopWidgets | type == "object") and
  (.desktopWidgets.enabled | type == "boolean") and
  (.desktopWidgets.showClock | type == "boolean") and
  (.desktopWidgets.showContext | type == "boolean") and
  (.desktopWidgets.showSystem | type == "boolean") and
  (.desktopWidgets.showMotto | type == "boolean") and
  (.desktopWidgets.compact | type == "boolean") and
  (.desktopWidgets.layout == "balanced") and
  (.desktopWidgets.scale | type == "number") and
  (.desktopWidgets.opacity | type == "number")
' "$defaults" >/dev/null || fail 'native widget defaults are invalid'

for symbol in \
  'RaohaneConfig\.desktopWidgetClock' \
  'RaohaneConfig\.desktopWidgetContext' \
  'RaohaneConfig\.desktopWidgetSystem' \
  'RaohaneConfig\.desktopWidgetMotto' \
  'RaohaneConfig\.desktopWidgetsCompact' \
  'RaohaneConfig\.desktopWidgetsLayout' \
  'RaohaneConfig\.desktopWidgetsScale' \
  'RaohaneConfig\.desktopWidgetsOpacity' \
  'RaohaneNetwork\.' 'RaohaneAudio\.' 'RaohaneSystemInfo\.'; do
  rg -q "$symbol" "$widgets" || fail "desktop widgets lost native contract: $symbol"
done

rg -q 'RaohaneConfig\.desktopWidgetsEnabled' "$canvas" \
  || fail 'desktop canvas does not honor the widget master switch'
rg -q 'RaohaneDesktopWidgets[[:space:]]*\{' "$canvas" \
  || fail 'desktop canvas does not load the native widget composition'

if [[ -e defaults/widgets ]]; then
  find defaults/widgets -type f -print -quit | grep -q . \
    && fail 'retired inherited widget SDK returned'
fi
if rg -n '^import qs\.services$|^import qs\.modules\.common|AbstractBackgroundWidget|~/.config/inir/widgets' "$canvas" "$widgets" "$studio" "$settings" "$registry" "$search"; then
  fail 'desktop widgets depend on retired inherited APIs'
fi

printf 'desktop-widget-boundary-audit: native widget config, declarative registry-backed Settings/search and desktop service boundaries are valid\n'
