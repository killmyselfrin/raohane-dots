#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'sidebar-performance-audit: %s\n' "$*" >&2
  exit 1
}

sidebar='modules/raohane/RaohaneSidebarLeft.qml'
surface_router='modules/raohane/RaohaneSurfaceRouter.qml'
[[ -f "$sidebar" ]] || fail "missing $sidebar"
[[ -f "$surface_router" ]] || fail "missing $surface_router"

rg -q 'running:[[:space:]]*RaohaneState\.leftSidebarOpen' "$sidebar" \
  || fail 'sidebar clock timer is not gated by panel visibility'
rg -q 'function onLeftSidebarOpenChanged\(\): void' "$sidebar" \
  || fail 'sidebar does not refresh its clock immediately when opened'
rg -q 'if \(RaohaneState\.leftSidebarOpen\)' "$sidebar" \
  || fail 'sidebar open-state handler does not guard the immediate refresh'
rg -q 'root\.now = new Date\(\)' "$sidebar" \
  || fail 'sidebar no longer updates its displayed clock'

# Public entrypoints stay resident while the navigation rail itself is lazy.
for contract in \
  'target:[[:space:]]*"sidebarLeft"' \
  'RaohaneState\.togglePrimary\("leftSidebar"\)' \
  'RaohaneState\.setPrimaryOpen\("leftSidebar", true\)' \
  'RaohaneState\.setPrimaryOpen\("leftSidebar", false\)' \
  'name:[[:space:]]*"sidebarLeftToggle"'; do
  rg -q "$contract" "$surface_router" \
    || fail "resident left-sidebar router lost contract: $contract"
done
if rg -n 'target:[[:space:]]*"sidebarLeft"|name:[[:space:]]*"sidebarLeftToggle"' "$sidebar"; then
  fail 'lazy left sidebar regained duplicate resident IPC/shortcut ownership'
fi
if rg -q '^import Quickshell\.Io$' "$sidebar"; then
  fail 'lazy navigation-only sidebar still imports Quickshell.Io after entrypoint extraction'
fi

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

printf 'sidebar-performance-audit: lazy navigation rail, resident entrypoints, visibility-gated clock and no audio polling are valid\n'
