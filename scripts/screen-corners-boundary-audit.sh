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
config='modules/raohane/config/RaohaneConfig.qml'
state='modules/raohane/RaohaneState.qml'
family='panelFamilies/RaohaneFamily.qml'
qmldir='modules/raohane/qmldir'

for path in "$corners" "$round_corner" "$config" "$state" "$family" "$qmldir"; do
  [[ -f "$path" ]] || fail "missing native screen-corner path: $path"
done

[[ ! -e modules/raohane/RaohaneLegacyBridge.qml ]] \
  || fail 'retired compatibility bridge returned to screen-corner runtime boundary'

rg -q '^RaohaneRoundCorner .*RaohaneRoundCorner.qml$' "$qmldir" \
  || fail 'RaohaneRoundCorner is not registered in the native module'
rg -q '^RaohaneScreenCorners .*RaohaneScreenCorners.qml$' "$qmldir" \
  || fail 'RaohaneScreenCorners is not registered in the native module'

for symbol in \
  'RaohaneConfig\.screenRoundingMode' \
  'RaohaneConfig\.screenCornerRadius' \
  'RaohaneConfig\.hotCornersEnabled' \
  'RaohaneConfig\.deadPixelWorkaround' \
  'RaohaneState\.toggleAction' \
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

for property_name in leftSidebarOpen overlayOpen regionSelectorOpen screenTranslatorOpen oskOpen; do
  rg -q "property bool ${property_name}:" "$state" \
    || fail "RaohaneState missing native transient state: $property_name"
done
rg -q 'function toggleAction\(name: string\)' "$state" \
  || fail 'RaohaneState lost hot-corner action routing'

rg -q 'component:[[:space:]]*RaohaneScreenCorners[[:space:]]*\{' "$family" \
  || fail 'RaohaneFamily does not load native ScreenCorners'
if rg -n '^import qs\.modules\.ii\.screenCorners$|component:[[:space:]]*ScreenCorners[[:space:]]*\{' "$family"; then
  fail 'legacy ScreenCorners is active in RaohaneFamily'
fi

printf 'screen-corners-boundary-audit: native rounding, actions and transient state have no legacy reference requirement\n'
