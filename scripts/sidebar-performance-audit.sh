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
rg -q 'RaohaneAudio\.refresh\(\)' "$sidebar" \
  || fail 'sidebar no longer requests the cached audio snapshot when opened'

if rg -n 'RaohaneAudio\.refresh\(true\)' "$sidebar"; then
  fail 'sidebar bypasses the shared audio cache on every open'
fi
if rg -n 'running:[[:space:]]*true' "$sidebar"; then
  fail 'sidebar contains an unconditional always-running timer/process'
fi

printf 'sidebar-performance-audit: clock is visibility-gated and audio opens reuse the shared cache\n'
