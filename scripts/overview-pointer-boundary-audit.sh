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

for contract in \
  'function activatePosition\(position: int\): void' \
  'function shortcutLabel\(index: int\): string' \
  'event\.key >= Qt\.Key_1 && event\.key <= Qt\.Key_9' \
  'event\.key === Qt\.Key_0' \
  'shortcutLabel:[[:space:]]*root\.shortcutLabel\(index\)'; do
  rg -q "$contract" "$overview" || fail "Overview lost numeric workspace shortcut contract: $contract"
done
rg -q 'property string shortcutLabel:[[:space:]]*""' "$card" \
  || fail 'workspace card lost visible numeric shortcut label'

rg -q 'RaohaneOverviewWindowRow[[:space:]]*\{' "$card" \
  || fail 'workspace card no longer composes extracted window rows'
rg -q 'onActivated:[[:space:]]*toplevel[[:space:]]*=>[[:space:]]*root\.windowActivated\(toplevel\)' "$card" \
  || fail 'window-row click no longer bubbles through the workspace card'
rg -q 'onClicked:[[:space:]]*root\.workspaceActivated\(root\.workspaceId\)' "$card" \
  || fail 'workspace background click no longer emits workspace activation'
rg -q 'preventStealing:[[:space:]]*true' "$window_row" \
  || fail 'window-row pointer area no longer protects its grab from the workspace card'
# Drag-safe clicks are guarded instead of forwarded unconditionally.
rg -Fq 'onClicked: {' "$window_row" \
  || fail 'Overview window row lost its click handler'
rg -Fq 'if (!root.suppressClick)' "$window_row" \
  || fail 'Overview window row activates accidentally after drag'
rg -Fq 'root.activated(root.toplevel)' "$window_row" \
  || fail 'Overview window row no longer activates selected windows'

# Overview labels follow Hyprland workspace names, while window icons use
# the native Wayland application ID rather than guessing from titles.
for contract in 'workspaceObject?.name' 'root.workspaceName' 'root.focusedTitle'; do
  rg -Fq "$contract" "$card" || fail "Overview lost named workspace header contract: $contract"
done
for contract in 'RaohaneAdaptiveIcon' 'root.toplevel?.wayland?.appId' 'root.urgentWindow'; do
  rg -Fq "$contract" "$window_row" || fail "Overview lost app icon/fallback contract: $contract"
done

  # Overview keeps one screenshot per selected workspace, captured once. It
# must not add permanent live streams, subprocess polling, or mouse-only
# navigation paths when drag-and-drop is added.
for contract in \
  'moveWindowToWorkspace(toplevel, workspaceId: int)' \
  'movetoworkspacesilent' \
  'hl.dsp.window.move(' \
  'function beginWindowDrag(' \
  'function finishWindowDrag(' \
  'dragProxy.Drag.drop()' \
  'dragProxy.Drag.cancel()' \
  'previewEnabled: RaohaneState.overviewOpen' \
  'property bool presented: false'; do
  rg -Fq "$contract" "$overview" || fail "Overview interaction/motion contract missing: $contract"
done
for contract in \
  'ScreencopyView {' \
  'live: false' \
  'active: root.previewEnabled' \
  'keys: ["raohane-overview-window"]' \
  'onDropped: drop =>' \
  'root.windowDropped(dragged.toplevel, root.workspaceId)' \
  'Behavior on opacity'; do
  rg -Fq "$contract" "$card" || fail "Overview preview/target contract missing: $contract"
done
for contract in \
  'signal windowDragStarted(' \
  'signal windowDragMoved(' \
  'signal windowDragFinished()' \
  'root.suppressClick' \
  'preventStealing: true' \
  'onClicked: {'; do
  rg -Fq "$contract" "$window_row" || fail "Overview window drag/click contract missing: $contract"
done
if rg -n 'live:[[:space:]]*true|Process[[:space:]]*\{|hyprctl' "$overview" "$card" "$window_row"; then
  fail 'Overview preview/drag regressed to live screencopy or active shell polling'
fi
rg -Uq '"overview":[[:space:]]*\{[^}]*deferredUnload:[[:space:]]*true' modules/raohane/RaohaneSurfaceRegistry.qml \
  || fail 'Overview is destroyed before its dismissal animation can finish'

printf 'overview-pointer-boundary-audit: %s\n' "$*" >&2
  exit 1

printf 'overview-pointer-boundary-audit: extracted window rows retain pointer activation and Overview exposes direct numeric workspace shortcuts\n'
