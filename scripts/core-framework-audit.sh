#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'core-framework-audit: %s\n' "$*" >&2
  exit 1
}

config_module='modules/raohane/config'
config="$config_module/RaohaneConfig.qml"
paths="$config_module/RaohanePaths.qml"
config_qmldir="$config_module/qmldir"
raohane_qmldir='modules/raohane/qmldir'
state='modules/raohane/RaohaneState.qml'
focus='modules/raohane/RaohaneFocusGrab.qml'
bar='modules/raohane/RaohaneBar.qml'
launcher='modules/raohane/RaohaneLauncher.qml'
overview='modules/raohane/RaohaneOverview.qml'
control_center='modules/raohane/RaohaneControlCenter.qml'
osd='modules/raohane/RaohaneOsd.qml'
session='modules/raohane/RaohaneSessionScreen.qml'
settings='modules/raohane/RaohaneSettings.qml'
settings_content='modules/raohane/RaohaneSettingsContentV3.qml'
settings_navigation='modules/raohane/RaohaneSettingsNavigation.qml'
settings_header='modules/raohane/RaohaneSettingsPageHeader.qml'
settings_registry='modules/raohane/RaohaneSettingsPageRegistry.qml'
settings_section_registry='modules/raohane/RaohaneSettingsSectionRegistry.qml'
settings_router='modules/raohane/RaohaneSettingsRouter.qml'
settings_section='modules/raohane/RaohaneSettingsSectionPage.qml'
settings_control='modules/raohane/RaohaneSettingsControlRow.qml'
settings_preferences='modules/raohane/RaohaneSettingsPreferences.qml'
settings_language='modules/raohane/RaohaneSettingsLanguage.qml'
backup='modules/raohane/RaohaneBackupSettings.qml'
family='panelFamilies/RaohaneFamily.qml'
shell='shell.qml'
installer='install-raohane.sh'
root_qmldir='qmldir'

required=(
  "$config" "$paths" "$config_qmldir" "$raohane_qmldir" "$state" "$focus"
  "$bar" "$launcher" "$overview" "$control_center" "$osd" "$session"
  "$settings" "$settings_content" "$settings_navigation" "$settings_header"
  "$settings_registry" "$settings_section_registry" "$settings_router"
  "$settings_section" "$settings_control" "$settings_preferences" "$settings_language" "$backup"
  "$family" "$shell" "$installer" "$root_qmldir"
)
for path in "${required[@]}"; do
  [[ -f "$path" ]] || fail "missing core framework path: $path"
done

for registration in \
  '^singleton RaohanePaths .*RaohanePaths.qml$' \
  '^singleton RaohaneConfig .*RaohaneConfig.qml$'; do
  rg -q "$registration" "$config_qmldir" || fail "missing native config registration: $registration"
done
for registration in \
  '^singleton RaohaneFocusGrab .*RaohaneFocusGrab.qml$' \
  '^singleton RaohaneState .*RaohaneState.qml$' \
  '^singleton RaohaneSettingsPageRegistry .*RaohaneSettingsPageRegistry.qml$' \
  '^singleton RaohaneSettingsSectionRegistry .*RaohaneSettingsSectionRegistry.qml$' \
  '^singleton RaohaneSettingsRouter .*RaohaneSettingsRouter.qml$' \
  '^RaohaneSettingsNavigation .*RaohaneSettingsNavigation.qml$' \
  '^RaohaneSettingsPageHeader .*RaohaneSettingsPageHeader.qml$' \
  '^RaohaneSettingsSectionPage .*RaohaneSettingsSectionPage.qml$' \
  '^RaohaneSettingsControlRow .*RaohaneSettingsControlRow.qml$' \
  '^RaohaneSettingsPreferences .*RaohaneSettingsPreferences.qml$' \
  '^RaohaneSettingsLanguage .*RaohaneSettingsLanguage.qml$'; do
  rg -q "$registration" "$raohane_qmldir" || fail "missing native module registration: $registration"
done

[[ "$(tr -d '\r' < "$root_qmldir")" == 'module qs' ]] || fail 'root qs module exports legacy types'
if rg -n 'GlobalStates|RaohaneLegacyBridge' "$root_qmldir" "$raohane_qmldir"; then
  fail 'legacy root/bridge singleton is registered in active modules'
fi

for symbol in 'StandardPaths\.standardLocations' 'Quickshell\.shellPath' 'configDirectory' 'nativeConfigFile' 'notificationsFile' 'defaultAvatarUrl'; do
  rg -q "$symbol" "$paths" || fail "RaohanePaths lost contract: $symbol"
done
if rg -n '^import qs\.|\bDirectories\.' "$paths"; then
  fail 'RaohanePaths depends on inherited path framework'
fi

rg -q 'schemaVersion:[[:space:]]*12' "$config" || fail 'RaohaneConfig schema is not v12'
rg -q 'RaohanePaths\.nativeConfigFile' "$config" || fail 'RaohaneConfig does not use RaohanePaths'
if rg -n '\bStandardPaths\.|\bDirectories\.|^import qs$|^import qs\.modules\.common|\bConfig\.' "$config"; then
  fail 'RaohaneConfig depends on inherited config/path framework'
fi
for property_name in \
  barBottom barVertical barAutoHide barAutoHidePushWindows barShowOnSuper barShowOnSuperDelay barScreenList barShowDate \
  frameEnabled frameThickness frameColor frameBarSideVisible screenRoundingMode screenCornerRadius deadPixelWorkaround \
  hotCornersEnabled hotCornerValueScroll hotCornerClickless hotCornerRegionWidth hotCornerRegionHeight \
  hotCornerBottomLeftAction hotCornerBottomRightAction hotCornerVisualize hotCornerClicklessEnd hotCornerVerticalOffset \
  oskPinned oskLayout profileDisplayName profileAvatarPath quickSliderBrightness quickSliderVolume quickSliderMic \
  contextIslandEnabled mediaOverlayEnabled integrationMode; do
  rg -q "property .* ${property_name}:" "$config" || fail "RaohaneConfig missing product property: $property_name"
done

for property_name in \
  barOpen controlCenterOpen leftSidebarOpen overlayOpen regionSelectorOpen screenTranslatorOpen oskOpen settingsOpen \
  sessionOpen osdOpen screenLocked superDown desktopMenuOpen; do
  rg -q "property bool ${property_name}:" "$state" || fail "RaohaneState missing runtime property: $property_name"
done
rg -q 'property string wallpaperSelectorTarget:' "$state" || fail 'RaohaneState missing wallpaper target routing property'
if rg -n '^[[:space:]]*property string settingsPage:|RaohaneState\.settingsPage' modules/raohane; then
  fail 'Settings page routing leaked back into global RaohaneState'
fi
for contract in \
  'function primaryOpen\(name: string\): bool' \
  'function closePrimarySurfaces\(except: string\): void' \
  'function setPrimaryOpen\(name: string, open: bool\): void' \
  'function togglePrimary\(name: string\): void' \
  'function toggleAction\(name: string\)'; do
  rg -q "$contract" "$state" || fail "RaohaneState missing action/coordinator contract: $contract"
done

rg -q '^import Quickshell\.Hyprland$' "$focus" || fail 'RaohaneFocusGrab is not bound to Hyprland'
rg -q '\bHyprlandFocusGrab[[:space:]]*\{' "$focus" || fail 'RaohaneFocusGrab does not own HyprlandFocusGrab'
if rg -n '^import qs\.|\bWM\.' "$focus"; then
  fail 'RaohaneFocusGrab depends on inherited compositor plumbing'
fi

for symbol in \
  'RaohaneConfig\.barAutoHide' 'RaohaneConfig\.barScreenList' 'RaohaneConfig\.barShowDate' \
  'RaohaneState\.barOpen' 'RaohaneState\.togglePrimary\("controlCenter"\)' 'RaohaneState\.screenLocked'; do
  rg -q "$symbol" "$bar" || fail "RaohaneBar lost native symbol: $symbol"
done
if rg -n '^import qs$|^import qs\.modules\.common|\bConfig\.|\bGlobalStates\.' "$bar"; then
  fail 'RaohaneBar regressed to inherited framework'
fi

for surface in "$launcher" "$settings" "$control_center"; do
  rg -q 'RaohaneFocusGrab\.' "$surface" || fail "$surface does not consume RaohaneFocusGrab"
  if rg -n '\bGlobalFocusGrab\.|^import qs\.services$' "$surface"; then
    fail "$surface regressed to inherited focus/services"
  fi
done
for symbol in \
  'RaohaneState\.controlCenterOpen' 'RaohaneState\.setPrimaryOpen\("controlCenter"' \
  'RaohaneNotifications\.markAllRead' 'RaohaneConfig\.profileDisplayName' 'RaohaneSystemInfo\.'; do
  rg -q "$symbol" "$control_center" || fail "RaohaneControlCenter lost native symbol: $symbol"
done
for symbol in 'RaohaneState\.osdOpen' 'RaohaneAudio\.' 'RaohaneDisplay\.' 'RaohaneConfig\.osdTimeout'; do
  rg -q "$symbol" "$osd" || fail "RaohaneOsd lost native symbol: $symbol"
done
for symbol in \
  'RaohaneState\.sessionOpen' 'RaohaneState\.screenLocked' 'RaohaneSession\.' \
  'RaohaneSessionWarnings\.' 'RaohaneSystemInfo\.' 'RaohaneConfig\.wallpaperPath'; do
  rg -q "$symbol" "$session" || fail "RaohaneSessionScreen lost native symbol: $symbol"
done

rg -q 'RaohaneState\.settingsOpen' "$settings" || fail 'RaohaneSettings does not own open state'
rg -q 'RaohaneState\.setPrimaryOpen\("settings"' "$settings" || fail 'RaohaneSettings does not use primary coordinator'
rg -q 'RaohaneSettingsContentV3[[:space:]]*\{' "$settings" || fail 'RaohaneSettings lost the unified Settings workspace'
for route in backup keybinds motion language; do
  rg -q "RaohaneSettingsRouter\.request\(\"${route}\", \"\"\)" "$settings" || fail "Settings quick action bypasses router: $route"
done
if rg -n 'preferencesOpen|backupOpen|openPreferences\(|openBackup\(|showMainSettings\(|onPreferencesRequested|onBackupRequested|onLanguageRequested' "$settings"; then
  fail 'Settings window reintroduced special overlay routing state'
fi
if rg -n '\bGlobalStates\.settingsOpen\b|^import qs$|^import qs\.modules\.common|\bMaterialSymbol[[:space:]]*\{' "$settings"; then
  fail 'RaohaneSettings regressed to inherited root/common/widgets'
fi

for symbol in \
  'RaohaneSettingsPageRegistry\.pages' 'RaohaneSettingsPageRegistry\.resolvePageIndex' \
  'RaohaneSettingsNavigation[[:space:]]*\{' 'RaohaneSettingsPageHeader[[:space:]]*\{' \
  'target:[[:space:]]*RaohaneSettingsRouter' 'function onPageRequested\(pageKey: string, controlKey: string\): void' \
  'RaohaneSettingsRouter\.request\(root\.pages\[index\]\.key, ""\)' \
  'source:[[:space:]]*root\.currentPageInfo\?\.source' 'pageOwnsHeader'; do
  rg -q "$symbol" "$settings_content" || fail "RaohaneSettingsContent lost unified coordinator contract: $symbol"
done
if rg -q 'externalSurface|RaohanePaths\.defaultAvatarUrl|RaohaneConfig\.profile(DisplayName|AvatarPath)|function componentForKind\(|sourceComponent:' "$settings_content"; then
  fail 'RaohaneSettingsContent reabsorbed routing/profile responsibilities'
fi

for symbol in \
  'RaohanePaths\.defaultAvatarUrl' 'RaohaneConfig\.profileDisplayName' 'RaohaneConfig\.profileAvatarPath' \
  'RaohaneSystemInfo\.' 'RaohaneSettingsPageRegistry\.isFirstInGroup' 'signal pageRequested\(int index\)'; do
  rg -q "$symbol" "$settings_navigation" || fail "RaohaneSettingsNavigation lost ownership contract: $symbol"
done
for symbol in 'property var pageInfo:' 'root\.pageInfo\?\.icon' 'root\.pageInfo\?\.name' 'root\.pageInfo\?\.subtitle'; do
  rg -q "$symbol" "$settings_header" || fail "RaohaneSettingsPageHeader lost ownership contract: $symbol"
done

for symbol in \
  'readonly property var pages:' 'readonly property var aliases:' 'readonly property var routeAliases:' \
  'function resolvePageIndex\(' 'function resolveRoute\(' 'function sectionEntries\(' 'function searchEntries\(' \
  'source:[[:space:]]*"RaohaneSettingsPreferences\.qml"' 'source:[[:space:]]*"RaohaneBackupSettings\.qml"' \
  'source:[[:space:]]*"RaohaneSettingsLanguage\.qml"' 'hideHeader:[[:space:]]*true' \
  'externalSurface:[[:space:]]*"displaySettings"'; do
  rg -q "$symbol" "$settings_registry" || fail "RaohaneSettingsPageRegistry lost unified route contract: $symbol"
done
for alias in keybinds shortcuts keyboard motion animations animation; do
  rg -q "\"${alias}\"[[:space:]]*:" "$settings_registry" || fail "Settings route registry lost deep alias: $alias"
done

for symbol in \
  'readonly property var extensions:' 'source:[[:space:]]*"RaohaneBarStudio\.qml"' \
  'function extension\(sectionKey: string\): var' 'function source\(sectionKey: string\): string' \
  'function ownsControl\(sectionKey: string, controlKey: string\): bool'; do
  rg -q "$symbol" "$settings_section_registry" || fail "RaohaneSettingsSectionRegistry lost extension contract: $symbol"
done

for symbol in \
  'signal pageRequested\(string pageKey, string controlKey\)' \
  'function splitRoute\(route: string, control: string\): var' \
  'function request\(route: string, control: string\): bool' \
  'function requestSearch\(section: string, key: string\): bool' \
  'RaohaneSettingsPageRegistry\.resolveRoute' 'RaohaneSettingsPageRegistry\.resolvePageIndex' \
  'RaohaneState\.setPrimaryOpen\(page\.externalSurface, true\)'; do
  rg -q "$symbol" "$settings_router" || fail "RaohaneSettingsRouter lost unified routing contract: $symbol"
done
if rg -n 'specialAliases|preferencesRequested|backupRequested|languageRequested|legacyStateBridge|onSettingsPageChanged' "$settings_router"; then
  fail 'RaohaneSettingsRouter reintroduced special/legacy route transport'
fi

for symbol in \
  'RaohaneSettingsPageRegistry\.sectionEntries' 'RaohaneSettingsSectionRegistry\.source' \
  'RaohaneSettingsSectionRegistry\.ownsControl' 'RaohaneSettingsControlRow[[:space:]]*\{' \
  'Loader[[:space:]]*\{' 'source:[[:space:]]*root\.extensionSource'; do
  rg -q "$symbol" "$settings_section" || fail "RaohaneSettingsSectionPage lost generic section composition contract: $symbol"
done
for symbol in 'RaohaneConfig\[' 'RaohaneSwitch[[:space:]]*\{' 'RaohaneIconButton[[:space:]]*\{' 'TextInput[[:space:]]*\{' 'function changeNumber\(delta: real\): void'; do
  rg -q "$symbol" "$settings_control" || fail "RaohaneSettingsControlRow lost config-bound control contract: $symbol"
done
if rg -q 'RaohaneConfig\[|RaohaneBarStudio[[:space:]]*\{|sectionKey[[:space:]]*===?[[:space:]]*"bar"' "$settings_section"; then
  fail 'RaohaneSettingsSectionPage reabsorbed config-bound or section-specific implementation'
fi

rg -q 'RaohanePreferencesHub[[:space:]]*\{' "$settings_preferences" || fail 'unified preferences page lost PreferencesHub'
rg -q 'function goTo\(control: string\): void' "$settings_preferences" || fail 'unified preferences page lost deep-link tab routing'
rg -q 'RaohaneSettingsRouter\.request\("home", ""\)' "$settings_preferences" || fail 'preferences back action bypasses Settings router'
rg -q 'RaohaneI18n\.supportedLanguages' "$settings_language" || fail 'language page lost supported-language source'
rg -q 'RaohaneI18n\.setLanguage' "$settings_language" || fail 'language page cannot apply runtime language'

if rg -n '^import qs$|\bDirectories\.|\bConfig\.|\bGlobalStates\.|\.\./ii/settings/pages|modules/ii/settings/pages|compatibilityConfigFile' \
  "$settings_content" "$settings_navigation" "$settings_header" "$settings_registry" "$settings_section_registry" "$settings_router" "$settings_section" "$settings_control" "$settings_preferences" "$settings_language"; then
  fail 'Raohane Settings architecture regressed to inherited settings/config/path framework'
fi

rg -q 'RaohaneConfig\.barVertical' "$family" || fail 'RaohaneFamily does not route bar orientation through native config'
if rg -n '^import qs\.modules\.common|^import qs\.modules\.ii|\bConfig\.|\bGlobalStates\.|\bRaohaneLegacyBridge\b' "$family"; then
  fail 'RaohaneFamily composition root depends on inherited framework'
fi

rg -q '^import "modules/raohane/config"$' "$shell" || fail 'shell bootstrap does not import native config'
rg -q 'active:[[:space:]]*RaohaneConfig\.ready' "$shell" || fail 'shell bootstrap is not gated by native config readiness'
rg -q 'component:[[:space:]]*RaohaneFamily[[:space:]]*\{' "$shell" || fail 'shell bootstrap does not load RaohaneFamily'
if rg -n '^import "modules/common"|^import "services"|\bConfig\.|\bGlobalStates\.|\bIllogicalImpulseFamily\b|\bRaohaneLegacyBridge\b' "$shell"; then
  fail 'shell bootstrap resolves inherited framework/family/bridge'
fi

rg -q '^import Quickshell\.Hyprland$' "$bar" || fail 'RaohaneBar lost direct Hyprland integration'
for symbol in \
  'HYPR_LUA_SNIPPET' 'hyprland\.lua' 'require\("raohane"\)' \
  'quickshell:raohaneLauncherToggle' 'quickshell:settingsToggle' \
  'quickshell:sidebarRightToggle' 'quickshell:raohaneMediaOverlayToggle'; do
  rg -q "$symbol" "$installer" || fail "installer lost Hyprland Lua symbol: $symbol"
done
rg -q 'hl\.bind\("SUPER \+ R"' "$installer" || fail 'installer lost SUPER+R launcher bind'
rg -q 'hl\.bind\("SUPER \+ Escape"' "$installer" || fail 'installer lost SUPER+Escape settings bind'

printf 'core-framework-audit: native paths/config/state/focus, unified registry-routed Settings workspace, primary coordinator and boot boundaries are valid\n'
