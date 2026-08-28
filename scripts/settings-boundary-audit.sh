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
bridge='modules/raohane/RaohaneLegacyBridge.qml'
qmldir='modules/raohane/qmldir'

for path in "$content" "$home" "$about" "$state" "$bridge" "$qmldir"; do
  [[ -f "$path" ]] || fail "missing settings path: $path"
done

rg -q '^RaohaneSettingsAbout .*RaohaneSettingsAbout.qml$' "$qmldir" \
  || fail 'RaohaneSettingsAbout is not registered'
rg -q 'Qt\.resolvedUrl\("RaohaneSettingsAbout\.qml"\)' "$content" \
  || fail 'Settings navigation does not load the native About page'
rg -q 'property string settingsPage:' "$state" \
  || fail 'RaohaneState does not own Settings page navigation state'

for symbol in 'RaohaneState\.settingsPage = GlobalStates\.settingsPage' 'GlobalStates\.settingsPage = RaohaneState\.settingsPage' 'onSettingsPageChanged'; do
  rg -q "$symbol" "$bridge" || fail "legacy bridge lost Settings page synchronization: $symbol"
done

for symbol in 'RaohaneIcon[[:space:]]*\{' 'RaohaneSystemInfo\.' 'RaohanePaths\.compatibilityConfigFile' 'RaohaneState\.settingsPage'; do
  rg -q "$symbol" "$content" || fail "Settings navigation lost native dependency: $symbol"
done
if rg -n '^import qs\.services$|^import qs\.modules\.common|\bMaterialSymbol[[:space:]]*\{|\bSystemInfo\.|\bUpdates\.|\bGlobalStates\.' "$content"; then
  fail 'Settings navigation regressed to inherited common/widgets/system/state services'
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

printf 'settings-boundary-audit: native Settings state/Home/About are isolated; legacy page routing stays inside the bridge\n'
