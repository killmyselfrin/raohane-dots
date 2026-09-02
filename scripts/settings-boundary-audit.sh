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
registry='modules/raohane/RaohaneSettingsPageRegistry.qml'
section='modules/raohane/RaohaneSettingsSectionPage.qml'
home='modules/raohane/RaohaneSettingsHome.qml'
catalog='modules/raohane/RaohaneThemeCatalog.qml'
bar_studio='modules/raohane/RaohaneBarStudio.qml'
about='modules/raohane/RaohaneSettingsAbout.qml'
config='modules/raohane/config/RaohaneConfig.qml'
state='modules/raohane/RaohaneState.qml'
qmldir='modules/raohane/qmldir'

for path in "$settings" "$search" "$content" "$registry" "$section" "$home" "$catalog" "$bar_studio" "$about" "$config" "$state" "$qmldir"; do
  [[ -f "$path" ]] || fail "missing settings path: $path"
done

for registration in \
  '^RaohaneSettingsSearch .*RaohaneSettingsSearch.qml$' \
  '^RaohaneSettingsContentV3 .*RaohaneSettingsContentV3.qml$' \
  '^singleton RaohaneSettingsPageRegistry .*RaohaneSettingsPageRegistry.qml$' \
  '^RaohaneSettingsSectionPage .*RaohaneSettingsSectionPage.qml$' \
  '^RaohaneSettingsAbout .*RaohaneSettingsAbout.qml$' \
  '^RaohaneSettingsHome .*RaohaneSettingsHome.qml$' \
  '^RaohaneThemeCatalog .*RaohaneThemeCatalog.qml$' \
  '^RaohaneBarStudio .*RaohaneBarStudio.qml$'; do
  rg -q "$registration" "$qmldir" || fail "missing Settings registration: $registration"
done

rg -q 'RaohaneSettingsContentV3[[:space:]]*\{' "$settings" \
  || fail 'Settings window is not routed through the active Settings V3 shell'
rg -q 'property string settingsPage:' "$state" \
  || fail 'RaohaneState does not own Settings page navigation state'

# Content owns navigation and loading only; page metadata/schema live in the
# registry and generic controls render in the extracted section page.
for symbol in \
  'RaohaneState\.settingsPage' \
  'RaohaneSettingsPageRegistry\.pages' \
  'RaohaneSettingsPageRegistry\.resolvePageIndex' \
  'RaohaneSettingsPageRegistry\.isFirstInGroup' \
  'RaohaneSettingsSectionPage[[:space:]]*\{' \
  'componentForKind' \
  'RaohaneSystemInfo\.'; do
  rg -q "$symbol" "$content" || fail "Settings shell lost registry-backed dependency: $symbol"
done
if rg -q 'function sectionEntries\(|function sectionDescription\(' "$content"; then
  fail 'Settings shell reabsorbed section schema owned by the registry'
fi

for contract in \
  'readonly property var pages:' \
  'readonly property var aliases:' \
  'function resolvePageIndex\(requestedValue: string\): int' \
  'function sectionDescription\(key: string\): string' \
  'function sectionEntries\(key: string\): var' \
  'function searchEntries\(\): var'; do
  rg -q "$contract" "$registry" || fail "Settings page registry lost contract: $contract"
done
for page_key in home themes widgets interface bar quick general desktop displays hyprland services profile about; do
  rg -q "key:[[:space:]]*\"${page_key}\"" "$registry" || fail "native Settings route is missing: $page_key"
done
for group in PERSONALIZE SHELL SYSTEM; do
  rg -q "$group" "$registry" || fail "Settings page registry lost navigation group: $group"
done
for contract in \
  'key:[[:space:]]*"barShowOnSuper"' \
  'Reveal on Super' \
  'module composition' \
  'Bar & Dock' \
  'Media & OSD' \
  'Desktop & Spaces' \
  'Desktop Widgets'; do
  rg -q "$contract" "$registry" || fail "Settings registry lost grouped UX contract: $contract"
done
rg -q 'text:[[:space:]]*qsTr\("System settings"\)' "$content" \
  || fail 'Settings shell lost sidebar hierarchy'

for symbol in \
  'RaohaneSettingsPageRegistry\.sectionEntries' \
  'RaohaneConfig\[' \
  'RaohaneSwitch[[:space:]]*\{' \
  'RaohaneIconButton[[:space:]]*\{' \
  'RaohaneBarStudio[[:space:]]*\{' \
  'needle\.includes\("module"\)'; do
  rg -q "$symbol" "$section" || fail "native section renderer lost contract: $symbol"
done

rg -q 'Open native\.json' "$home" \
  || fail 'Settings Home no longer exposes the native config entry point'

rg -q 'RaohaneThemeCatalog[[:space:]]*\{' "$content" \
  || fail 'Settings shell does not load the native Theme Library'
rg -q 'RaohaneTheme\.presets' "$catalog" \
  || fail 'Theme Library does not consume the shared Raohane preset catalog'
rg -q 'RaohaneConfig\.themePreset[[:space:]]*=' "$catalog" \
  || fail 'Theme Library does not apply theme selection through native config'
rg -q 'property string themePreset:' "$config" \
  || fail 'native config does not own selected theme state'

for contract in \
  'RaohaneConfig\.barModuleLayout' \
  'RaohaneConfig\.barVerticalModuleLayout' \
  'RaohaneBarModuleRegistry\.sanitizeLayout' \
  'function resetLayout\(\): void'; do
  rg -q "$contract" "$bar_studio" || fail "Bar Studio lost native Settings contract: $contract"
done

# Search and rendered controls consume the same registry schema. Search-only
# routes are explicitly listed in the registry rather than duplicated in UI.
rg -q 'RaohaneSettingsPageRegistry\.searchEntries\(\)' "$search" \
  || fail 'global Settings search is not registry-backed'
for key in themePreset barModuleLayout desktopWidgetsLayout; do
  rg -q "key:[[:space:]]*\"${key}\"" "$registry" \
    || fail "Settings registry lost search-only native key: $key"
done

if rg -n '\.\./ii/settings/pages|modules/ii/settings/pages|^import qs$|^import qs\.services$|^import qs\.modules\.common|^import qs\.modules\.ii|\bMaterialSymbol[[:space:]]*\{|\bGlobalStates\.|\bContentPage[[:space:]]*\{' \
  "$content" "$registry" "$section" "$settings" "$search" "$catalog" "$bar_studio"; then
  fail 'Settings navigation resolves inherited settings/common/root types'
fi
if rg -n 'compatibilityConfigFile|~/.config/raohane/config\.json|qsTr\("config\.json"\)' \
  "$content" "$registry" "$section" "$settings" "$search" "$catalog" "$bar_studio"; then
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

mapfile -t registry_keys < <(rg -o 'type:[[:space:]]*"(toggle|number|text)",[[:space:]]*key:[[:space:]]*"[A-Za-z0-9_]+"' "$registry" \
  | sed -E 's/.*key:[[:space:]]*"([A-Za-z0-9_]+)"/\1/' | sort -u)
[[ "${#registry_keys[@]}" -gt 0 ]] || fail 'could not discover native Settings control keys from registry'
for key in "${registry_keys[@]}" themePreset barModuleLayout desktopWidgetsLayout; do
  rg -q "property [^:]+ ${key}:" "$config" \
    || fail "Settings registry points to non-native config key: $key"
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

printf 'settings-boundary-audit: registry-backed Settings V3, extracted native sections, Theme Library, Bar Studio, global search and keyboard navigation are Raohane-owned\n'
