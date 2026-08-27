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
settings='modules/raohane/RaohaneSettings.qml'
settings_content='modules/raohane/RaohaneSettingsContent.qml'
family='panelFamilies/RaohaneFamily.qml'
shell='shell.qml'

for path in "$config" "$paths" "$config_qmldir" "$raohane_qmldir" "$state" "$focus" "$bridge" "$bar" "$launcher" "$settings" "$settings_content" "$family" "$shell"; do
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

for property_name in barOpen controlCenterOpen settingsOpen sessionOpen screenLocked superDown; do
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

for surface in "$launcher" "$settings"; do
  rg -q 'RaohaneFocusGrab\.' "$surface" \
    || fail "$surface does not consume RaohaneFocusGrab"
  if rg -n '\bGlobalFocusGrab\.|^import qs\.services$' "$surface"; then
    fail "$surface regressed to inherited GlobalFocusGrab/services"
  fi
done

rg -q 'RaohaneState\.settingsOpen' "$settings" \
  || fail 'RaohaneSettings does not own its runtime open state'
if rg -n '\bGlobalStates\.settingsOpen\b|^import qs$|^import qs\.modules\.common' "$settings"; then
  fail 'RaohaneSettings regressed to inherited root/common state'
fi
if rg -n '\bMaterialSymbol[[:space:]]*\{' "$settings"; then
  fail 'RaohaneSettings regressed to inherited MaterialSymbol'
fi

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
  'RaohaneState\.controlCenterOpen'; do
  rg -q "$symbol" "$bridge" || fail "legacy bridge is missing native synchronization: $symbol"
done

printf 'core-framework-audit: native paths, config v6, focus helper and bar/settings state boundaries are valid\n'
