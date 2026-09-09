#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'media-overlay-boundary-audit: %s\n' "$*" >&2
  exit 1
}

MEDIA=modules/raohane/RaohaneMediaOverlay.qml
[[ -f "$MEDIA" ]] || fail "missing media overlay: $MEDIA"

for contract in \
  'readonly property bool gamingEdgeMode: RaohaneScenes\.gaming' \
  'implicitWidth: root\.lyricsFocus \? 720' \
  ': root\.gamingEdgeMode \? 430' \
  ': root\.gamingEdgeMode \? 108' \
  'right: true' \
  'bottom: true' \
  'right: 24' \
  'bottom: 26' \
  'id: playerHud' \
  ': root\.gamingEdgeMode \? 90' \
  'id: hudCover' \
  'id: lyricsStage' \
  'visible: root\.lyricsOpen' \
  'id: lyricsMiniCover' \
  'RaohaneMedia\.cyclePlayer\(-1\)' \
  'RaohaneMedia\.cyclePlayer\(1\)' \
  'RaohaneMedia\.raisePlayer\(\)' \
  'RaohaneMedia\.setVolume\(value\)' \
  'id: lyricsScrollAnimation' \
  'duration: RaohaneMotion\.standard' \
  'RaohaneMedia\.seekRatio' \
  'RaohaneLyrics\.currentLineIndex'; do
  rg -q "$contract" "$MEDIA" || fail "media overlay lost contract: $contract"
done

# The player must stay at an edge. Do not bring back screen-width centering math
# or the old split/deck presentation that occupied the visual focus area.
if rg -n 'focusedScreen.*width.*implicitWidth|id:[[:space:]]*(artworkPane|transportRail|lyricsTransport)' "$MEDIA"; then
  fail 'media overlay regressed to centered or detached-card geometry'
fi

# Gaming is a compact presentation of the same native player. It should hide
# secondary metadata/volume/raise controls instead of spawning a second player.
rg -q 'visible: !root\.gamingEdgeMode.*RaohaneMedia\.canRaise' "$MEDIA" \
  || fail 'gaming edge mode no longer suppresses the secondary Raise Player action'
rg -q 'visible: !root\.gamingEdgeMode && !root\.lyricsOpen && RaohaneMedia\.volumeSupported' "$MEDIA" \
  || fail 'gaming edge mode no longer suppresses the volume rail'

# The outer surface may fade and the ListView may move to keep the current
# synced line centered. Glyphs themselves must stay stable: no zooming and no
# animated color/style/opacity transitions on lyric lines.
if rg -n 'Behavior on (scale|color|styleColor)' "$MEDIA"; then
  fail 'lyric/player text regained transform or color Behaviors'
fi
if rg -n '^[[:space:]]*scale:[[:space:]]' "$MEDIA"; then
  fail 'media overlay contains text/item scale state again'
fi

opacity_behaviors="$(rg -c 'Behavior on opacity' "$MEDIA" || true)"
if (( opacity_behaviors > 1 )); then
  fail 'more than the outer surface opacity animation is present'
fi

# Media actions remain native MPRIS/service calls. Do not grow shell-process
# control paths inside presentation QML.
if rg -n '\bProcess[[:space:]]*\{|Quickshell\.execDetached|playerctl' "$MEDIA"; then
  fail 'media presentation bypasses native RaohaneMedia services'
fi

printf 'media-overlay-boundary-audit: adaptive right-edge player, compact gaming mode, native MPRIS controls and stable lyric typography are valid\n'
