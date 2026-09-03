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
section_registry='modules/raohane/RaohaneSettingsSectionRegistry.qml'
router='modules/raohane/RaohaneSettingsRouter.qml'
section='modules/raohane/RaohaneSettingsSectionPage.qml'
control_row='modules/raohane/RaohaneSettingsControlRow.qml'
preferences='modules/raohane/RaohaneSettingsPreferences.qml'
preferences_hub='modules/raohane/RaohanePreferencesHub.qml'
language='modules/raohane/RaohaneSettingsLanguage.qml'
backup='modules/raohane/RaohaneBackupSettings.qml'
home='modules/raohane/RaohaneSettingsHome.qml'
catalog='modules/raohane/RaohaneThemeCatalog.qml'
bar_studio='modules/raohane/RaohaneBarStudio.qml'
about='modules/raohane/RaohaneSettingsAbout.qml'
config='modules/raohane/config/RaohaneConfig.qml'
state='modules/raohane/RaohaneState.qml'
qmldir='modules/raohane/qmldir'

required=(
  "$settings" "$search" "$content" "$navigation" "$header" "$registry" "$section_registry" "$router"
  "$section" "$control_row" "$preferences" "$preferences_hub" "$language" "$backup" "$home" "$catalog"
  "$bar_studio" "$about" "$config" "$state" "$qmldir"
)
for path in "${required[@]}"; do
  [[ -f "$path" ]] || fail "missing settings path: $path"
done

for registration in \
  '^RaohaneSettingsSearch .*RaohaneSettingsSearch.qml$' \
  '^RaohaneSettingsContentV3 .*RaohaneSettingsContentV3.qml$' \
  '^RaohaneSettingsNavigation .*RaohaneSettingsNavigation.qml$' \
  '^RaohaneSettingsPageHeader .*RaohaneSettingsPageHeader.qml$' \
  '^singleton RaohaneSettingsPageRegistry .*RaohaneSettingsPageRegistry.qml$' \
  '^singleton RaohaneSettingsSectionRegistry .*RaohaneSettingsSectionRegistry.qml$' \
  '^singleton RaohaneSettingsRouter .*RaohaneSettingsRouter.qml$' \
  '^RaohaneSettingsSectionPage .*RaohaneSettingsSectionPage.qml$' \
  '^RaohaneSettingsControlRow .*RaohaneSettingsControlRow.qml$' \
  '^RaohaneSettingsPreferences .*RaohaneSettingsPreferences.qml$' \
  '^RaohaneSettingsLanguage .*RaohaneSettingsLanguage.qml$' \
  '^RaohaneBackupSettings .*RaohaneBackupSettings.qml$'; do
  rg -q "$registration" "$qmldir" || fail "missing Settings registration: $registration"
done

rg -q 'RaohaneSettingsContentV3[[:space:]]*\{' "$settings" || fail 'Settings window is not routed through Settings V3'
if rg -n 'RaohaneState\.settingsPage|^[[:space:]]*property string settingsPage:' modules/raohane; then
  fail 'legacy Settings page state returned to runtime'
fi

for contract in \
  'readonly property var pages:' 'readonly property var aliases:' 'readonly property var routeAliases:' \
  'readonly property var sectionOrder:' 'readonly property var sectionSchemas:' \
  'function resolvePageIndex\(requestedValue: string\): int' \
  'function resolveRoute\(requestedValue: string, control: string\): var' \
  'function sectionSchema\(key: string\): var' 'function sectionEntries\(key: string\): var' \
  'function searchEntries\(\): var'; do
  rg -q "$contract" "$registry" || fail "Settings page registry lost contract: $contract"
done
for page_key in home themes widgets interface bar quick general desktop displays hyprland preferences services profile backup language about; do
  rg -q "key:[[:space:]]*\"${page_key}\"" "$registry" || fail "native Settings route is missing: $page_key"
done
for group in PERSONALIZE SHELL SYSTEM; do
  rg -q "$group" "$registry" || fail "Settings page registry lost navigation group: $group"
done
for source in \
  RaohaneSettingsPreferences.qml RaohaneBackupSettings.qml RaohaneSettingsLanguage.qml; do
  rg -q "source:[[:space:]]*\"${source//./\\.}\"" "$registry" || fail "Settings registry lost unified page source: $source"
done
rg -q 'hideHeader:[[:space:]]*true' "$registry" || fail 'Preferences page no longer owns its local header'
rg -q 'externalSurface:[[:space:]]*"displaySettings"' "$registry" || fail 'Display Settings route lost external surface ownership'
for alias in keybinds shortcuts keyboard motion animations animation; do
  rg -q "\"${alias}\"[[:space:]]*:" "$registry" || fail "Settings deep alias is missing: $alias"
done
for alias in restore 'backup & restore' locale; do
  rg -q "\"${alias}\"[[:space:]]*:" "$registry" || fail "Settings page alias is missing: $alias"
done

for contract in \
  'signal pageRequested\(string pageKey, string controlKey\)' \
  'function splitRoute\(route: string, control: string\): var' \
  'function request\(route: string, control: string\): bool' \
  'function requestSearch\(section: string, key: string\): bool' \
  'RaohaneSettingsPageRegistry\.resolveRoute' \
  'RaohaneSettingsPageRegistry\.resolvePageIndex' \
  'RaohaneState\.setPrimaryOpen\("settings", true\)' \
  'RaohaneState\.setPrimaryOpen\(page\.externalSurface, true\)'; do
  rg -q "$contract" "$router" || fail "Settings router lost unified route contract: $contract"
done
if rg -n 'specialAliases|preferencesRequested|backupRequested|languageRequested|legacyStateBridge|onSettingsPageChanged' "$router"; then
  fail 'Settings router reintroduced special or legacy route transport'
fi

for symbol in \
  'RaohaneSettingsPageRegistry\.pages' 'RaohaneSettingsPageRegistry\.resolvePageIndex' \
  'RaohaneSettingsNavigation[[:space:]]*\{' 'RaohaneSettingsPageHeader[[:space:]]*\{' \
  'target:[[:space:]]*RaohaneSettingsRouter' 'function onPageRequested\(pageKey: string, controlKey: string\): void' \
  'pageOwnsHeader' 'source:[[:space:]]*root\.currentPageInfo\?\.source' \
  'pageLoader\.item\.hasOwnProperty\("sectionKey"\)' 'typeof pageLoader\.item\.goTo'; do
  rg -q "$symbol" "$content" || fail "Settings coordinator lost unified page-loader contract: $symbol"
done
if rg -q 'externalSurface|function componentForKind\(|sourceComponent:|RaohaneConfig\.profile|RaohanePaths\.defaultAvatarUrl' "$content"; then
  fail 'Settings coordinator reabsorbed imperative routing or profile ownership'
fi

for symbol in \
  'RaohanePaths\.defaultAvatarUrl' 'RaohaneConfig\.profileDisplayName' 'RaohaneConfig\.profileAvatarPath' \
  'RaohaneSystemInfo\.' 'RaohaneSettingsPageRegistry\.isFirstInGroup' 'signal pageRequested\(int index\)'; do
  rg -q "$symbol" "$navigation" || fail "Settings navigation lost contract: $symbol"
done
for symbol in 'property var pageInfo:' 'root\.pageInfo\?\.icon' 'root\.pageInfo\?\.name' 'root\.pageInfo\?\.subtitle'; do
  rg -q "$symbol" "$header" || fail "Settings page header lost contract: $symbol"
done

for contract in \
  'readonly property var extensions:' 'source:[[:space:]]*"RaohaneBarStudio\.qml"' \
  'function extension\(sectionKey: string\): var' 'function source\(sectionKey: string\): string' \
  'function ownsControl\(sectionKey: string, controlKey: string\): bool'; do
  rg -q "$contract" "$section_registry" || fail "Settings section registry lost contract: $contract"
done

mapfile -t page_sources < <(rg -o 'source:[[:space:]]*"[A-Za-z0-9_/-]+\.qml"' "$registry" | sed -E 's/.*"([^"]+)"/\1/' | sort -u)
[[ "${#page_sources[@]}" -ge 8 ]] || fail 'Settings registry exposes too few declarative page sources'
for source in "${page_sources[@]}"; do
  [[ -f "modules/raohane/$source" ]] || fail "Settings registry points to missing page source: $source"
done

for symbol in \
  'RaohaneSettingsPageRegistry\.sectionEntries' 'RaohaneSettingsSectionRegistry\.source' \
  'RaohaneSettingsSectionRegistry\.ownsControl' 'RaohaneSettingsControlRow[[:space:]]*\{' \
  'Loader[[:space:]]*\{' 'source:[[:space:]]*root\.extensionSource'; do
  rg -q "$symbol" "$section" || fail "native section renderer lost generic composition contract: $symbol"
done
if rg -n 'RaohaneConfig\[|RaohaneSwitch[[:space:]]*\{|RaohaneIconButton[[:space:]]*\{|TextInput[[:space:]]*\{|RaohaneBarStudio[[:space:]]*\{|sectionKey[[:space:]]*===?[[:space:]]*"bar"' "$section"; then
  fail 'generic Settings section renderer reabsorbed control or section-specific implementation'
fi
for symbol in \
  'RaohaneConfig\[' 'RaohaneSwitch[[:space:]]*\{' 'RaohaneIconButton[[:space:]]*\{' \
  'TextInput[[:space:]]*\{' 'function changeNumber\(delta: real\): void' 'Keys\.onPressed'; do
  rg -q "$symbol" "$control_row" || fail "Settings control row lost config-bound contract: $symbol"
done

rg -q 'RaohanePreferencesHub[[:space:]]*\{' "$preferences" || fail 'Preferences route lost reusable PreferencesHub'
rg -q 'function goTo\(control: string\): void' "$preferences" || fail 'Preferences route lost deep-link selection'
rg -q 'preferences\.section[[:space:]]*=' "$preferences" || fail 'Preferences route cannot select requested tab'
rg -q 'RaohaneSettingsRouter\.request\("home", ""\)' "$preferences" || fail 'Preferences back button bypasses Settings router'
for tab in keybinds motion; do
  rg -q "root\.section[[:space:]]*===?[[:space:]]*\"${tab}\"" "$preferences_hub" || fail "PreferencesHub lost tab: $tab"
done

rg -q 'RaohaneI18n\.supportedLanguages' "$language" || fail 'Language page lost supported language model'
rg -q 'RaohaneI18n\.language' "$language" || fail 'Language page lost selected-state binding'
rg -q 'RaohaneI18n\.setLanguage' "$language" || fail 'Language page cannot apply language'
rg -q 'FileDialog[[:space:]]*\{' "$backup" || fail 'Backup page lost native file workflow'
rg -q 'RaohaneBackup\.(exportBackup|restoreBackup)' "$backup" || fail 'Backup page bypasses native backup service'

for route in backup keybinds motion language; do
  rg -q "RaohaneSettingsRouter\.request\(\"${route}\", \"\"\)" "$settings" || fail "Settings quick action bypasses router: $route"
done
rg -q 'settingsContent\.pageOwnsHeader' "$settings" || fail 'Settings top chrome does not respect page-owned header'
rg -q 'Qt\.ControlModifier' "$settings" || fail 'Settings lost Ctrl+F search shortcut'
rg -q 'settingsSearch\.focusSearch\(\)' "$settings" || fail 'Settings lost keyboard search focus'
if rg -n 'preferencesOpen|backupOpen|openPreferences\(|openBackup\(|showMainSettings\(|onPreferencesRequested|onBackupRequested|onLanguageRequested' "$settings"; then
  fail 'Settings window reintroduced special overlay state'
fi

rg -q 'RaohaneSettingsPageRegistry\.searchEntries\(\)' "$search" || fail 'global Settings search is not registry-backed'
rg -q 'RaohaneSettingsRouter\.requestSearch\(entry\.section, entry\.key\)' "$search" || fail 'global Settings search bypasses router'
for key in themePreset barModuleLayout desktopWidgetsLayout keybinds motion backup language; do
  rg -q "key:[[:space:]]*\"${key}\"" "$registry" || fail "Settings registry lost search route: $key"
done

rg -q 'Open native\.json' "$home" || fail 'Settings Home no longer exposes native config entry point'
rg -q 'RaohaneSettingsRouter\.request\(page, ""\)' "$home" || fail 'Settings Home bypasses centralized router'
rg -q 'RaohaneTheme\.presets' "$catalog" || fail 'Theme Library lost shared preset catalog'
rg -q 'RaohaneConfig\.themePreset[[:space:]]*=' "$catalog" || fail 'Theme Library cannot apply theme through native config'
for contract in 'RaohaneConfig\.barModuleLayout' 'RaohaneConfig\.barVerticalModuleLayout' 'RaohaneBarModuleRegistry\.sanitizeLayout'; do
  rg -q "$contract" "$bar_studio" || fail "Bar Studio lost native contract: $contract"
done
for symbol in 'RaohaneSystemInfo\.' 'Quickshell\.shellPath\("VERSION"\)' 'raohane doctor all'; do
  rg -q "$symbol" "$about" || fail "About page lost native contract: $symbol"
done

mapfile -t registry_keys < <(rg -o 'type:[[:space:]]*"(toggle|number|text)",[[:space:]]*key:[[:space:]]*"[A-Za-z0-9_]+"' "$registry" | sed -E 's/.*key:[[:space:]]*"([A-Za-z0-9_]+)"/\1/' | sort -u)
[[ "${#registry_keys[@]}" -gt 0 ]] || fail 'could not discover native Settings control keys'
for key in "${registry_keys[@]}" themePreset barModuleLayout desktopWidgetsLayout; do
  rg -q "property [^:]+ ${key}:" "$config" || fail "Settings registry points to non-native config key: $key"
done

if rg -n '\.\./ii/settings/pages|modules/ii/settings/pages|^import qs$|^import qs\.services$|^import qs\.modules\.common|^import qs\.modules\.ii|\bGlobalStates\.' \
  "$content" "$navigation" "$header" "$registry" "$section_registry" "$router" "$section" "$control_row" "$preferences" "$language" "$settings" "$search"; then
  fail 'Settings architecture resolves inherited settings/common/root types'
fi

printf 'settings-boundary-audit: all Settings routes share one registry/router/workspace, with generic sections, reusable control rows, preferences, backup and language pages\n'
