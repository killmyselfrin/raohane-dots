#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'overview-pointer-boundary-audit: %s\n' "$*" >&2
  exit 1
}

overview='modules/raohane/RaohaneOverview.qml'
card='modules/raohane/RaohaneOverviewWorkspaceCard.qml'
window_row='modules/raohane/RaohaneOverviewWindowRow.qml'
qmldir='modules/raohane/qmldir'

for file in "$overview" "$card" "$window_row" "$qmldir"; do
  [[ -f "$file" ]] || fail "missing $file"
done

for registration in \
  '^RaohaneOverviewWorkspaceCard .*RaohaneOverviewWorkspaceCard.qml$' \
  '^RaohaneOverviewWindowRow .*RaohaneOverviewWindowRow.qml$'; do
  rg -q "$registration" "$qmldir" || fail "Overview v2 lost registration: $registration"
done

rg -q 'function activateWindow\(toplevel\): void' "$overview" \
  || fail 'Overview lost direct window activation helper'
rg -q 'toplevel\.wayland\.activate\(\)' "$overview" \
  || fail 'Overview no longer activates selected Wayland toplevels'
rg -q 'RaohaneOverviewWorkspaceCard[[:space:]]*\{' "$overview" \
  || fail 'Overview no longer composes extracted workspace cards'
rg -q 'onWindowActivated:[[:space:]]*toplevel[[:space:]]*=>[[:space:]]*root\.activateWindow\(toplevel\)' "$overview" \
  || fail 'workspace-card window activation no longer routes to Overview activation helper'
rg -q 'onWorkspaceActivated:[[:space:]]*workspaceId[[:space:]]*=>[[:space:]]*root\.activateWorkspace\(workspaceId\)' "$overview" \
  || fail 'workspace-card background activation no longer routes to workspace activation'

rg -q 'RaohaneOverviewWindowRow[[:space:]]*\{' "$card" \
  || fail 'workspace card no longer composes extracted window rows'
rg -q 'onActivated:[[:space:]]*toplevel[[:space:]]*=>[[:space:]]*root\.windowActivated\(toplevel\)' "$card" \
  || fail 'window-row click no longer bubbles through the workspace card'
rg -q 'onClicked:[[:space:]]*root\.workspaceActivated\(root\.workspaceId\)' "$card" \
  || fail 'workspace background click no longer emits workspace activation'
rg -q 'preventStealing:[[:space:]]*true' "$window_row" \
  || fail 'window-row pointer area no longer protects its grab from the workspace card'
rg -q 'onClicked:[[:space:]]*root\.activated\(root\.toplevel\)' "$window_row" \
  || fail 'window-row pointer no longer emits direct toplevel activation'

printf 'overview-pointer-boundary-audit: extracted window rows retain pointer activation over workspace-card clicks\n'
