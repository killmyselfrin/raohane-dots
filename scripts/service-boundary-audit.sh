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

[[ -f "$QMLDIR" ]] || fail 'Raohane service qmldir is missing'
[[ -f "$CONFIG_MODULE/qmldir" ]] || fail 'Raohane config qmldir is missing'
[[ -f "$CONFIG_MODULE/RaohaneConfig.qml" ]] || fail 'RaohaneConfig is missing'
rg -q '^singleton RaohaneConfig .*RaohaneConfig.qml$' "$CONFIG_MODULE/qmldir" \
  || fail 'RaohaneConfig is not registered in the native config module'
if rg -n 'import qs$|modules\.common|JsonAdapter' "$CONFIG_MODULE/RaohaneConfig.qml"; then
  fail 'RaohaneConfig depends on the inherited config/common framework'
fi

require_service() {
  local name="$1"
  local backend_pattern="$2"
  local file="$MODULE/$name.qml"
  [[ -f "$file" ]] || fail "$file is missing"
  rg -q "^singleton ${name} .*${name}\.qml$" "$QMLDIR" \
    || fail "$name is not registered in the Raohane service module"
  rg -q "$backend_pattern" "$file" \
    || fail "$name does not bind directly to its Quickshell/system backend"
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

rg -q 'RaohaneMedia\.' modules/raohane/RaohaneContext.qml \
  || fail 'RaohaneContext does not consume RaohaneMedia'
rg -q 'RaohaneMedia\.' modules/raohane/RaohaneMediaOverlay.qml \
  || fail 'RaohaneMediaOverlay does not consume RaohaneMedia'
if rg -n 'MprisController' modules/raohane/RaohaneContext.qml modules/raohane/RaohaneMediaOverlay.qml; then
  fail 'active Raohane media surfaces use inherited MprisController'
fi

rg -q 'RaohaneBluetooth\.' modules/raohane/RaohaneQuickControls.qml \
  || fail 'RaohaneQuickControls does not consume RaohaneBluetooth'
if rg -n 'BluetoothStatus|Bluetooth\.defaultAdapter' modules/raohane/RaohaneQuickControls.qml; then
  fail 'RaohaneQuickControls use inherited/direct Bluetooth plumbing'
fi
rg -q 'RaohaneBluetooth' services/BluetoothStatus.qml \
  || fail 'compatibility BluetoothStatus facade is not routed to RaohaneBluetooth'
if rg -n 'Quickshell\.Bluetooth|Bluetooth\.defaultAdapter' "$MODULE/RaohaneBluetooth.qml" services/BluetoothStatus.qml; then
  fail 'Raohane bluetooth graph regressed to the Quickshell BlueZ object-manager backend'
fi

rg -q 'RaohaneAudio\.' modules/raohane/RaohaneQuickControls.qml \
  || fail 'RaohaneQuickControls does not consume RaohaneAudio'
rg -q 'RaohaneAudio\.' modules/raohane/RaohaneOsd.qml \
  || fail 'RaohaneOsd does not consume RaohaneAudio'
if rg -n '\bAudio\.' modules/raohane/RaohaneQuickControls.qml modules/raohane/RaohaneOsd.qml; then
  fail 'active Raohane audio surfaces use inherited Audio service'
fi
rg -q 'RaohaneAudio' services/Audio.qml \
  || fail 'compatibility Audio facade is not routed to RaohaneAudio'
if rg -n 'Quickshell\.Services\.Pipewire|PwObjectTracker|\bPipewire\.' "$MODULE/RaohaneAudio.qml" services/Audio.qml; then
  fail 'Raohane audio graph regressed to a Quickshell PipeWire event loop'
fi

rg -q '\bpw-dump\b' modules/raohane/RaohanePrivacy.qml \
  || fail 'RaohanePrivacy is not inspecting the PipeWire graph through pw-dump'
if rg -n 'Quickshell\.Services\.Pipewire|PwObjectTracker|\bPipewire\.' modules/raohane/RaohanePrivacy.qml; then
  fail 'RaohanePrivacy regressed to a Quickshell PipeWire event loop'
fi

rg -q 'RaohaneNetwork\.' modules/raohane/RaohaneQuickControls.qml \
  || fail 'RaohaneQuickControls does not consume RaohaneNetwork'
if rg -n '\bNetwork\.' modules/raohane/RaohaneQuickControls.qml; then
  fail 'RaohaneQuickControls use inherited Network service'
fi

rg -q 'RaohaneDisplay\.' modules/raohane/RaohaneQuickControls.qml \
  || fail 'RaohaneQuickControls does not consume RaohaneDisplay'
rg -q 'RaohaneDisplay\.' modules/raohane/RaohaneOsd.qml \
  || fail 'RaohaneOsd does not consume RaohaneDisplay'
if rg -n '\bBrightness\.|\bHyprsunset\.' modules/raohane/RaohaneQuickControls.qml modules/raohane/RaohaneOsd.qml; then
  fail 'active Raohane display surfaces use inherited Brightness/Hyprsunset services'
fi

for symbol in RaohaneIdle RaohaneEasyEffects; do
  rg -q "${symbol}\." modules/raohane/RaohaneQuickControls.qml \
    || fail "RaohaneQuickControls does not consume ${symbol}"
done
if rg -n '^import qs\.services$|(^|[^A-Za-z])Idle\.|(^|[^A-Za-z])EasyEffects\.' modules/raohane/RaohaneQuickControls.qml; then
  fail 'RaohaneQuickControls regressed to inherited Idle/EasyEffects services'
fi
if rg -n 'modules\.common|Quickshell\.Services\.Pipewire|PwObjectTracker|\bPipewire\.' "$MODULE/RaohaneIdle.qml" "$MODULE/RaohaneEasyEffects.qml"; then
  fail 'native quick-control helpers depend on inherited common/PipeWire plumbing'
fi

for surface in RaohaneNotificationCenter.qml RaohaneNotificationPopup.qml RaohaneNotificationCard.qml; do
  rg -q 'RaohaneNotifications\.' "modules/raohane/$surface" \
    || fail "$surface does not consume RaohaneNotifications"
done
if rg -n '\bNotifications\.' modules/raohane/RaohaneNotificationCenter.qml modules/raohane/RaohaneNotificationPopup.qml modules/raohane/RaohaneNotificationCard.qml; then
  fail 'active Raohane notification UI uses inherited Notifications service'
fi
rg -q 'RaohaneNotifications' services/Notifications.qml \
  || fail 'compatibility Notifications facade is not routed to RaohaneNotifications'
if rg -n 'NotificationServer[[:space:]]*\{' services/Notifications.qml; then
  fail 'compatibility Notifications service owns a second NotificationServer'
fi

rg -q 'RaohaneWallpapers' services/Wallpapers.qml \
  || fail 'compatibility Wallpapers facade is not routed to RaohaneWallpapers'
if rg -n 'FolderListModel|FolderListModelWithHistory|switchwall\.sh|illogical-impulse' services/Wallpapers.qml; then
  fail 'compatibility Wallpapers service still owns inherited wallpaper plumbing'
fi
rg -q 'RaohaneConfig\.wallpaperPath' modules/raohane/services/RaohaneWallpapers.qml \
  || fail 'RaohaneWallpapers does not persist through RaohaneConfig'
rg -q '"mp4".*"webm".*"mkv"' modules/raohane/services/RaohaneWallpapers.qml \
  || fail 'RaohaneWallpapers lost native video wallpaper discovery'

for symbol in RaohaneWallpapers RaohaneConfig RaohaneState; do
  rg -q "${symbol}\." modules/raohane/RaohaneWallpaperSelector.qml \
    || fail "RaohaneWallpaperSelector does not consume ${symbol}"
done
if rg -n '\bConfig\.|\bDirectories\.|\bAppearance\.|\bWallpapers\.|GlobalStates\.wallpaperSelector' modules/raohane/RaohaneWallpaperSelector.qml; then
  fail 'RaohaneWallpaperSelector regressed to inherited wallpaper state/services'
fi

rg -q 'RaohaneSession' modules/common/functions/Session.qml \
  || fail 'compatibility Session API is not routed to RaohaneSession'
if rg -n -i 'niri|end4-pC|pkill.*Hyprland|HyprlandData' modules/common/functions/Session.qml; then
  fail 'compatibility Session API still contains inherited compositor/process logic'
fi
rg -q 'RaohaneSessionWarnings' services/SessionWarnings.qml \
  || fail 'compatibility SessionWarnings is not routed to RaohaneSessionWarnings'
if rg -n 'Process[[:space:]]*\{' services/SessionWarnings.qml; then
  fail 'compatibility SessionWarnings still owns process probes'
fi
rg -q 'RaohaneSystemInfo' services/SystemInfo.qml \
  || fail 'compatibility SystemInfo is not routed to RaohaneSystemInfo'
if rg -n 'Process[[:space:]]*\{|FileView[[:space:]]*\{' services/SystemInfo.qml; then
  fail 'compatibility SystemInfo still owns system probes'
fi

for service in RaohaneSession.qml RaohaneDisplay.qml RaohaneWallpapers.qml; do
  rg -q 'qs\.modules\.raohane\.config' "$MODULE/$service" \
    || fail "$service does not consume the native config module"
  if rg -n '\bConfig\.' "$MODULE/$service"; then
    fail "$service still consumes inherited Config"
  fi
done

rg -q 'RaohaneSearch\.' modules/raohane/RaohaneLauncher.qml \
  || fail 'RaohaneLauncher does not consume RaohaneSearch'
if rg -n 'LauncherSearch|LauncherSearchResult|AppSearch|qs\.modules\.common\.models' modules/raohane/RaohaneLauncher.qml; then
  fail 'RaohaneLauncher regressed to the inherited search model'
fi
if rg -n 'import qs$|import qs\.services|modules\.common|LauncherSearch|AppSearch|StringUtils|Fuzzy\.' "$MODULE/RaohaneSearch.qml"; then
  fail 'RaohaneSearch depends on inherited search/common services'
fi

rg -q 'RaohaneConfig' modules/raohane/RaohaneLegacyBridge.qml \
  || fail 'legacy bridge is not connected to RaohaneConfig'
rg -q 'RaohaneLegacyBridge\.load' panelFamilies/RaohaneFamily.qml \
  || fail 'RaohaneFamily does not initialize the temporary config bridge'

printf 'raohane-service-audit: core services, quick controls, wallpaper workflow, native search and config boundaries are Raohane-owned\n'
