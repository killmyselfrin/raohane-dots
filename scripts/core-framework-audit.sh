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

rg -q '^singleton RaohanePaths .*RaohanePaths.qml$' "$config_qmldir" \
  || fail 'RaohanePaths is not registered in the native config module'
rg -q '^singleton RaohaneConfig .*RaohaneConfig.qml$' "$config_qmldir" \
  || fail 'RaohaneConfig is not registered in the native config module'
rg -q '^singleton RaohaneFocusGrab .*RaohaneFocusGrab.qml$' "$raohane_qmldir" \
  || fail 'RaohaneFocusGrab is not registered in the native Raohane module'

for symbol in 'StandardPaths\.standardLocations' 'Quickshell\.shellPath' 'configDirectory' 'nativeConfigFile' 'notificationsFile' 'defaultAvatarUrl'; do
  rg -q "$symbol" "$paths" || fail "RaohanePaths lost required path contract: $symbol"
done
if rg -n '^import qs\.|\bDirectories\.' "$paths"; then
  fail 'RaohanePaths depends on the inherited framework'
fi

rg -q 'schemaVersion:[[:space:]]*6' "$config" || fail 'RaohaneConfig schema was not advanced to v6'
rg -q 'RaohanePaths\.nativeConfigFile' "$config" || fail 'RaohaneConfig does not use the native paths API'
if rg -n '\bStandardPaths\.|\bDirectories\.|^import qs$|^import qs\.modules\.common' "$config"; then
  fail 'RaohaneConfig owns paths/config through an inherited framework dependency'
fi

for property_name in \
  barBottom barVertical barAutoHide barAutoHidePushWindows \
  barShowOnSuper barShowOnSuperDelay barScreenList barShowDate; do
  rg -q "property .* ${property_name}:" "$config" \
    || fail "RaohaneConfig missing native bar property: $property_name"
done

for property_name in barOpen controlCenterOpen settingsOpen sessionOpen osdOpen screenLocked superDown; do
  rg -q "property bool ${property_name}:" "$state" \
    || fail "RaohaneState missing runtime property: $property_name"
done

rg -q '^import Quickshell\.Hyprland$' "$focus" \
  || fail 'RaohaneFocusGrab is not bound directly to Hyprland'
rg -q '\bHyprlandFocusGrab[[:space:]]*\{' "$focus" \
  || fail 'RaohaneFocusGrab does not own a HyprlandFocusGrab'
if rg -n '^import qs\.|\bWM\.' "$focus"; then
  fail 'RaohaneFocusGrab depends on inherited compositor/services plumbing'
fi

for symbol in \
  'RaohaneConfig\.barAutoHide' 'RaohaneConfig\.barScreenList' \
  'RaohaneConfig\.barShowDate' 'RaohaneState\.barOpen' \
  'RaohaneState\.controlCenterOpen' 'RaohaneState\.screenLocked'; do
  rg -q "$symbol" "$bar" || fail "RaohaneBar lost native framework symbol: $symbol"
done
if rg -n '^import qs$|^import qs\.modules\.common|\bConfig\.|\bGlobalStates\.' "$bar"; then
  fail 'RaohaneBar regressed to inherited config/state/common framework'
fi

for surface in "$launcher" "$settings" "$control_center"; do
  rg -q 'RaohaneFocusGrab\.' "$surface" \
    || fail "$surface does not consume RaohaneFocusGrab"
  if rg -n '\bGlobalFocusGrab\.|^import qs\.services$' "$surface"; then
    fail "$surface regressed to inherited GlobalFocusGrab/services"
  fi
done

for symbol in \
  'RaohaneState\.controlCenterOpen' 'RaohaneNotifications\.markAllRead' \
  'RaohaneConfig\.wallpaperPath' 'RaohaneSystemInfo\.' 'RaohaneIcon[[:space:]]*\{'; do
  rg -q "$symbol" "$control_center" || fail "RaohaneControlCenter lost native framework symbol: $symbol"
done
if rg -n '^import qs$|^import qs\.modules\.common|^import qs\.modules\.common\.widgets|\bConfig\.|\bGlobalStates\.|\bMaterialSymbol[[:space:]]*\{' "$control_center"; then
  fail 'RaohaneControlCenter regressed to inherited common/config/state/widgets'
fi

for symbol in 'RaohaneState\.osdOpen' 'RaohaneAudio\.' 'RaohaneDisplay\.' 'RaohaneConfig\.osdTimeout'; do
  rg -q "$symbol" "$osd" || fail "RaohaneOsd lost native framework symbol: $symbol"
done
if rg -n '^import qs$|\bGlobalStates\.osdVolumeOpen\b|\bAudio\.|\bBrightness\.|\bHyprsunset\.' "$osd"; then
  fail 'RaohaneOsd regressed to inherited root/audio/display state'
fi

for symbol in \
  'RaohaneState\.sessionOpen' 'RaohaneState\.screenLocked' \
  'RaohaneSession\.' 'RaohaneSessionWarnings\.' 'RaohaneSystemInfo\.' \
  'RaohaneConfig\.wallpaperPath' 'RaohaneIcon[[:space:]]*\{'; do
  rg -q "$symbol" "$session" || fail "RaohaneSessionScreen lost native framework symbol: $symbol"
done
if rg -n '^import qs$|^import qs\.services$|^import qs\.modules\.common|\bGlobalStates\.|\bConfig\.|(^|[^A-Za-z])Session\.|(^|[^A-Za-z])SessionWarnings\.|(^|[^A-Za-z])SystemInfo\.|\bMaterialSymbol[[:space:]]*\{' "$session"; then
  fail 'RaohaneSessionScreen regressed to inherited config/state/services/widgets'
fi

rg -q 'RaohaneState\.settingsOpen' "$settings" \
  || fail 'RaohaneSettings does not own its runtime open state'
if rg -n '\bGlobalStates\.settingsOpen\b|^import qs$|^import qs\.modules\.common' "$settings"; then
  fail 'RaohaneSettings regressed to inherited root/common state'
fi
if rg -n 'Component\.onCompleted:[[:space:]]*RaohaneState\.settingsOpen[[:space:]]*=[[:space:]]*false' "$settings"; then
  fail 'RaohaneSettings resets a valid open request during component startup'
fi
if rg -n '\bMaterialSymbol[[:space:]]*\{' "$settings"; then
  fail 'RaohaneSettings regressed to inherited MaterialSymbol'
fi

for symbol in 'RaohaneState\.settingsOpen' 'GlobalStates\.settingsOpen' 'onSettingsOpenChanged'; do
  rg -q "$symbol" "$bridge" || fail "legacy bridge is missing settings synchronization: $symbol"
done

# Bare Super belongs to no launcher in Raohane. The old end4 searchToggle*
# contract is intentionally removed; the native launcher remains SUPER+R.
if rg -n 'name:[[:space:]]*"searchToggle(Release|ReleaseInterrupt)?"|\breleaseArmed\b' "$overview"; then
  fail 'RaohaneOverview still exposes inherited bare-Super launcher hooks'
fi

# Hyprland 0.55+ is Lua-first. Keep the old hyprlang snippet for <=0.54,
# but require a native Lua override that is loaded last from hyprland.lua.
for symbol in \
  'HYPR_LUA_SNIPPET' 'hyprland\.lua' 'require\("raohane"\)' \
  'hl\.unbind\("SUPER \+ SUPER_L"\)' 'hl\.unbind\("SUPER \+ SUPER_R"\)' \
  'quickshell:raohaneLauncherToggle' 'quickshell:settingsToggle' \
  'quickshell:sidebarRightToggle' 'quickshell:raohaneMediaOverlayToggle'; do
  rg -q "$symbol" "$installer" || fail "installer lost Hyprland Lua integration symbol: $symbol"
done
rg -q 'hl\.bind\("SUPER \+ R"' "$installer" \
  || fail 'Hyprland Lua integration lost SUPER+R Raohane launcher bind'
rg -q 'hl\.bind\("SUPER \+ Escape"' "$installer" \
  || fail 'Hyprland Lua integration lost SUPER+Escape settings bind'
rg -q 'hl\.dsp\.focus\(\{ workspace = workspace \}\)' "$installer" \
  || fail 'Hyprland Lua integration lost numeric workspace focus binds'
rg -q 'hl\.dsp\.window\.move\(\{ workspace = workspace \}\)' "$installer" \
  || fail 'Hyprland Lua integration lost numeric move-window binds'

# Legacy <=0.54 compatibility remains explicit and must also remove both bare Super keys.
rg -q 'unbind[[:space:]]*=[[:space:]]*SUPER,[[:space:]]*Super_L' "$installer" \
  || fail 'legacy installer does not free inherited left bare-Super binding'
rg -q 'unbind[[:space:]]*=[[:space:]]*SUPER,[[:space:]]*Super_R' "$installer" \
  || fail 'legacy installer does not free inherited right bare-Super binding'
rg -q 'bind[[:space:]]*=[[:space:]]*SUPER,[[:space:]]*R,[[:space:]]*exec,[[:space:]]*raohane launcher' "$installer" \
  || fail 'legacy installer lost the explicit Raohane launcher shortcut'
rg -q 'bind[[:space:]]*=[[:space:]]*SUPER SHIFT,[[:space:]]*0,[[:space:]]*movetoworkspace,[[:space:]]*10' "$installer" \
  || fail 'legacy installer lost move-window workspace 10 binding'

rg -q 'RaohanePaths\.defaultAvatarUrl' "$settings_content" \
  || fail 'RaohaneSettingsContent does not use RaohanePaths for its avatar fallback'
rg -q 'RaohanePaths\.compatibilityConfigFile' "$settings_content" \
  || fail 'RaohaneSettingsContent does not use RaohanePaths for the compatibility config path'
if rg -n '\bDirectories\.' "$settings_content"; then
  fail 'RaohaneSettingsContent regressed to inherited Directories'
fi

rg -q 'RaohanePaths\.scriptsPath' "$shell" \
  || fail 'shell bootstrap does not use RaohanePaths for scripts'
if rg -n 'Directories\.scriptPath' "$shell"; then
  fail 'shell bootstrap regressed to inherited Directories for scripts'
fi

rg -q 'RaohaneConfig\.barVertical' "$family" \
  || fail 'RaohaneFamily does not route bar orientation through native config'
if rg -n 'Config\.options\.bar\.vertical' "$family"; then
  fail 'RaohaneFamily still routes bar orientation through inherited Config'
fi

for symbol in \
  'RaohaneConfig\.barVertical' 'RaohaneConfig\.barAutoHide' \
  'RaohaneConfig\.barScreenList' 'RaohaneState\.barOpen' \
  'RaohaneState\.controlCenterOpen' 'RaohaneState\.settingsOpen'; do
  rg -q "$symbol" "$bridge" || fail "legacy bridge is missing native synchronization: $symbol"
done

printf 'core-framework-audit: native paths, config v6, focus helper, control/settings/OSD/session state and Hyprland Lua keybind boundaries are valid\n'
