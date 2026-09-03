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
host='modules/raohane/RaohaneDesktopWidgetHost.qml'
clock='modules/raohane/RaohaneDesktopClockWidget.qml'
context='modules/raohane/RaohaneDesktopContextWidget.qml'
system='modules/raohane/RaohaneDesktopSystemWidget.qml'
motto='modules/raohane/RaohaneDesktopMottoWidget.qml'
studio='modules/raohane/RaohaneWidgetStudio.qml'
widget_registry='modules/raohane/RaohaneDesktopWidgetRegistry.qml'
qmldir='modules/raohane/qmldir'
settings='modules/raohane/RaohaneSettingsContentV3.qml'
registry='modules/raohane/RaohaneSettingsPageRegistry.qml'
search='modules/raohane/RaohaneSettingsSearch.qml'
config='modules/raohane/config/RaohaneConfig.qml'
defaults='defaults/native.json'

for path in "$canvas" "$widgets" "$host" "$clock" "$context" "$system" "$motto" "$studio" "$widget_registry" "$qmldir" "$settings" "$registry" "$search" "$config" "$defaults"; do
  [[ -f "$path" ]] || fail "missing native widget path: $path"
done

rg -q '^singleton RaohaneDesktopWidgetRegistry 1\.0 RaohaneDesktopWidgetRegistry\.qml$' "$qmldir" \
  || fail 'Desktop Widget Registry is not registered in the Raohane QML module'
for registration in \
  '^RaohaneDesktopWidgetHost 1\.0 RaohaneDesktopWidgetHost\.qml$' \
  '^RaohaneDesktopClockWidget 1\.0 RaohaneDesktopClockWidget\.qml$' \
  '^RaohaneDesktopContextWidget 1\.0 RaohaneDesktopContextWidget\.qml$' \
  '^RaohaneDesktopSystemWidget 1\.0 RaohaneDesktopSystemWidget\.qml$' \
  '^RaohaneDesktopMottoWidget 1\.0 RaohaneDesktopMottoWidget\.qml$'; do
  rg -q "$registration" "$qmldir" || fail "desktop widget runtime lost registration: $registration"
done

rg -q 'readonly property var widgetIds:[[:space:]]*\["clock", "context", "system", "motto"\]' "$widget_registry" \
  || fail 'Desktop Widget Registry lost the native widget ids'
for widget_id in clock context system motto; do
  rg -q "${widget_id}:[[:space:]]*\{" "$widget_registry" \
    || fail "Desktop Widget Registry lost ${widget_id} metadata"
done
for source in RaohaneDesktopClockWidget.qml RaohaneDesktopContextWidget.qml RaohaneDesktopSystemWidget.qml RaohaneDesktopMottoWidget.qml; do
  rg -q "source:[[:space:]]*\"${source}\"" "$widget_registry" \
    || fail "Desktop Widget Registry lost runtime source ${source}"
done
rg -q 'function definitions\(\): var' "$widget_registry" \
  || fail 'Desktop Widget Registry lost ordered metadata access'
rg -q 'function idsForZone\(zone: string\): var' "$widget_registry" \
  || fail 'Desktop Widget Registry lost zone metadata access'

rg -q 'RaohaneDesktopWidgetRegistry\.idsForZone\("primary"\)' "$widgets" \
  || fail 'desktop runtime no longer composes the primary registry zone'
rg -q 'RaohaneDesktopWidgetRegistry\.idsForZone\("secondary"\)' "$widgets" \
  || fail 'desktop runtime no longer composes the secondary registry zone'
rg -q 'delegate:[[:space:]]*RaohaneDesktopWidgetHost[[:space:]]*\{' "$widgets" \
  || fail 'desktop runtime no longer renders registry IDs through the shared host'
rg -q 'RaohaneDesktopWidgetRegistry\.definition\(root\.widgetId\)' "$host" \
  || fail 'desktop widget host lost registry metadata lookup'
rg -q 'RaohaneConfig\[root\.configKey\]' "$host" \
  || fail 'desktop widget host lost native enable-state binding'
rg -q 'source:[[:space:]]*root\.definition\?\.source' "$host" \
  || fail 'desktop widget host lost declarative source loading'

rg -q 'RaohaneMedia\.' "$context" || fail 'context widget lost native media service ownership'
rg -q 'RaohaneContext\.' "$context" || fail 'context widget lost live context ownership'
rg -q 'RaohaneNetwork\.' "$system" || fail 'system widget lost native network service ownership'
rg -q 'RaohaneAudio\.' "$system" || fail 'system widget lost native audio service ownership'
rg -q 'RaohaneSystemInfo\.' "$system" || fail 'system widget lost native host-status ownership'
rg -q 'Timer[[:space:]]*\{' "$clock" || fail 'clock widget lost its local idle-safe time source'
rg -q 'Move gently\. Stay present\.' "$motto" || fail 'motto widget lost native ambient copy'

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
  'RaohaneConfig\.desktopWidgetsCompact' \
  'RaohaneConfig\.desktopWidgetsLayout' \
  'RaohaneConfig\.desktopWidgetsScale' \
  'RaohaneConfig\.desktopWidgetsOpacity'; do
  rg -q "$symbol" "$widgets" || fail "desktop host lost native composition contract: $symbol"
done

rg -q 'RaohaneConfig\.desktopWidgetsEnabled' "$canvas" \
  || fail 'desktop canvas does not honor the widget master switch'
rg -q 'RaohaneDesktopWidgets[[:space:]]*\{' "$canvas" \
  || fail 'desktop canvas does not load the native widget composition'

if rg -n 'RaohaneMedia\.|RaohaneNetwork\.|RaohaneAudio\.|RaohaneSystemInfo\.' "$widgets"; then
  fail 'desktop host reabsorbed concrete widget service ownership'
fi
if [[ -e defaults/widgets ]]; then
  find defaults/widgets -type f -print -quit | grep -q . \
    && fail 'retired inherited widget SDK returned'
fi
if rg -n '^import qs\.services$|^import qs\.modules\.common|AbstractBackgroundWidget|~/.config/inir/widgets' "$canvas" "$widgets" "$host" "$clock" "$context" "$system" "$motto" "$studio" "$widget_registry" "$settings" "$registry" "$search"; then
  fail 'desktop widgets depend on retired inherited APIs'
fi

printf 'desktop-widget-boundary-audit: registry-driven widget runtime, native config, declarative Settings/search and service ownership are valid\n'
