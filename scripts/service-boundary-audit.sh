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

[[ -f "$QMLDIR" ]] || fail 'Raohane service qmldir is missing'

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
require_service RaohaneBluetooth 'Quickshell\.Bluetooth'
require_service RaohaneAudio 'Quickshell\.Services\.Pipewire'
require_service RaohaneNetwork '\bnmcli\b'
require_service RaohaneDisplay 'brightnessctl|ddcutil|hyprsunset'
require_service RaohaneNotifications 'Quickshell\.Services\.Notifications'

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

rg -q 'RaohaneAudio\.' modules/raohane/RaohaneQuickControls.qml \
  || fail 'RaohaneQuickControls does not consume RaohaneAudio'
rg -q 'RaohaneAudio\.' modules/raohane/RaohaneOsd.qml \
  || fail 'RaohaneOsd does not consume RaohaneAudio'
if rg -n '\bAudio\.' modules/raohane/RaohaneQuickControls.qml modules/raohane/RaohaneOsd.qml; then
  fail 'active Raohane audio surfaces use inherited Audio service'
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

printf 'raohane-service-audit: media, Bluetooth, audio, network, display and notification boundaries are native\n'
