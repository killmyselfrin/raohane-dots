#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'sidebar-performance-audit: %s\n' "$*" >&2
  exit 1
}

sidebar='modules/raohane/RaohaneSidebarLeft.qml'
[[ -f "$sidebar" ]] || fail "missing $sidebar"

rg -q 'running:[[:space:]]*RaohaneState\.leftSidebarOpen' "$sidebar" \
  || fail 'sidebar clock timer is not gated by panel visibility'
rg -q 'function onLeftSidebarOpenChanged\(\): void' "$sidebar" \
  || fail 'sidebar does not refresh its clock immediately when opened'
rg -q 'if \(RaohaneState\.leftSidebarOpen\)' "$sidebar" \
  || fail 'sidebar open-state handler does not guard the immediate refresh'
rg -q 'root\.now = new Date\(\)' "$sidebar" \
  || fail 'sidebar no longer updates its displayed clock'

# Audio controls belong to Control Center. The navigation-only left rail should
# not wake the audio snapshot path simply because it becomes visible.
if rg -n 'RaohaneAudio\.refresh\(' "$sidebar"; then
  fail 'navigation-only sidebar regressed to requesting audio snapshots on open'
fi
if rg -n 'RaohaneAudio\.(setVolume|toggleMute|setMuted)' "$sidebar"; then
  fail 'navigation-only sidebar regressed to owning audio controls'
fi
if rg -n 'running:[[:space:]]*true' "$sidebar"; then
  fail 'sidebar contains an unconditional always-running timer/process'
fi

printf 'sidebar-performance-audit: clock is visibility-gated and navigation rail does not poll audio\n'
