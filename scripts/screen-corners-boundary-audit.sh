#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'screen-corners-boundary-audit: %s\n' "$*" >&2
  exit 1
}

corners='modules/raohane/RaohaneScreenCorners.qml'
round_corner='modules/raohane/RaohaneRoundCorner.qml'
action_registry='modules/raohane/RaohaneActionRegistry.qml'
drop_shelf='modules/raohane/services/RaohaneDropShelf.qml'
config='modules/raohane/config/RaohaneConfig.qml'
state='modules/raohane/RaohaneState.qml'
family='panelFamilies/RaohaneFamily.qml'
qmldir='modules/raohane/qmldir'

for path in "$corners" "$round_corner" "$action_registry" "$drop_shelf" "$config" "$state" "$family" "$qmldir"; do
  [[ -f "$path" ]] || fail "missing native screen-corner path: $path"
done

[[ ! -e modules/raohane/RaohaneLegacyBridge.qml ]] \
  || fail 'retired compatibility bridge returned to screen-corner runtime boundary'

rg -q '^RaohaneRoundCorner .*RaohaneRoundCorner.qml$' "$qmldir" \
  || fail 'RaohaneRoundCorner is not registered in the native module'
rg -q '^RaohaneScreenCorners .*RaohaneScreenCorners.qml$' "$qmldir" \
  || fail 'RaohaneScreenCorners is not registered in the native module'
rg -q '^singleton RaohaneActionRegistry .*RaohaneActionRegistry.qml$' "$qmldir" \
  || fail 'RaohaneActionRegistry is not registered in the native module'

for symbol in \
  'RaohaneConfig\.screenRoundingMode' \
  'RaohaneConfig\.screenCornerRadius' \
  'RaohaneConfig\.hotCornersEnabled' \
  'RaohaneConfig\.deadPixelWorkaround' \
  'RaohaneActionRegistry\.trigger' \
  'RaohaneDisplay\.setComposite' \
  'RaohaneAudio\.setVolume' \
  'Hyprland\.monitorFor' \
  'WlrLayer\.Overlay' \
  'WlrKeyboardFocus\.None'; do
  rg -q "$symbol" "$corners" || fail "native ScreenCorners lost required contract: $symbol"
done

if rg -n '^import qs$|^import qs\.services|^import qs\.modules\.common|^import qs\.modules\.ii|\bConfig\.|\bGlobalStates\.|\bAppearance\.|\bBrightness\.|(^|[^A-Za-z])Audio\.|\bRoundCorner[[:space:]]*\{' "$corners"; then
  fail 'native ScreenCorners regressed to inherited framework/services/widgets'
fi

for symbol in \
  'readonly property var actionIds:' \
  'dropShelf' \
  'aliases:[[:space:]]*\["sidebarLeftOpen"\]' \
  'aliases:[[:space:]]*\["sidebarRightOpen"\]' \
  'function normalize\(value: string\): string' \
  'function hotCornerOptions\(\): var' \
  'function trigger\(value: string, screen\): void' \
  'RaohaneState\.toggleSurface' \
  'RaohaneDropShelf\.showOnScreen'; do
  rg -q "$symbol" "$action_registry" || fail "RaohaneActionRegistry lost hot-corner contract: $symbol"
done
rg -q 'function showOnScreen\(urls, x: real, y: real, screenName\): void' "$drop_shelf" \
  || fail 'DropShelf service lost invocation-screen action contract'
rg -q 'property string targetScreenName:[[:space:]]*""' "$drop_shelf" \
  || fail 'DropShelf service lost invocation-screen state'
rg -q 'root\.targetScreenName[[:space:]]*=[[:space:]]*String\(screenName' "$drop_shelf" \
  || fail 'DropShelf service no longer records the invocation monitor'

rg -q '^import QtQuick\.Shapes$' "$round_corner" \
  || fail 'RaohaneRoundCorner does not own its QtQuick.Shapes geometry'
if rg -n '^import qs|\bAppearance\.|\bConfig\.' "$round_corner"; then
  fail 'RaohaneRoundCorner depends on inherited presentation framework'
fi

for property_name in \
  screenRoundingMode screenCornerRadius deadPixelWorkaround hotCornersEnabled \
  hotCornerValueScroll hotCornerClickless hotCornerRegionWidth hotCornerRegionHeight \
  hotCornerBottomLeftAction hotCornerBottomRightAction hotCornerVisualize \
  hotCornerClicklessEnd hotCornerVerticalOffset; do
  rg -q "property .* ${property_name}:" "$config" \
    || fail "RaohaneConfig missing native corner property: $property_name"
done
schema_version="$(sed -nE 's/.*schemaVersion:[[:space:]]*([0-9]+).*/\1/p' "$config" | head -1)"
[[ "$schema_version" =~ ^[0-9]+$ ]] || fail 'could not read native config schema version'
(( schema_version >= 9 )) || fail 'native config schema is older than v9'
rg -q 'corners:[[:space:]]*\{' "$config" \
  || fail 'native config snapshot does not persist corners'

# RaohaneState remains the stateful-surface coordinator used by ActionRegistry;
# service-backed actions are intentionally not represented as fake state flags.
for property_name in leftSidebarOpen overlayOpen regionSelectorOpen screenTranslatorOpen oskOpen; do
  rg -q "property bool ${property_name}:" "$state" \
    || fail "RaohaneState missing native transient state: $property_name"
done
rg -q 'function toggleSurface\(name: string\): void' "$state" \
  || fail 'RaohaneState lost registry-backed surface action routing'

rg -q 'component:[[:space:]]*RaohaneScreenCorners[[:space:]]*\{' "$family" \
  || fail 'RaohaneFamily does not load native ScreenCorners'
if rg -n '^import qs\.modules\.ii\.screenCorners$|component:[[:space:]]*ScreenCorners[[:space:]]*\{' "$family"; then
  fail 'legacy ScreenCorners is active in RaohaneFamily'
fi

printf 'screen-corners-boundary-audit: native rounding, declarative actions, DropShelf invocation routing and surface state have no legacy reference requirement\n'
