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
family='panelFamilies/RaohaneFamily.qml'
qmldir='modules/raohane/qmldir'

for path in "$frame" "$config" "$family" "$qmldir"; do
  [[ -f "$path" ]] || fail "missing native frame path: $path"
done

[[ ! -e modules/raohane/RaohaneLegacyBridge.qml ]] \
  || fail 'retired compatibility bridge returned to frame runtime boundary'

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

if rg -n '^import qs$|^import qs\.services|^import qs\.modules\.common|^import qs\.modules\.ii|\bConfig\.|\bGlobalStates\.|\bAppearance\.|\bRoundCorner[[:space:]]*\{' "$frame"; then
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

rg -q 'component:[[:space:]]*RaohaneScreenFrame[[:space:]]*\{' "$family" \
  || fail 'RaohaneFamily does not load the native frame'
if rg -n '^import qs\.modules\.ii\.frame$|component:[[:space:]]*ScreenFrame[[:space:]]*\{' "$family"; then
  fail 'legacy ScreenFrame is active in RaohaneFamily'
fi

printf 'frame-boundary-audit: native screen frame owns rendering and persisted config with no legacy reference requirement\n'
