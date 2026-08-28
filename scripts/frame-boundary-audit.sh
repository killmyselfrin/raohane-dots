#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'frame-boundary-audit: %s\n' "$*" >&2
  exit 1
}

frame='modules/raohane/RaohaneScreenFrame.qml'
config='modules/raohane/config/RaohaneConfig.qml'
bridge='modules/raohane/RaohaneLegacyBridge.qml'
family='panelFamilies/RaohaneFamily.qml'
qmldir='modules/raohane/qmldir'
legacy='modules/ii/frame/ScreenFrame.qml'

for path in "$frame" "$config" "$bridge" "$family" "$qmldir" "$legacy"; do
  [[ -f "$path" ]] || fail "missing frame migration path: $path"
done

rg -q '^RaohaneScreenFrame .*RaohaneScreenFrame.qml$' "$qmldir" \
  || fail 'RaohaneScreenFrame is not registered in the native module'

for symbol in \
  'RaohaneConfig\.frameEnabled' \
  'RaohaneConfig\.frameThickness' \
  'RaohaneConfig\.frameColor' \
  'RaohaneConfig\.frameBarSideVisible' \
  'RaohaneConfig\.barVertical' \
  'RaohaneConfig\.barBottom' \
  '\bPanelWindow[[:space:]]*\{' \
  'ExclusionMode\.Normal' \
  'WlrKeyboardFocus\.None'; do
  rg -q "$symbol" "$frame" || fail "native frame lost required contract: $symbol"
done

if rg -n '^import qs$|^import qs\.services|^import qs\.modules\.common|\bConfig\.|\bGlobalStates\.|\bAppearance\.|\bRoundCorner[[:space:]]*\{' "$frame"; then
  fail 'native frame regressed to inherited framework/widgets'
fi

for property_name in frameEnabled frameThickness frameColor frameBarSideVisible; do
  rg -q "property .* ${property_name}:" "$config" \
    || fail "RaohaneConfig missing frame property: $property_name"
done
schema_version="$(sed -nE 's/.*schemaVersion:[[:space:]]*([0-9]+).*/\1/p' "$config" | head -1)"
[[ "$schema_version" =~ ^[0-9]+$ ]] || fail 'could not read native config schema version'
(( schema_version >= 8 )) || fail 'native config schema is older than v8'
rg -q 'frame:[[:space:]]*\{' "$config" \
  || fail 'native config snapshot does not persist the frame object'

for symbol in \
  'Config\.options\.bar\.showFrame' \
  'Config\.options\.bar\.frameThickness' \
  'Config\.options\.bar\.frameColor' \
  'RaohaneConfig\.frameEnabled' \
  'RaohaneConfig\.frameThickness' \
  'RaohaneConfig\.frameColor' \
  'RaohaneConfig\.frameBarSideVisible' \
  'legacyFrameBarSideVisible'; do
  rg -q "$symbol" "$bridge" || fail "legacy bridge lost frame migration symbol: $symbol"
done

rg -q 'component:[[:space:]]*RaohaneScreenFrame[[:space:]]*\{' "$family" \
  || fail 'RaohaneFamily does not load the native frame'
if rg -n '^import qs\.modules\.ii\.frame$|component:[[:space:]]*ScreenFrame[[:space:]]*\{' "$family"; then
  fail 'legacy ScreenFrame is still active in RaohaneFamily'
fi

printf 'frame-boundary-audit: native screen frame owns rendering/config while legacy frame remains migration-only\n'
