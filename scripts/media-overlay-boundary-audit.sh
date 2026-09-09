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
  'implicitWidth: root\.lyricsFocus \? 720 : 820' \
  'implicitHeight: root\.lyricsFocus \? 520 : root\.lyricsOpen \? 520 : 164' \
  'left: true' \
  'bottom: true' \
  'bottom: 28' \
  'id: playerHud' \
  'Layout\.preferredHeight: root\.lyricsFocus \? 0 : 132' \
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

# The media surface is now a bottom floating HUD. Lyrics expand above the same
# persistent transport surface instead of replacing it with another card.
if rg -n 'id:[[:space:]]*(artworkPane|transportRail|lyricsTransport)' "$MEDIA"; then
  fail 'media overlay regressed to a detached card/deck layout'
fi

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

printf 'media-overlay-boundary-audit: bottom floating HUD, expanding lyrics, native MPRIS controls and stable lyric typography are valid\n'
