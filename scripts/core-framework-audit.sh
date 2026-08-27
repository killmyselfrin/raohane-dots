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
qmldir="$config_module/qmldir"
state='modules/raohane/RaohaneState.qml'
bridge='modules/raohane/RaohaneLegacyBridge.qml'
bar='modules/raohane/RaohaneBar.qml'
settings_content='modules/raohane/RaohaneSettingsContent.qml'
family='panelFamilies/RaohaneFamily.qml'

for path in "$config" "$paths" "$qmldir" "$state" "$bridge" "$bar" "$settings_content" "$family"; do
  [[ -f "$path" ]] || fail "missing core framework path: $path"
done

rg -q '^singleton RaohanePaths .*RaohanePaths.qml$' "$qmldir" \
  || fail 'RaohanePaths is not registered in the native config module'
rg -q '^singleton RaohaneConfig .*RaohaneConfig.qml$' "$qmldir" \
  || fail 'RaohaneConfig is not registered in the native config module'

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

for property_name in barOpen controlCenterOpen screenLocked superDown; do
  rg -q "property bool ${property_name}:" "$state" \
    || fail "RaohaneState missing runtime property: $property_name"
done

for symbol in \
  'RaohaneConfig\.barAutoHide' 'RaohaneConfig\.barScreenList' \
  'RaohaneConfig\.barShowDate' 'RaohaneState\.barOpen' \
  'RaohaneState\.controlCenterOpen' 'RaohaneState\.screenLocked'; do
  rg -q "$symbol" "$bar" || fail "RaohaneBar lost native framework symbol: $symbol"
done
if rg -n '^import qs$|^import qs\.modules\.common|\bConfig\.|\bGlobalStates\.' "$bar"; then
  fail 'RaohaneBar regressed to inherited config/state/common framework'
fi

rg -q 'RaohanePaths\.defaultAvatarUrl' "$settings_content" \
  || fail 'RaohaneSettingsContent does not use RaohanePaths for its avatar fallback'
rg -q 'RaohanePaths\.compatibilityConfigFile' "$settings_content" \
  || fail 'RaohaneSettingsContent does not use RaohanePaths for the compatibility config path'
if rg -n '\bDirectories\.' "$settings_content"; then
  fail 'RaohaneSettingsContent regressed to inherited Directories'
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

printf 'core-framework-audit: native paths, config v6 and bar config/state boundaries are valid\n'
