#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'compat-service-audit: %s\n' "$*" >&2
  exit 1
}

idle='services/Idle.qml'
effects='services/EasyEffects.qml'

[[ -f "$idle" ]] || fail 'services/Idle.qml is missing'
[[ -f "$effects" ]] || fail 'services/EasyEffects.qml is missing'

rg -q 'RaohaneIdle' "$idle" || fail 'Idle facade is not routed to RaohaneIdle'
if rg -n 'IdleInhibitor|\bPersistent\.|modules\.common|Quickshell\.Wayland' "$idle"; then
  fail 'Idle compatibility facade still owns inherited persistence/inhibitor plumbing'
fi

rg -q 'RaohaneEasyEffects' "$effects" || fail 'EasyEffects facade is not routed to RaohaneEasyEffects'
if rg -n 'Process[[:space:]]*\{|modules\.common|Quickshell\.Services\.Pipewire|PwObjectTracker|\bPipewire\.' "$effects"; then
  fail 'EasyEffects compatibility facade still owns process/common/PipeWire plumbing'
fi

printf 'compat-service-audit: Idle and EasyEffects are thin Raohane compatibility facades\n'
