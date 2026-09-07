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

# BlueZ events are the primary state source. Opening Control Center may request
# a refresh, but the service must reuse a recent snapshot instead of spawning
# bluetoothctl repeatedly during rapid surface toggles.
rg -q 'bluetoothctl --monitor' "$service" \
  || fail 'Bluetooth service is not using BlueZ monitor output'
rg -q 'readonly property int minimumRefreshInterval:[[:space:]]*15000' "$service" \
  || fail 'Bluetooth open-refresh cache is missing or unexpectedly aggressive'
rg -q 'lastRefreshMs' "$service" \
  || fail 'Bluetooth snapshots are not cached between surface opens'
rg -q 'id:[[:space:]]*monitorDebounce' "$service" \
  || fail 'BlueZ monitor events are not debounced'
rg -A4 'id:[[:space:]]*monitorDebounce' "$service" | rg -q 'root\.refresh\(true\)' \
  || fail 'BlueZ events do not bypass the UI refresh cache'
rg -q 'id:[[:space:]]*monitorRestart' "$service" \
  || fail 'BlueZ monitor has no restart path'
rg -q 'interval:[[:space:]]*90000' "$service" \
  || fail 'Bluetooth repair fallback is missing or too aggressive'

if rg -n 'interval:[[:space:]]*(3000|15000)[[:space:]]*$' "$service"; then
  fail 'legacy aggressive Bluetooth health polling returned'
fi

rg -q '^bluez-utils$' "$manifest" \
  || fail 'feature manifest no longer provides bluetoothctl'

printf 'bluetooth-performance-audit: cached snapshots follow BlueZ monitor events with a slow repair fallback\n'
