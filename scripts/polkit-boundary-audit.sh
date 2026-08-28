#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'polkit-boundary-audit: %s\n' "$*" >&2
  exit 1
}

family='panelFamilies/RaohaneFamily.qml'
polkit='modules/raohane/RaohanePolkit.qml'
qmldir='modules/raohane/qmldir'

[[ -f "$polkit" ]] || fail 'RaohanePolkit.qml is missing'
rg -q '^RaohanePolkit .*RaohanePolkit.qml$' "$qmldir" \
  || fail 'RaohanePolkit is not registered in the native module'
rg -q 'component: RaohanePolkit \{\}' "$family" \
  || fail 'RaohaneFamily does not load the native Polkit surface'
if rg -n '^import qs\.modules\.ii\.polkit$|component: Polkit \{\}' "$family"; then
  fail 'RaohaneFamily regressed to the inherited Polkit surface'
fi

for symbol in \
  '^import Quickshell\.Services\.Polkit$' \
  '\bPolkitAgent[[:space:]]*\{' \
  'cancelAuthenticationRequest\(\)' \
  '\.submit\(inputField\.text\)' \
  'WlrKeyboardFocus\.Exclusive'; do
  rg -q "$symbol" "$polkit" || fail "RaohanePolkit lost required native contract: $symbol"
done

if rg -n '^import qs$|^import qs\.services$|modules\.common|PolkitService|FullscreenPolkitWindow|MaterialSymbol|\bAppearance\.|\bConfig\.|\bGlobalStates\.' "$polkit"; then
  fail 'RaohanePolkit depends on inherited service/common/UI framework'
fi

printf 'polkit-boundary-audit: native Polkit agent and authentication UI boundary are valid\n'
