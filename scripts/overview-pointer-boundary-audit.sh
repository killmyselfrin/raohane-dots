#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'overview-pointer-boundary-audit: %s\n' "$*" >&2
  exit 1
}

overview='modules/raohane/RaohaneOverview.qml'
[[ -f "$overview" ]] || fail "missing $overview"

rg -q 'function activateWindow\(toplevel\): void' "$overview" \
  || fail 'Overview lost direct window activation helper'
rg -q 'toplevel\.wayland\.activate\(\)' "$overview" \
  || fail 'Overview no longer activates selected Wayland toplevels'
rg -q 'preventStealing:[[:space:]]*true' "$overview" \
  || fail 'window-row pointer area no longer protects its grab from the workspace card'
rg -q 'onClicked:[[:space:]]*root\.activateWindow\(windowRow\.modelData\)' "$overview" \
  || fail 'window-row click is not routed directly to window activation'
rg -q 'onClicked:[[:space:]]*root\.activateWorkspace\(workspaceCard\.workspaceId\)' "$overview" \
  || fail 'workspace background click no longer activates the workspace'

printf 'overview-pointer-boundary-audit: window rows retain pointer activation over workspace-card clicks\n'
