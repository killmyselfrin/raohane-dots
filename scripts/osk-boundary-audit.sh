#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'osk-boundary-audit: %s\n' "$*" >&2
  exit 1
}

osk='modules/raohane/RaohaneOnScreenKeyboard.qml'
content='modules/raohane/RaohaneOskContent.qml'
key='modules/raohane/RaohaneOskKey.qml'
layout='modules/raohane/osk/layouts.js'
ydotool='modules/raohane/services/RaohaneYdotool.qml'
config='modules/raohane/config/RaohaneConfig.qml'
family='panelFamilies/RaohaneFamily.qml'
state='modules/raohane/RaohaneState.qml'
qmldir='modules/raohane/qmldir'
services_qmldir='modules/raohane/services/qmldir'
features='install/arch/features.txt'
legacy='modules/ii/onScreenKeyboard/OnScreenKeyboard.qml'

for path in "$osk" "$content" "$key" "$layout" "$ydotool" "$config" "$family" "$state" "$qmldir" "$services_qmldir" "$features" "$legacy"; do
  [[ -f "$path" ]] || fail "missing OSK migration path: $path"
done

for registration in \
  '^RaohaneOskKey .*RaohaneOskKey.qml$' \
  '^RaohaneOskContent .*RaohaneOskContent.qml$' \
  '^RaohaneOnScreenKeyboard .*RaohaneOnScreenKeyboard.qml$'; do
  rg -q "$registration" "$qmldir" || fail "missing native OSK registration: $registration"
done
rg -q '^singleton RaohaneYdotool .*RaohaneYdotool.qml$' "$services_qmldir" \
  || fail 'RaohaneYdotool is not registered in native services'

for symbol in \
  'RaohaneState\.oskOpen' \
  'RaohaneConfig\.oskPinned' \
  'RaohaneConfig\.oskLayout' \
  'RaohaneYdotool\.releaseAllKeys' \
  'IpcHandler[[:space:]]*\{' \
  'target:[[:space:]]*"osk"' \
  'name:[[:space:]]*"oskToggle"' \
  'WlrLayer\.Overlay'; do
  rg -q "$symbol" "$osk" || fail "native OSK lost runtime contract: $symbol"
done

for config_symbol in \
  'property bool oskPinned:' \
  'property string oskLayout:' \
  'osk:[[:space:]]*\{' \
  'onOskPinnedChanged:[[:space:]]*scheduleSave\(\)' \
  'onOskLayoutChanged:[[:space:]]*scheduleSave\(\)'; do
  rg -q "$config_symbol" "$config" || fail "native config lost OSK persistence contract: $config_symbol"
done

for file in "$osk" "$content" "$key" "$ydotool"; do
  if rg -n '^import qs$|^import qs\.services$|^import qs\.modules\.common|\bConfig\.|\bGlobalStates\.|\bAppearance\.|\bYdotool\.' "$file"; then
    fail "$file regressed to inherited OSK framework/services"
  fi
done

rg -q '^import qs\.modules\.raohane\.config$' "$osk" || fail 'native OSK does not import Raohane config'
rg -q 'RaohaneYdotool\.press' "$key" || fail 'native key does not press through RaohaneYdotool'
rg -q 'RaohaneYdotool\.release' "$key" || fail 'native key does not release through RaohaneYdotool'
rg -q 'import "osk/layouts\.js" as Layouts' "$content" || fail 'native OSK does not own its layout data'
rg -q 'Quickshell\.execDetached' "$ydotool" || fail 'RaohaneYdotool does not own ydotool execution'
rg -q '"ydotool"' "$ydotool" || fail 'RaohaneYdotool lost executable contract'
rg -q '^ydotool$' "$features" || fail 'Arch feature dependencies do not include ydotool'

rg -q 'property bool oskOpen:' "$state" || fail 'RaohaneState does not own OSK open state'
rg -q 'component:[[:space:]]*RaohaneOnScreenKeyboard[[:space:]]*\{' "$family" \
  || fail 'RaohaneFamily does not load native OSK'
if rg -n '^import qs\.modules\.ii\.onScreenKeyboard$|component:[[:space:]]*OnScreenKeyboard[[:space:]]*\{' "$family"; then
  fail 'legacy OnScreenKeyboard is still active in RaohaneFamily'
fi

printf 'osk-boundary-audit: native keyboard UI, persisted preferences, ydotool service, layout data and package boundary are valid\n'
