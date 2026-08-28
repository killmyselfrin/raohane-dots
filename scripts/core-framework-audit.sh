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
bridge='modules/raohane/RaohaneLegacyBridge.qml'
bar='modules/raohane/RaohaneBar.qml'
launcher='modules/raohane/RaohaneLauncher.qml'
overview='modules/raohane/RaohaneOverview.qml'
control_center='modules/raohane/RaohaneControlCenter.qml'
osd='modules/raohane/RaohaneOsd.qml'
session='modules/raohane/RaohaneSessionScreen.qml'
settings='modules/raohane/RaohaneSettings.qml'
settings_content='modules/raohane/RaohaneSettingsContent.qml'
family='panelFamilies/RaohaneFamily.qml'
shell='shell.qml'
installer='install-raohane.sh'

for path in "$config" "$paths" "$config_qmldir" "$raohane_qmldir" "$state" "$focus" "$bridge" "$bar" "$launcher" "$overview" "$control_center" "$osd" "$session" "$settings" "$settings_content" "$family" "$shell" "$installer"; do
  [[ -f "$path" ]] || fail "missing core framework path: $path"
done

for registration in \
  '^singleton RaohanePaths .*RaohanePaths.qml$' \
  '^singleton RaohaneConfig .*RaohaneConfig.qml$'; do
  rg -q "$registration" "$config_qmldir" || fail "missing native config registration: $registration"
done
rg -q '^singleton RaohaneFocusGrab .*RaohaneFocusGrab.qml$' "$raohane_qmldir" \
  || fail 'RaohaneFocusGrab is not registered'
rg -q '^singleton RaohaneState .*RaohaneState.qml$' "$raohane_qmldir" \
  || fail 'RaohaneState is not registered'

for symbol in 'StandardPaths\.standardLocations' 'Quickshell\.shellPath' 'configDirectory' 'nativeConfigFile' 'notificationsFile' 'defaultAvatarUrl'; do
  rg -q "$symbol" "$paths" || fail "RaohanePaths lost contract: $symbol"
done
if rg -n '^import qs\.|\bDirectories\.' "$paths"; then
  fail 'RaohanePaths depends on inherited path framework'
fi

rg -q 'schemaVersion:[[:space:]]*9' "$config" || fail 'RaohaneConfig schema is not v9'
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
  hotCornerVerticalOffset profileDisplayName profileAvatarPath; do
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
for property_name in settingsPage wallpaperSelectorTarget; do
  rg -q "property string ${property_name}:" "$state" \
    || fail "RaohaneState missing routing property: $property_name"
done
rg -q 'function toggleAction\(name: string\)' "$state" \
  || fail 'RaohaneState missing action router'

rg -q '^import Quickshell\.Hyprland$' "$focus" \
  || fail 'RaohaneFocusGrab is not bound to Hyprland'
rg -q '\bHyprlandFocusGrab[[:space:]]*\{' "$focus" \
  || fail 'RaohaneFocusGrab does not own HyprlandFocusGrab'
if rg -n '^import qs\.|\bWM\.' "$focus"; then
  fail 'RaohaneFocusGrab depends on inherited compositor plumbing'
fi

for symbol in \
  'RaohaneConfig\.barAutoHide' 'RaohaneConfig\.barScreenList' \
  'RaohaneConfig\.barShowDate' 'RaohaneState\.barOpen' \
  'RaohaneState\.controlCenterOpen' 'RaohaneState\.screenLocked'; do
  rg -q "$symbol" "$bar" || fail "RaohaneBar lost native symbol: $symbol"
done
if rg -n '^import qs$|^import qs\.modules\.common|\bConfig\.|\bGlobalStates\.' "$bar"; then
  fail 'RaohaneBar regressed to inherited framework'
fi

for surface in "$launcher" "$settings" "$control_center"; do
  rg -q 'RaohaneFocusGrab\.' "$surface" || fail "$surface does not consume RaohaneFocusGrab"
  if rg -n '\bGlobalFocusGrab\.|^import qs\.services$' "$surface"; then
    fail "$surface regressed to inherited focus/services'
  fi
done

for symbol in \
  'RaohaneState\.controlCenterOpen' 'RaohaneNotifications\.markAllRead' \
  'RaohaneConfig\.wallpaperPath' 'RaohaneSystemInfo\.' 'RaohaneIcon[[:space:]]*\{'; do
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
if rg -n '\bGlobalStates\.settingsOpen\b|^import qs$|^import qs\.modules\.common|\bMaterialSymbol[[:space:]]*\{' "$settings"; then
  fail 'RaohaneSettings regressed to inherited root/common/widgets'
fi

for symbol in 'RaohanePaths\.defaultAvatarUrl' 'RaohanePaths\.compatibilityConfigFile' \
  'RaohaneConfig\.profileDisplayName' 'RaohaneConfig\.profileAvatarPath'; do
  rg -q "$symbol" "$settings_content" || fail "RaohaneSettingsContent lost native contract: $symbol"
done
if rg -n '^import qs$|\bDirectories\.|\bConfig\.|\bGlobalStates\.' "$settings_content"; then
  fail 'RaohaneSettingsContent regressed to inherited root/config/state/path framework'
fi

# The compatibility bridge is retained only for lazy legacy settings pages.
# It may mirror native state when explicitly used, but must never be part of
# RaohaneFamily startup.
rg -q 'RaohaneConfig' "$bridge" || fail 'compatibility bridge is disconnected from RaohaneConfig'
if rg -n '\bRaohaneLegacyBridge\.load\b' "$family"; then
  fail 'RaohaneFamily initializes compatibility bridge at boot'
fi

rg -q 'RaohaneConfig\.barVertical' "$family" \
  || fail 'RaohaneFamily does not route bar orientation through native config'
if rg -n '^import qs\.modules\.common|^import qs\.modules\.ii|\bConfig\.|\bGlobalStates\.' "$family"; then
  fail 'RaohaneFamily composition root depends on inherited framework'
fi

rg -q '^import "modules/raohane/config"$' "$shell" \
  || fail 'shell bootstrap does not import native config'
rg -q 'active:[[:space:]]*RaohaneConfig\.ready' "$shell" \
  || fail 'shell bootstrap is not gated by native config readiness'
rg -q 'component:[[:space:]]*RaohaneFamily[[:space:]]*\{' "$shell" \
  || fail 'shell bootstrap does not load RaohaneFamily'
if rg -n '^import "modules/common"|^import "services"|\bConfig\.|\bIllogicalImpulseFamily\b|\bRaohaneLegacyBridge\b' "$shell"; then
  fail 'shell bootstrap resolves inherited framework/family/bridge'
fi

# Hyprland integration belongs in native surface modules, not shell bootstrap.
rg -q '^import Quickshell\.Hyprland$' "$bar" \
  || fail 'RaohaneBar lost direct Hyprland integration'

# Hyprland 0.55+ Lua override remains installation-owned.
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

printf 'core-framework-audit: native paths/config/state/focus/composition and boot boundaries are valid\n'
