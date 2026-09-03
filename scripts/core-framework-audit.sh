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
family='panelFamilies/RaohaneFamily.qml'
shell='shell.qml'
installer='install-raohane.sh'
root_qmldir='qmldir'

for path in "$config" "$paths" "$config_qmldir" "$raohane_qmldir" "$state" "$focus" "$bar" "$launcher" "$overview" "$control_center" "$osd" "$session" "$settings" "$settings_content" "$settings_navigation" "$settings_header" "$settings_registry" "$settings_section_registry" "$settings_router" "$settings_section" "$settings_control" "$family" "$shell" "$installer" "$root_qmldir"; do
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
  '^RaohaneSettingsControlRow .*RaohaneSettingsControlRow.qml$'; do
  rg -q "$registration" "$raohane_qmldir" || fail "missing native module registration: $registration"
done

[[ "$(tr -d '\r' < "$root_qmldir")" == 'module qs' ]] \
  || fail 'root qs module exports legacy types'
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
  barBottom barVertical barAutoHide barAutoHidePushWindows \
  barShowOnSuper barShowOnSuperDelay barScreenList barShowDate \
  frameEnabled frameThickness frameColor frameBarSideVisible \
  screenRoundingMode screenCornerRadius deadPixelWorkaround \
  hotCornersEnabled hotCornerValueScroll hotCornerClickless \
  hotCornerRegionWidth hotCornerRegionHeight hotCornerBottomLeftAction \
  hotCornerBottomRightAction hotCornerVisualize hotCornerClicklessEnd \
  hotCornerVerticalOffset oskPinned oskLayout \
  profileDisplayName profileAvatarPath \
  quickSliderBrightness quickSliderVolume quickSliderMic \
  contextIslandEnabled mediaOverlayEnabled integrationMode; do
  rg -q "property .* ${property_name}:" "$config" \
    || fail "RaohaneConfig missing product property: $property_name"
done

for property_name in \
  barOpen controlCenterOpen leftSidebarOpen overlayOpen regionSelectorOpen \
  screenTranslatorOpen oskOpen settingsOpen sessionOpen osdOpen screenLocked \
  superDown desktopMenuOpen; do
  rg -q "property bool ${property_name}:" "$state" \
    || fail "RaohaneState missing runtime property: $property_name"
done
rg -q 'property string wallpaperSelectorTarget:' "$state" \
  || fail 'RaohaneState missing wallpaper target routing property'
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
  'RaohaneConfig\.barAutoHide' 'RaohaneConfig\.barScreenList' \
  'RaohaneConfig\.barShowDate' 'RaohaneState\.barOpen' \
  'RaohaneState\.togglePrimary\("controlCenter"\)' 'RaohaneState\.screenLocked'; do
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
  'RaohaneNotifications\.markAllRead' 'RaohaneConfig\.profileDisplayName' \
  'RaohaneSystemInfo\.' 'RaohaneIcon[[:space:]]*\{'; do
  rg -q "$symbol" "$control_center" || fail "RaohaneControlCenter lost native symbol: $symbol"
done
if rg -n '^import qs$|^import qs\.modules\.common|\bConfig\.|\bGlobalStates\.|\bMaterialSymbol[[:space:]]*\{' "$control_center"; then
  fail 'RaohaneControlCenter regressed to inherited framework/widgets'
fi

for symbol in 'RaohaneState\.osdOpen' 'RaohaneAudio\.' 'RaohaneDisplay\.' 'RaohaneConfig\.osdTimeout'; do
  rg -q "$symbol" "$osd" || fail "RaohaneOsd lost native symbol: $symbol"
done
if rg -n '^import qs$|\bGlobalStates\.|(^|[^A-Za-z])Audio\.|(^|[^A-Za-z])Brightness\.|(^|[^A-Za-z])Hyprsunset\.' "$osd"; then
  fail 'RaohaneOsd regressed to inherited state/services'
fi

for symbol in \
  'RaohaneState\.sessionOpen' 'RaohaneState\.screenLocked' \
  'RaohaneSession\.' 'RaohaneSessionWarnings\.' 'RaohaneSystemInfo\.' \
  'RaohaneConfig\.wallpaperPath' 'RaohaneIcon[[:space:]]*\{'; do
  rg -q "$symbol" "$session" || fail "RaohaneSessionScreen lost native symbol: $symbol"
done
if rg -n '^import qs$|^import qs\.services$|^import qs\.modules\.common|\bGlobalStates\.|\bConfig\.|\bMaterialSymbol[[:space:]]*\{' "$session"; then
  fail 'RaohaneSessionScreen regressed to inherited framework/widgets'
fi

rg -q 'RaohaneState\.settingsOpen' "$settings" || fail 'RaohaneSettings does not own open state'
rg -q 'RaohaneState\.setPrimaryOpen\("settings"' "$settings" || fail 'RaohaneSettings does not use primary coordinator'
if rg -n '\bGlobalStates\.settingsOpen\b|^import qs$|^import qs\.modules\.common|\bMaterialSymbol[[:space:]]*\{' "$settings"; then
  fail 'RaohaneSettings regressed to inherited root/common/widgets'
fi

for symbol in \
  'RaohaneSettingsPageRegistry\.pages' \
  'RaohaneSettingsPageRegistry\.resolvePageIndex' \
  'RaohaneSettingsNavigation[[:space:]]*\{' \
  'RaohaneSettingsPageHeader[[:space:]]*\{' \
  'target:[[:space:]]*RaohaneSettingsRouter' \
  'function onPageRequested\(pageKey: string, controlKey: string\): void' \
  'RaohaneSettingsRouter\.request\(root\.pages\[index\]\.key, ""\)' \
  'source:[[:space:]]*root\.currentPageInfo\?\.source'; do
  rg -q "$symbol" "$settings_content" || fail "RaohaneSettingsContent lost router-backed coordinator contract: $symbol"
done
if rg -q 'externalSurface|RaohanePaths\.defaultAvatarUrl|RaohaneConfig\.profile(DisplayName|AvatarPath)|ScrollBar\.vertical|function componentForKind\(|sourceComponent:|RaohaneSettingsSectionPage[[:space:]]*\{' "$settings_content"; then
  fail 'RaohaneSettingsContent reabsorbed route/profile/navigation presentation or imperative page routing'
fi

for symbol in \
  'RaohanePaths\.defaultAvatarUrl' \
  'RaohaneConfig\.profileDisplayName' \
  'RaohaneConfig\.profileAvatarPath' \
  'RaohaneSystemInfo\.' \
  'RaohaneSettingsPageRegistry\.isFirstInGroup' \
  'RaohaneSettingsPageRegistry\.resolvePageIndex\("profile"\)' \
  'signal pageRequested\(int index\)'; do
  rg -q "$symbol" "$settings_navigation" || fail "RaohaneSettingsNavigation lost ownership contract: $symbol"
done
for symbol in \
  'property var pageInfo:' \
  'root\.pageInfo\?\.icon' \
  'root\.pageInfo\?\.name' \
  'root\.pageInfo\?\.subtitle'; do
  rg -q "$symbol" "$settings_header" || fail "RaohaneSettingsPageHeader lost ownership contract: $symbol"
done

for symbol in \
  'readonly property var pages:' 'readonly property var aliases:' \
  'source:[[:space:]]*"RaohaneSettingsHome\.qml"' \
  'source:[[:space:]]*"RaohaneThemeCatalog\.qml"' \
  'source:[[:space:]]*"RaohaneWidgetStudio\.qml"' \
  'source:[[:space:]]*"RaohaneSettingsSectionPage\.qml"' \
  'source:[[:space:]]*"RaohaneSettingsAbout\.qml"' \
  'externalSurface:[[:space:]]*"displaySettings"' \
  'desktopWidgetsEnabled' 'function sectionEntries\(' 'function searchEntries\('; do
  rg -q "$symbol" "$settings_registry" || fail "RaohaneSettingsPageRegistry lost declarative native contract: $symbol"
done
for symbol in \
  'readonly property var extensions:' \
  'source:[[:space:]]*"RaohaneBarStudio\.qml"' \
  'controlKeys:[[:space:]]*\["barModuleLayout"\]' \
  'function extension\(sectionKey: string\): var' \
  'function source\(sectionKey: string\): string' \
  'function ownsControl\(sectionKey: string, controlKey: string\): bool'; do
  rg -q "$symbol" "$settings_section_registry" || fail "RaohaneSettingsSectionRegistry lost extension contract: $symbol"
done
for symbol in \
  'signal pageRequested\(string pageKey, string controlKey\)' \
  'readonly property var specialAliases:' \
  'function splitRoute\(route: string, control: string\): var' \
  'function request\(route: string, control: string\): bool' \
  'function requestSearch\(section: string, key: string\): bool' \
  'RaohaneSettingsPageRegistry\.resolvePageIndex' \
  'RaohaneState\.setPrimaryOpen\(page\.externalSurface, true\)'; do
  rg -q "$symbol" "$settings_router" || fail "RaohaneSettingsRouter lost routing contract: $symbol"
done
if rg -n 'legacyStateBridge|onSettingsPageChanged' "$settings_router"; then
  fail 'RaohaneSettingsRouter reintroduced legacy state routing'
fi
for symbol in \
  'RaohaneSettingsPageRegistry\.sectionEntries' \
  'RaohaneSettingsSectionRegistry\.source' \
  'RaohaneSettingsSectionRegistry\.ownsControl' \
  'RaohaneSettingsControlRow[[:space:]]*\{' \
  'Loader[[:space:]]*\{' \
  'source:[[:space:]]*root\.extensionSource'; do
  rg -q "$symbol" "$settings_section" || fail "RaohaneSettingsSectionPage lost generic section composition contract: $symbol"
done
for symbol in 'RaohaneConfig\[' 'RaohaneSwitch[[:space:]]*\{' 'RaohaneIconButton[[:space:]]*\{' 'TextInput[[:space:]]*\{' 'function changeNumber\(delta: real\): void'; do
  rg -q "$symbol" "$settings_control" || fail "RaohaneSettingsControlRow lost config-bound control contract: $symbol"
done
if rg -q 'RaohaneConfig\[|RaohaneSwitch[[:space:]]*\{|RaohaneIconButton[[:space:]]*\{|TextInput[[:space:]]*\{|RaohaneBarStudio[[:space:]]*\{|sectionKey[[:space:]]*===?[[:space:]]*"bar"' "$settings_section"; then
  fail 'RaohaneSettingsSectionPage reabsorbed config-bound or section-specific implementation'
fi
if rg -n '^import qs$|\bDirectories\.|\bConfig\.|\bGlobalStates\.|\.\./ii/settings/pages|modules/ii/settings/pages|compatibilityConfigFile' \
  "$settings_content" "$settings_navigation" "$settings_header" "$settings_registry" "$settings_section_registry" "$settings_router" "$settings_section" "$settings_control"; then
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
  'hl\.unbind\("SUPER \+ SUPER_L"\)' 'hl\.unbind\("SUPER \+ SUPER_R"\)' \
  'quickshell:raohaneLauncherToggle' 'quickshell:settingsToggle' \
  'quickshell:sidebarRightToggle' 'quickshell:raohaneMediaOverlayToggle'; do
  rg -q "$symbol" "$installer" || fail "installer lost Hyprland Lua symbol: $symbol"
done
rg -q 'hl\.bind\("SUPER \+ R"' "$installer" || fail 'installer lost SUPER+R launcher bind'
rg -q 'hl\.bind\("SUPER \+ Escape"' "$installer" || fail 'installer lost SUPER+Escape settings bind'
rg -q 'hl\.dsp\.focus\(\{ workspace = workspace \}\)' "$installer" || fail 'installer lost workspace focus binds'
rg -q 'hl\.dsp\.window\.move\(\{ workspace = workspace \}\)' "$installer" || fail 'installer lost move-window workspace binds'

printf 'core-framework-audit: native paths/config/state/focus/settings router without legacy route state, coordinator/navigation/header/page+section registries/control-row, primary coordinator and boot boundaries are valid\n'
