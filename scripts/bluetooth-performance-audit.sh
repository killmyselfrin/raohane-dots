#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'bluetooth-performance-audit: %s\n' "$*" >&2
  exit 1
}

service='modules/raohane/services/RaohaneBluetooth.qml'
manifest='install/arch/features.txt'
device_picker='modules/raohane/RaohaneDevicePicker.qml'

[[ -f "$service" ]] || fail "missing $service"
[[ -f "$manifest" ]] || fail "missing $manifest"
[[ -f "$device_picker" ]] || fail "missing $device_picker"

rg -q '^import Quickshell\.Bluetooth$' "$service" \
  || fail 'Bluetooth service does not use Quickshell native BlueZ integration'

for contract in \
  'Bluetooth\.defaultAdapter' \
  'root\.adapter\.devices\.values' \
  'BluetoothAdapterState\.Enabling' \
  'BluetoothAdapterState\.Disabling' \
  'BluetoothAdapterState\.Blocked' \
  'root\.adapter\.enabled[[:space:]]*=' \
  'device\.batteryAvailable' \
  'device\.battery'; do
  rg -q "$contract" "$service" || fail "Bluetooth lost native contract: $contract"
done

for compatibility in \
  'function refresh\(force\): void' \
  'function setEnabled\(value: bool\): void' \
  'function toggle\(\): void' \
  'function openManager\(\): void' \
  'signal powerApplied\(bool enabled\)'; do
  rg -q "$compatibility" "$service" || fail "Bluetooth lost UI compatibility contract: $compatibility"
done

if rg -n '\bbluetoothctl\b|Quickshell\.Io|Process[[:space:]]*\{|Timer[[:space:]]*\{|minimumRefreshInterval|lastRefreshMs|monitorDebounce|monitorRestart' "$service"; then
  fail 'Bluetooth regressed to helper-process or polling based BlueZ state'
fi

rg -q '^bluez$' "$manifest" \
  || fail 'feature manifest no longer provides the BlueZ daemon/runtime'

# Picker-owned discovery must not restart after Bluetooth mode is closed.
for contract in \
  'function startBluetoothDiscovery\\(\\): void' \
  'function stopBluetoothDiscovery\\(\\): void' \
  'Qt\\.callLater\\(\\(\\) => root\\.startBluetoothDiscovery\\(\\)\\)' \
  'if \\(!root\\.bluetoothMode \\|\\| !RaohaneBluetooth\\.enabled \\|\\| RaohaneBluetooth\\.discovering\\)' \
  'Component\\.onDestruction: root\\.stopBluetoothDiscovery\\(\\)' \
  'running: root\\.busy && root\\.visible && RaohaneMotion\\.panelMotionEnabled' \
  'running: row\\.waiting && root\\.visible && RaohaneMotion\\.panelMotionEnabled'; do
  rg -q "$contract" "$device_picker" || fail "picker discovery/motion contract missing: $contract"
done
if rg -n 'Qt\\.callLater\\(\\(\\) => RaohaneBluetooth\\.startDiscovery\\(\\)\\)' "$device_picker"; then
  fail 'picker can restart Bluetooth discovery after it closes'
fi

printf 'bluetooth-performance-audit: adapter power, discovery and device state come directly from Quickshell BlueZ with no monitor/probe subprocesses\n'
