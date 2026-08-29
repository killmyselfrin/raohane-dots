#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'settings-boundary-audit: %s\n' "$*" >&2
  exit 1
}

settings='modules/raohane/RaohaneSettings.qml'
search='modules/raohane/RaohaneSettingsSearch.qml'
content='modules/raohane/RaohaneSettingsContent.qml'
home='modules/raohane/RaohaneSettingsHome.qml'
about='modules/raohane/RaohaneSettingsAbout.qml'
config='modules/raohane/config/RaohaneConfig.qml'
state='modules/raohane/RaohaneState.qml'
qmldir='modules/raohane/qmldir'

for path in "$settings" "$search" "$content" "$home" "$about" "$config" "$state" "$qmldir"; do
  [[ -f "$path" ]] || fail "missing settings path: $path"
done

for registration in \
  '^RaohaneSettingsSearch .*RaohaneSettingsSearch.qml$' \
  '^RaohaneSettingsAbout .*RaohaneSettingsAbout.qml$' \
  '^RaohaneSettingsHome .*RaohaneSettingsHome.qml$'; do
  rg -q "$registration" "$qmldir" || fail "missing Settings registration: $registration"
done
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

for contract in \
  'key:[[:space:]]*"barShowOnSuper"' \
  'Reveal on Super' \
  'native\.json' \
  'Live settings · ~/.config/raohane/native\.json'; do
  rg -q "$contract" "$content" || fail "Settings lost release UX contract: $contract"
done

if rg -n '\.\./ii/settings/pages|modules/ii/settings/pages|^import qs$|^import qs\.services$|^import qs\.modules\.common|^import qs\.modules\.ii|\bMaterialSymbol[[:space:]]*\{|\bGlobalStates\.|\bContentPage[[:space:]]*\{' "$content" "$settings" "$search"; then
  fail 'Settings navigation resolves inherited settings/common/root types'
fi
if rg -n 'compatibilityConfigFile|~/.config/raohane/config\.json|qsTr\("config\.json"\)' "$content" "$settings" "$search"; then
  fail 'Settings still exposes the retired compatibility config path/name'
fi

# Final visible Settings pass: global search, keyboard focus, exact page/control
# routing and runtime status are all first-class native UX.
for symbol in \
  'RaohaneSettingsSearch[[:space:]]*\{' \
  'Qt\.ControlModifier' \
  'settingsSearch\.focusSearch\(\)' \
  'function status\(\): string' \
  'function page\(page: string\)'; do
  rg -q "$symbol" "$settings" || fail "Settings window lost final UX contract: $symbol"
done
for symbol in \
  'function focusSearch\(\)' \
  'function activate\(index: int\)' \
  'RaohaneState\.settingsPage = entry\.section \+ ":" \+ entry\.key' \
  'Qt\.Key_Down' \
  'Qt\.Key_Up' \
  'Qt\.Key_Return' \
  'No matching setting'; do
  rg -q "$symbol" "$search" || fail "global Settings search lost contract: $symbol"
done

mapfile -t search_keys < <(rg -o 'key:[[:space:]]*"[A-Za-z0-9_]+"' "$search" \
  | sed -E 's/.*"([A-Za-z0-9_]+)"/\1/' | sort -u)
for key in "${search_keys[@]}"; do
  rg -q "property [^:]+ ${key}:" "$config" \
    || fail "global Settings search points to non-native config key: $key"
done

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

printf 'settings-boundary-audit: native routes, global search, keyboard navigation and native config UX are Raohane-owned\n'
