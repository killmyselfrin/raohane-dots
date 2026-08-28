#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'settings-boundary-audit: %s\n' "$*" >&2
  exit 1
}

content='modules/raohane/RaohaneSettingsContent.qml'
about='modules/raohane/RaohaneSettingsAbout.qml'
qmldir='modules/raohane/qmldir'

for path in "$content" "$about" "$qmldir"; do
  [[ -f "$path" ]] || fail "missing settings path: $path"
done

rg -q '^RaohaneSettingsAbout .*RaohaneSettingsAbout.qml$' "$qmldir" \
  || fail 'RaohaneSettingsAbout is not registered'
rg -q 'Qt\.resolvedUrl\("RaohaneSettingsAbout\.qml"\)' "$content" \
  || fail 'Settings navigation does not load the native About page'

for symbol in 'RaohaneIcon[[:space:]]*\{' 'RaohaneSystemInfo\.' 'RaohanePaths\.compatibilityConfigFile'; do
  rg -q "$symbol" "$content" || fail "Settings navigation lost native dependency: $symbol"
done
if rg -n '^import qs\.services$|^import qs\.modules\.common|\bMaterialSymbol[[:space:]]*\{|\bSystemInfo\.|\bUpdates\.' "$content"; then
  fail 'Settings navigation regressed to inherited common widgets/system services'
fi

for symbol in 'RaohaneSystemInfo\.' 'RaohaneIcon[[:space:]]*\{' 'Quickshell\.shellPath\("VERSION"\)' 'raohane doctor all'; do
  rg -q "$symbol" "$about" || fail "native About page lost required Raohane contract: $symbol"
done
if rg -n -i '^import qs$|^import qs\.services$|^import qs\.modules\.common|^import qs\.modules\.ii|end4-pC|illogical-impulse|git[[:space:]]+clone|qs[[:space:]]+-c[[:space:]]+end4' "$about"; then
  fail 'native About page contains inherited shell/runtime update plumbing'
fi

printf 'settings-boundary-audit: Settings chrome uses native widgets/system info and About is standalone\n'
