#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'settings-boundary-audit: %s\n' "$*" >&2
  exit 1
}

content='modules/raohane/RaohaneSettingsContent.qml'
home='modules/raohane/RaohaneSettingsHome.qml'
about='modules/raohane/RaohaneSettingsAbout.qml'
state='modules/raohane/RaohaneState.qml'
qmldir='modules/raohane/qmldir'

for path in "$content" "$home" "$about" "$state" "$qmldir"; do
  [[ -f "$path" ]] || fail "missing settings path: $path"
done

rg -q '^RaohaneSettingsAbout .*RaohaneSettingsAbout.qml$' "$qmldir" \
  || fail 'RaohaneSettingsAbout is not registered'
rg -q '^RaohaneSettingsHome .*RaohaneSettingsHome.qml$' "$qmldir" \
  || fail 'RaohaneSettingsHome is not registered'
rg -q 'property string settingsPage:' "$state" \
  || fail 'RaohaneState does not own Settings page navigation state'

for symbol in \
  'RaohaneState\.settingsPage' \
  'RaohanePaths\.nativeConfigFile' \
  'RaohaneConfig\[' \
  'sectionEntries' \
  'nativeSectionPage' \
  'RaohaneIcon[[:space:]]*\{' \
  'RaohaneSystemInfo\.'; do
  rg -q "$symbol" "$content" || fail "Settings navigation lost native dependency: $symbol"
done

for page_key in quick general bar desktop interface services hyprland profile; do
  rg -q "key: \"${page_key}\"" "$content" || fail "native Settings route is missing: $page_key"
done

if rg -n '\.\./ii/settings/pages|modules/ii/settings/pages|^import qs$|^import qs\.services$|^import qs\.modules\.common|^import qs\.modules\.ii|\bMaterialSymbol[[:space:]]*\{|\bGlobalStates\.|\bContentPage[[:space:]]*\{' "$content"; then
  fail 'Settings navigation resolves inherited settings/common/root types'
fi
if rg -n 'compatibilityConfigFile' "$content"; then
  fail 'Settings still exposes the legacy compatibility config path'
fi

for symbol in 'RaohaneConfig\.wallpaperPath' 'RaohaneNetwork\.' 'RaohaneAudio\.' 'RaohanePrivacy\.' 'RaohaneState\.settingsPage' 'RaohaneIcon[[:space:]]*\{'; do
  rg -q "$symbol" "$home" || fail "Settings Home lost native dependency: $symbol"
done
if rg -n '^import qs$|^import qs\.services$|^import qs\.modules\.common|\bConfig\.|\bNetwork\.|\bAudio\.|\bGlobalStates\.|\bMaterialSymbol[[:space:]]*\{' "$home"; then
  fail 'Settings Home regressed to inherited config/services/state/common widgets'
fi

for symbol in 'RaohaneSystemInfo\.' 'RaohaneIcon[[:space:]]*\{' 'Quickshell\.shellPath\("VERSION"\)' 'raohane doctor all'; do
  rg -q "$symbol" "$about" || fail "native About page lost required Raohane contract: $symbol"
done
if rg -n -i '^import qs$|^import qs\.services$|^import qs\.modules\.common|^import qs\.modules\.ii|end4-pC|illogical-impulse|git[[:space:]]+clone|qs[[:space:]]+-c[[:space:]]+end4' "$about"; then
  fail 'native About page contains inherited shell/runtime update plumbing'
fi

printf 'settings-boundary-audit: all active Settings routes are Raohane-owned and use native config/state\n'
