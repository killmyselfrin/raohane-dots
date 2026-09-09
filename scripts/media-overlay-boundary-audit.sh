#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'media-overlay-boundary-audit: %s\n' "$*" >&2
  exit 1
}

MEDIA=modules/raohane/RaohaneMediaOverlay.qml
CONFIG=modules/raohane/config/RaohaneConfig.qml
SETTINGS=modules/raohane/RaohaneSettingsPageRegistry.qml
DEFAULTS=defaults/native.json

for file in "$MEDIA" "$CONFIG" "$SETTINGS" "$DEFAULTS"; do
  [[ -f "$file" ]] || fail "missing media placement contract file: $file"
done

for contract in \
  'import qs\.modules\.raohane\.config' \
  'readonly property bool gamingScene: RaohaneScenes\.gaming' \
  'readonly property bool gamingEdgeMode: root\.gamingScene' \
  'RaohaneConfig\.mediaOverlayPosition' \
  'RaohaneConfig\.mediaOverlayGamingPosition' \
  'left: root\.positionLeft' \
  'right: root\.positionRight' \
  'top: root\.positionTop' \
  'bottom: root\.positionBottom' \
  'left: root\.positionLeft \? 24 : 0' \
  'right: root\.positionRight \? 24 : 0' \
  'top: root\.positionTop \? 26 : 0' \
  'bottom: root\.positionBottom \? 26 : 0' \
  'implicitWidth: root\.lyricsFocus \? 720' \
  ': root\.gamingEdgeMode \? 430' \
  ': root\.gamingEdgeMode \? 108' \
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

for contract in \
  'property string mediaOverlayPosition: "bottom-right"' \
  'property string mediaOverlayGamingPosition: "bottom-right"' \
  'function sanitizeMediaOverlayPosition' \
  'mediaOverlayPosition: root\.sanitizeMediaOverlayPosition' \
  'mediaOverlayGamingPosition: root\.sanitizeMediaOverlayPosition' \
  'onMediaOverlayPositionChanged: scheduleSave\(\)' \
  'onMediaOverlayGamingPositionChanged: scheduleSave\(\)'; do
  rg -q "$contract" "$CONFIG" || fail "native config lost media placement contract: $contract"
done

for key in mediaOverlayPosition mediaOverlayGamingPosition; do
  rg -q "type: \"choice\", key: \"$key\"" "$SETTINGS" \
    || fail "Media & OSD settings lost choice: $key"
done
for value in top-left top-right bottom-left bottom-right; do
  rg -q "value: \"$value\"" "$SETTINGS" \
    || fail "Media & OSD settings lost position option: $value"
done

jq -e '.schemaVersion == 13' "$DEFAULTS" >/dev/null \
  || fail 'native defaults schema unexpectedly changed'
jq -e '.features.mediaOverlayPosition == "bottom-right" and .features.mediaOverlayGamingPosition == "bottom-right"' "$DEFAULTS" >/dev/null \
  || fail 'native defaults lost media placement defaults'

# The player must stay at a corner. Do not bring back screen-width centering
# math or the old split/deck presentation that occupied the visual focus area.
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

printf 'media-overlay-boundary-audit: configurable corner placement, compact gaming mode, native MPRIS controls and stable lyric typography are valid\n'
