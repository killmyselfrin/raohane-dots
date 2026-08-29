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

rg -q 'bluetoothctl --monitor' "$service" \
  || fail 'Bluetooth service is not using BlueZ monitor output'
rg -q 'id:[[:space:]]*monitorDebounce' "$service" \
  || fail 'BlueZ monitor events are not debounced'
rg -q 'id:[[:space:]]*monitorRestart' "$service" \
  || fail 'BlueZ monitor has no restart path'
rg -q 'interval:[[:space:]]*15000' "$service" \
  || fail 'Bluetooth health fallback is missing or too aggressive'

if rg -n 'interval:[[:space:]]*3000' "$service"; then
  fail 'legacy 3-second Bluetooth polling returned'
fi

rg -q '^bluez-utils$' "$manifest" \
  || fail 'feature manifest no longer provides bluetoothctl'

printf 'bluetooth-performance-audit: Bluetooth state follows BlueZ monitor events with a slow health fallback\n'
