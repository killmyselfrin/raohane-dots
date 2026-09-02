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
content='modules/raohane/RaohaneSettingsContentV3.qml'
home='modules/raohane/RaohaneSettingsHome.qml'
catalog='modules/raohane/RaohaneThemeCatalog.qml'
about='modules/raohane/RaohaneSettingsAbout.qml'
config='modules/raohane/config/RaohaneConfig.qml'
state='modules/raohane/RaohaneState.qml'
qmldir='modules/raohane/qmldir'

for path in "$settings" "$search" "$content" "$home" "$catalog" "$about" "$config" "$state" "$qmldir"; do
  [[ -f "$path" ]] || fail "missing settings path: $path"
done

for registration in \
  '^RaohaneSettingsSearch .*RaohaneSettingsSearch.qml$' \
  '^RaohaneSettingsContentV3 .*RaohaneSettingsContentV3.qml$' \
  '^RaohaneSettingsAbout .*RaohaneSettingsAbout.qml$' \
  '^RaohaneSettingsHome .*RaohaneSettingsHome.qml$' \
  '^RaohaneThemeCatalog .*RaohaneThemeCatalog.qml$'; do
  rg -q "$registration" "$qmldir" || fail "missing Settings registration: $registration"
done
rg -q 'RaohaneSettingsContentV3[[:space:]]*\{' "$settings" \
  || fail 'Settings window is not routed through the active grouped Settings V3 layout'
rg -q 'property string settingsPage:' "$state" \
  || fail 'RaohaneState does not own Settings page navigation state'

for symbol in \
  'RaohaneState\.settingsPage' \
  'RaohaneConfig\[' \
  'sectionEntries' \
  'nativeSectionPage' \
  'RaohaneSurface[[:space:]]*\{' \
  'RaohaneSwitch[[:space:]]*\{' \
  'RaohaneIcon[[:space:]]*\{' \
  'RaohaneSystemInfo\.'; do
  rg -q "$symbol" "$content" || fail "Settings navigation lost native dependency: $symbol"
done

for page_key in themes quick general bar desktop widgets interface services hyprland profile; do
  rg -q "key: \"${page_key}\"" "$content" || fail "native Settings route is missing: $page_key"
done

for contract in \
  'key:[[:space:]]*"barShowOnSuper"' \
  'Reveal on Super' \
  'PERSONALIZE' \
  'SHELL' \
  'SYSTEM' \
  'Bar & Dock' \
  'Media & OSD' \
  'Desktop & Spaces' \
  'Desktop Widgets' \
  'System settings'; do
  rg -q "$contract" "$content" || fail "Settings lost grouped minimal UX contract: $contract"
done
rg -q 'Open native\.json' "$home" \
  || fail 'Settings Home no longer exposes the native config entry point'

rg -q 'RaohaneThemeCatalog[[:space:]]*\{' "$content" \
  || fail 'Settings does not load the native Theme Library'
rg -q 'RaohaneTheme\.presets' "$catalog" \
  || fail 'Theme Library does not consume the shared Raohane preset catalog'
rg -q 'RaohaneConfig\.themePreset[[:space:]]*=' "$catalog" \
  || fail 'Theme Library does not apply theme selection through native config'
rg -q 'property string themePreset:' "$config" \
  || fail 'native config does not own selected theme state'
rg -q 'key:[[:space:]]*"themePreset"' "$search" \
  || fail 'global Settings search does not expose the Theme Library'

if rg -n '\.\./ii/settings/pages|modules/ii/settings/pages|^import qs$|^import qs\.services$|^import qs\.modules\.common|^import qs\.modules\.ii|\bMaterialSymbol[[:space:]]*\{|\bGlobalStates\.|\bContentPage[[:space:]]*\{' "$content" "$settings" "$search" "$catalog"; then
  fail 'Settings navigation resolves inherited settings/common/root types'
fi
if rg -n 'compatibilityConfigFile|~/.config/raohane/config\.json|qsTr\("config\.json"\)' "$content" "$settings" "$search" "$catalog"; then
  fail 'Settings still exposes the retired compatibility config path/name'
fi

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

printf 'settings-boundary-audit: active grouped Settings V3 routes, Theme Library, global search, keyboard navigation and native config UX are Raohane-owned\n'
