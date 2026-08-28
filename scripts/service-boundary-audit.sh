#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'raohane-service-audit: %s\n' "$*" >&2
  exit 1
}

MODULE=modules/raohane/services
QMLDIR="$MODULE/qmldir"
CONFIG_MODULE=modules/raohane/config
FAMILY=panelFamilies/RaohaneFamily.qml
AUTOSTART_SCRIPT=scripts/autostart.sh
RECORDER=scripts/videos/record.sh
FEATURES=install/arch/features.txt
REQUIRED=install/arch/required.txt

for path in "$QMLDIR" "$CONFIG_MODULE/qmldir" "$CONFIG_MODULE/RaohaneConfig.qml" "$AUTOSTART_SCRIPT" "$RECORDER" "$FEATURES" "$REQUIRED"; do
  [[ -f "$path" ]] || fail "missing native service/runtime path: $path"
done
rg -q '^singleton RaohaneConfig .*RaohaneConfig.qml$' "$CONFIG_MODULE/qmldir" \
  || fail 'RaohaneConfig is not registered in the native config module'
if rg -n '^import qs$|modules\.common|JsonAdapter|\bConfig\.' "$CONFIG_MODULE/RaohaneConfig.qml"; then
  fail 'RaohaneConfig depends on inherited config/common framework'
fi

require_service() {
  local name="$1"
  local backend_pattern="$2"
  local file="$MODULE/$name.qml"
  [[ -f "$file" ]] || fail "$file is missing"
  rg -q "^singleton ${name} .*${name}\.qml$" "$QMLDIR" \
    || fail "$name is not registered in native services"
  rg -q "$backend_pattern" "$file" \
    || fail "$name lost direct system/Quickshell backend: $backend_pattern"
}

require_service RaohaneMedia 'Quickshell\.Services\.Mpris'
require_service RaohaneBluetooth '\bbluetoothctl\b'
require_service RaohaneAudio '\bwpctl\b'
require_service RaohaneNetwork '\bnmcli\b'
require_service RaohaneDisplay 'brightnessctl|ddcutil|hyprsunset'
require_service RaohaneNotifications 'Quickshell\.Services\.Notifications'
require_service RaohaneWallpapers 'Qt\.labs\.folderlistmodel'
require_service RaohaneSession 'hyprctl.*dispatch.*exit'
require_service RaohaneSessionWarnings 'pacman|/var/lib/pacman/db\.lck'
require_service RaohaneSystemInfo '/etc/os-release'
require_service RaohaneSearch 'DesktopEntries'
require_service RaohaneIdle 'IdleInhibitor'
require_service RaohaneEasyEffects 'easyeffects'
require_service RaohaneYdotool 'ydotool'
require_service RaohaneDropShelf 'wl-copy --type text/uri-list'
require_service RaohaneAutostart 'scripts/autostart\.sh'

# Every external backend owned by a native service must have an installable Arch
# package in the full feature manifest. Keep this close to the service audit so
# adding a command cannot silently make fresh installs incomplete.
for package in bluez-utils brightnessctl ddcutil hyprsunset easyeffects ydotool; do
  rg -q "^${package}$" "$FEATURES" \
    || fail "native service backend package missing from feature manifest: $package"
done

for pair in \
  'modules/raohane/RaohaneContext.qml:RaohaneMedia\.' \
  'modules/raohane/RaohaneMediaOverlay.qml:RaohaneMedia\.' \
  'modules/raohane/RaohaneQuickControls.qml:RaohaneBluetooth\.' \
  'modules/raohane/RaohaneQuickControls.qml:RaohaneAudio\.' \
  'modules/raohane/RaohaneQuickControls.qml:RaohaneNetwork\.' \
  'modules/raohane/RaohaneQuickControls.qml:RaohaneDisplay\.' \
  'modules/raohane/RaohaneQuickControls.qml:RaohaneIdle\.' \
  'modules/raohane/RaohaneQuickControls.qml:RaohaneEasyEffects\.' \
  'modules/raohane/RaohaneOsd.qml:RaohaneAudio\.' \
  'modules/raohane/RaohaneOsd.qml:RaohaneDisplay\.' \
  'modules/raohane/RaohaneLauncher.qml:RaohaneSearch\.' \
  'modules/raohane/RaohaneWallpaperSelector.qml:RaohaneWallpapers\.'; do
  file="${pair%%:*}"
  pattern="${pair#*:}"
  rg -q "$pattern" "$file" || fail "$file lost native service dependency: $pattern"
done

for surface in RaohaneNotificationCenter.qml RaohaneNotificationPopup.qml RaohaneNotificationCard.qml; do
  rg -q 'RaohaneNotifications\.' "modules/raohane/$surface" \
    || fail "$surface does not consume RaohaneNotifications"
done

if rg -n \
  '\bMprisController\b|\bBluetoothStatus\.|(^|[^A-Za-z])Audio\.|(^|[^A-Za-z])Network\.|(^|[^A-Za-z])Brightness\.|(^|[^A-Za-z])Hyprsunset\.|(^|[^A-Za-z])Idle\.|(^|[^A-Za-z])EasyEffects\.' \
  modules/raohane/RaohaneContext.qml \
  modules/raohane/RaohaneMediaOverlay.qml \
  modules/raohane/RaohaneQuickControls.qml \
  modules/raohane/RaohaneOsd.qml; then
  fail 'active Raohane surfaces reference inherited service APIs'
fi

if rg -n 'LauncherSearch|LauncherSearchResult|AppSearch|qs\.modules\.common\.models' modules/raohane/RaohaneLauncher.qml; then
  fail 'RaohaneLauncher regressed to inherited search model'
fi
if rg -n '^import qs$|^import qs\.services|modules\.common|LauncherSearch|AppSearch|StringUtils|Fuzzy\.' "$MODULE/RaohaneSearch.qml"; then
  fail 'RaohaneSearch depends on inherited search/common services'
fi

for service in RaohaneSession.qml RaohaneDisplay.qml RaohaneWallpapers.qml; do
  rg -q 'qs\.modules\.raohane\.config' "$MODULE/$service" \
    || fail "$service does not consume native config"
  if rg -n '\bConfig\.' "$MODULE/$service"; then
    fail "$service still consumes inherited Config"
  fi
done

for contract in \
  'HYPRLAND_INSTANCE_SIGNATURE' \
  'raohane-autostart-' \
  'setsid bash -lc' \
  'run|rerun|reset|status|config'; do
  rg -q "$contract" "$AUTOSTART_SCRIPT" \
    || fail "native autostart backend lost session contract: $contract"
done
rg -q 'RaohaneAutostart\.runOnce\(\)' "$FAMILY" \
  || fail 'RaohaneFamily no longer starts the native autostart service'
rg -q '^import qs\.modules\.raohane\.services$' "$FAMILY" \
  || fail 'RaohaneFamily does not import native services for autostart'
bash -n "$AUTOSTART_SCRIPT"

# Screen recording is part of the native region surface. It must not read the
# retired inherited config document, and every external command used for the
# full recording path must be represented by the install manifests.
if rg -n 'illogical-impulse|raohane/config\.json|CONFIG_FILE=.*/config\.json' "$RECORDER"; then
  fail 'native recorder still reads a retired compatibility config'
fi
for contract in \
  'RAOHANE_RECORDING_DIR' \
  'xdg-user-dir VIDEOS' \
  '\bwf-recorder\b' \
  '\bslurp\b' \
  '\bhyprctl\b' \
  '\bpactl\b'; do
  rg -q "$contract" "$RECORDER" \
    || fail "native recorder lost runtime contract: $contract"
done
for package in wf-recorder slurp libpulse; do
  rg -q "^${package}$" "$FEATURES" \
    || fail "recorder backend package missing from feature manifest: $package"
done
rg -q '^xdg-user-dirs$' "$REQUIRED" \
  || fail 'recorder XDG Videos fallback requires xdg-user-dirs'
bash -n "$RECORDER"

if [[ -e modules/raohane/RaohaneLegacyBridge.qml ]]; then
  fail 'retired compatibility bridge returned to the native runtime tree'
fi
if rg -n '\bRaohaneLegacyBridge\b' "$FAMILY" modules/raohane/qmldir; then
  fail 'active runtime references the retired compatibility bridge'
fi

printf 'raohane-service-audit: native services, backend packages, recorder and session-safe autostart contracts are valid\n'
