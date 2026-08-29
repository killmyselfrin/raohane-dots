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

if rg -n 'Timer[[:space:]]*\{([^}]|\n)*running:[[:space:]]*true' "$sidebar" >/dev/null 2>&1; then
  fail 'sidebar contains an unconditional always-running timer'
fi

printf 'sidebar-performance-audit: clock updates only while the sidebar is visible\n'
