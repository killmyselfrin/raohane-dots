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
navigation='modules/raohane/RaohaneSettingsNavigation.qml'
header='modules/raohane/RaohaneSettingsPageHeader.qml'
registry='modules/raohane/RaohaneSettingsPageRegistry.qml'
section='modules/raohane/RaohaneSettingsSectionPage.qml'
home='modules/raohane/RaohaneSettingsHome.qml'
catalog='modules/raohane/RaohaneThemeCatalog.qml'
bar_studio='modules/raohane/RaohaneBarStudio.qml'
about='modules/raohane/RaohaneSettingsAbout.qml'
config='modules/raohane/config/RaohaneConfig.qml'
state='modules/raohane/RaohaneState.qml'
qmldir='modules/raohane/qmldir'

for path in "$settings" "$search" "$content" "$navigation" "$header" "$registry" "$section" "$home" "$catalog" "$bar_studio" "$about" "$config" "$state" "$qmldir"; do
  [[ -f "$path" ]] || fail "missing settings path: $path"
done

for registration in \
  '^RaohaneSettingsSearch .*RaohaneSettingsSearch.qml$' \
  '^RaohaneSettingsContentV3 .*RaohaneSettingsContentV3.qml$' \
  '^RaohaneSettingsNavigation .*RaohaneSettingsNavigation.qml$' \
  '^RaohaneSettingsPageHeader .*RaohaneSettingsPageHeader.qml$' \
  '^singleton RaohaneSettingsPageRegistry .*RaohaneSettingsPageRegistry.qml$' \
  '^RaohaneSettingsSectionPage .*RaohaneSettingsSectionPage.qml$' \
  '^RaohaneSettingsAbout .*RaohaneSettingsAbout.qml$' \
  '^RaohaneSettingsHome .*RaohaneSettingsHome.qml$' \
  '^RaohaneThemeCatalog .*RaohaneThemeCatalog.qml$' \
  '^RaohaneBarStudio .*RaohaneBarStudio.qml$'; do
  rg -q "$registration" "$qmldir" || fail "missing Settings registration: $registration"
done

rg -q 'RaohaneSettingsContentV3[[:space:]]*\{' "$settings" \
  || fail 'Settings window is not routed through the active Settings V3 coordinator'
rg -q 'property string settingsPage:' "$state" \
  || fail 'RaohaneState does not own Settings page navigation state'

# Content owns coordination only: route/deep-link state, page animation and
# declarative loading. Navigation and header presentation are extracted.
for symbol in \
  'RaohaneState\.settingsPage' \
  'RaohaneSettingsPageRegistry\.pages' \
  'RaohaneSettingsPageRegistry\.resolvePageIndex' \
  'RaohaneSettingsNavigation[[:space:]]*\{' \
  'RaohaneSettingsPageHeader[[:space:]]*\{' \
  'pageLoader\.item\.hasOwnProperty\("sectionKey"\)' \
  'source:[[:space:]]*root\.currentPageInfo\?\.source' \
  'externalSurface' \
  'RaohaneSystemInfo\.'; do
  rg -q "$symbol" "$content" || fail "Settings coordinator lost native contract: $symbol"
done
if rg -q 'function sectionEntries\(|function sectionDescription\(|function componentForKind\(|sourceComponent:|RaohaneConfig\.profile|RaohanePaths\.defaultAvatarUrl|ScrollBar\.vertical' "$content"; then
  fail 'Settings coordinator reabsorbed schema, profile/nav presentation or imperative page routing'
fi

for symbol in \
  'property var pages:' \
  'property int currentPage:' \
  'property bool compact:' \
  'signal pageRequested\(int index\)' \
  'RaohaneSettingsPageRegistry\.isFirstInGroup' \
  'RaohaneSettingsPageRegistry\.resolvePageIndex\("profile"\)' \
  'RaohaneConfig\.profileDisplayName' \
  'RaohaneConfig\.profileAvatarPath' \
  'RaohanePaths\.defaultAvatarUrl' \
  'RaohaneSystemInfo\.' \
  'text:[[:space:]]*qsTr\("System settings"\)'; do
  rg -q "$symbol" "$navigation" || fail "Settings navigation lost contract: $symbol"
done
for symbol in \
  'property var pageInfo:' \
  'property bool compact:' \
  'root\.pageInfo\?\.icon' \
  'root\.pageInfo\?\.name' \
  'root\.pageInfo\?\.subtitle' \
  'RaohaneTheme\.borderFaint'; do
  rg -q "$symbol" "$header" || fail "Settings page header lost contract: $symbol"
done

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
rg -q 'externalSurface:[[:space:]]*"displaySettings"' "$registry" \
  || fail 'Display Settings route lost external surface ownership'

mapfile -t page_sources < <(rg -o 'source:[[:space:]]*"[A-Za-z0-9_/-]+\.qml"' "$registry" \
  | sed -E 's/.*"([^"]+)"/\1/' | sort -u)
[[ "${#page_sources[@]}" -ge 5 ]] || fail 'Settings registry exposes too few declarative page sources'
for source in "${page_sources[@]}"; do
  [[ -f "modules/raohane/$source" ]] || fail "Settings registry points to missing page source: $source"
done
for source in RaohaneSettingsHome.qml RaohaneThemeCatalog.qml RaohaneWidgetStudio.qml RaohaneSettingsSectionPage.qml RaohaneSettingsAbout.qml; do
  rg -q "source:[[:space:]]*\"${source}\"" "$registry" \
    || fail "Settings registry lost declarative page source: $source"
done

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
rg -q 'source:[[:space:]]*"RaohaneThemeCatalog\.qml"' "$registry" \
  || fail 'Settings registry does not load the native Theme Library'
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

rg -q 'RaohaneSettingsPageRegistry\.searchEntries\(\)' "$search" \
  || fail 'global Settings search is not registry-backed'
for key in themePreset barModuleLayout desktopWidgetsLayout; do
  rg -q "key:[[:space:]]*\"${key}\"" "$registry" \
    || fail "Settings registry lost search-only native key: $key"
done

if rg -n '\.\./ii/settings/pages|modules/ii/settings/pages|^import qs$|^import qs\.services$|^import qs\.modules\.common|^import qs\.modules\.ii|\bMaterialSymbol[[:space:]]*\{|\bGlobalStates\.|\bContentPage[[:space:]]*\{' \
  "$content" "$navigation" "$header" "$registry" "$section" "$settings" "$search" "$catalog" "$bar_studio"; then
  fail 'Settings architecture resolves inherited settings/common/root types'
fi
if rg -n 'compatibilityConfigFile|~/.config/raohane/config\.json|qsTr\("config\.json"\)' \
  "$content" "$navigation" "$header" "$registry" "$section" "$settings" "$search" "$catalog" "$bar_studio"; then
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

printf 'settings-boundary-audit: coordinator, extracted navigation/header, declarative registry-loaded pages, native sections, Theme Library, Bar Studio and global search are Raohane-owned\n'
