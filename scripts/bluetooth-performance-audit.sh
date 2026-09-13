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

[[ -f "$service" ]] || fail "missing $service"
[[ -f "$manifest" ]] || fail "missing $manifest"

rg -q '^import Quickshell\.Bluetooth$' "$service" \
  || fail 'Bluetooth service does not use Quickshell native BlueZ integration'

for contract in \
  'Bluetooth\.defaultAdapter' \
  'Bluetooth\.devices\.values' \
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

printf 'bluetooth-performance-audit: adapter power and connected-device state come directly from Quickshell BlueZ with no monitor/probe subprocesses\n'
