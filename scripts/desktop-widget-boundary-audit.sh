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
search='modules/raohane/RaohaneSettingsSearch.qml'
config='modules/raohane/config/RaohaneConfig.qml'
defaults='defaults/native.json'

for path in "$canvas" "$widgets" "$studio" "$settings" "$search" "$config" "$defaults"; do
  [[ -f "$path" ]] || fail "missing native widget path: $path"
done

properties=(
  desktopWidgetsEnabled desktopWidgetClock desktopWidgetContext
  desktopWidgetSystem desktopWidgetMotto desktopWidgetsCompact
)
for property_name in "${properties[@]}"; do
  rg -q "property bool ${property_name}:" "$config" \
    || fail "native config is missing $property_name"
  rg -q "on${property_name^}Changed:[[:space:]]*scheduleSave\(\)" "$config" \
    || fail "$property_name is not persisted"
  rg -q "key:[[:space:]]*\"${property_name}\"" "$settings" \
    || fail "Settings does not expose $property_name"
  rg -q "key:[[:space:]]*\"${property_name}\"" "$search" \
    || fail "Settings search does not expose $property_name"
done

jq -e '
  .schemaVersion == 11 and
  (.desktopWidgets | type == "object") and
  (.desktopWidgets.enabled | type == "boolean") and
  (.desktopWidgets.showClock | type == "boolean") and
  (.desktopWidgets.showContext | type == "boolean") and
  (.desktopWidgets.showSystem | type == "boolean") and
  (.desktopWidgets.showMotto | type == "boolean") and
  (.desktopWidgets.compact | type == "boolean")
' "$defaults" >/dev/null || fail 'native widget defaults are invalid'

for symbol in \
  'RaohaneConfig\.desktopWidgetClock' \
  'RaohaneConfig\.desktopWidgetContext' \
  'RaohaneConfig\.desktopWidgetSystem' \
  'RaohaneConfig\.desktopWidgetMotto' \
  'RaohaneConfig\.desktopWidgetsCompact' \
  'RaohaneNetwork\.' 'RaohaneAudio\.' 'RaohaneSystemInfo\.'; do
  rg -q "$symbol" "$widgets" || fail "desktop widgets lost native contract: $symbol"
done

rg -q 'RaohaneConfig\.desktopWidgetsEnabled' "$canvas" \
  || fail 'desktop canvas does not honor the widget master switch'
rg -q 'RaohaneDesktopWidgets[[:space:]]*\{' "$canvas" \
  || fail 'desktop canvas does not load the native widget composition'
rg -q 'RaohaneWidgetStudio[[:space:]]*\{' "$settings" \
  || fail 'Settings does not route through the visual Widget Studio'

if [[ -e defaults/widgets ]]; then
  find defaults/widgets -type f -print -quit | grep -q . \
    && fail 'retired inherited widget SDK returned'
fi
if rg -n '^import qs\.services$|^import qs\.modules\.common|AbstractBackgroundWidget|~/.config/inir/widgets' "$canvas" "$widgets" "$studio" "$settings" "$search"; then
  fail 'desktop widgets depend on retired inherited APIs'
fi

printf 'desktop-widget-boundary-audit: native widget config, Settings/search and desktop service boundaries are valid\n'
