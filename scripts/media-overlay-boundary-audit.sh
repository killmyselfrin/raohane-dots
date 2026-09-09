#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'media-overlay-boundary-audit: %s\n' "$*" >&2
  exit 1
}

MEDIA=modules/raohane/RaohaneMediaOverlay.qml
CONTEXT=modules/raohane/RaohaneContext.qml
ISLAND=modules/raohane/RaohaneContextIsland.qml
CONFIG=modules/raohane/config/RaohaneConfig.qml
SETTINGS=modules/raohane/RaohaneSettingsPageRegistry.qml
SECTIONS=modules/raohane/RaohaneSettingsSectionRegistry.qml
STUDIO=modules/raohane/RaohaneMediaStudio.qml
DEFAULTS=defaults/native.json

for file in "$MEDIA" "$CONTEXT" "$ISLAND" "$CONFIG" "$SETTINGS" "$SECTIONS" "$STUDIO" "$DEFAULTS"; do
  [[ -f "$file" ]] || fail "missing media placement contract file: $file"
done

for contract in \
  'import qs\.modules\.raohane\.config' \
  'readonly property bool gamingScene: RaohaneScenes\.gaming' \
  'readonly property bool gamingEdgeMode: root\.gamingScene' \
  'readonly property int gamingAutoHideSeconds:' \
  'readonly property bool gamingAutoHideEnabled:' \
  'function armGamingAutoHide\(\): void' \
  'id: gamingAutoHideTimer' \
  'id: mediaHover' \
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
  'RaohaneMedia\.formatTime\(RaohaneMedia\.position\)' \
  'RaohaneMedia\.formatTime\(Math\.max\(0, RaohaneMedia\.length - RaohaneMedia\.position\)\)' \
  'RaohaneLyrics\.currentLineIndex'; do
  rg -q "$contract" "$MEDIA" || fail "media overlay lost contract: $contract"
done

# The Context Island owns compact media context only while the dedicated media
# overlay is closed. Recording/privacy/transient event priority stays intact.
for contract in \
  'readonly property bool mediaOverlayVisible: RaohaneState\.mediaOverlayOpen' \
  'readonly property bool mediaActive: RaohaneMedia\.available && !root\.mediaOverlayVisible' \
  'mediaOverlayVisible: mediaOverlayVisible'; do
  rg -q "$contract" "$CONTEXT" || fail "Context Island media handoff lost contract: $contract"
done

# Compact media context is an entry point to the dedicated player, not a second
# half-working mini-player. Clicking the Island opens the overlay and the icon
# communicates that transition explicitly.
for contract in \
  'readonly property bool mediaMode: RaohaneContext\.mode === "media"' \
  'root\.mediaMode \? "open_in_new"' \
  'id: mediaOpenArea' \
  'enabled: root\.mediaMode' \
  'onClicked: RaohaneState\.mediaOverlayOpen = true'; do
  rg -q "$contract" "$ISLAND" || fail "Context Island media entrypoint lost contract: $contract"
done

# One Scene change should produce one coherent Island event. DND, Game Mode and
# Keep Awake changes applied by that Scene are implementation details and must
# not cascade over the scene feedback. Manual changes outside this short
# transition window still surface normally.
for contract in \
  'property bool sceneTransitionMuted: false' \
  'root\.sceneTransitionMuted = true' \
  'sceneTransitionTimer\.restart\(\)' \
  'id: sceneTransitionTimer' \
  'interval: 1800' \
  'if \(!root\.eventSignalsReady \|\| root\.sceneTransitionMuted\)'; do
  rg -q "$contract" "$CONTEXT" || fail "Context Island scene coalescing lost contract: $contract"
done
coalesced_guards="$(rg -c 'if \(!root\.eventSignalsReady \|\| root\.sceneTransitionMuted\)' "$CONTEXT" || true)"
if (( coalesced_guards < 3 )); then
  fail 'scene transition no longer suppresses DND, Game Mode and Keep Awake event cascades'
fi

for contract in \
  'property string mediaOverlayPosition: "bottom-right"' \
  'property string mediaOverlayGamingPosition: "bottom-right"' \
  'property int mediaOverlayGamingAutoHideSeconds: 8' \
  'function sanitizeMediaOverlayPosition' \
  'function sanitizeMediaOverlayGamingAutoHideSeconds' \
  'mediaOverlayPosition: root\.sanitizeMediaOverlayPosition' \
  'mediaOverlayGamingPosition: root\.sanitizeMediaOverlayPosition' \
  'mediaOverlayGamingAutoHideSeconds: root\.sanitizeMediaOverlayGamingAutoHideSeconds' \
  'onMediaOverlayPositionChanged: scheduleSave\(\)' \
  'onMediaOverlayGamingPositionChanged: scheduleSave\(\)' \
  'onMediaOverlayGamingAutoHideSecondsChanged: scheduleSave\(\)'; do
  rg -q "$contract" "$CONFIG" || fail "native config lost media placement contract: $contract"
done

# Media controls belong to one visual studio. Generic rows must not reappear
# beside the studio and duplicate the same settings. Keep the ownership check
# key-based so formatting the array over multiple lines cannot break CI.
rg -q 'source: "RaohaneMediaStudio\.qml"' "$SECTIONS" \
  || fail 'Media & OSD lost the visual Media Position Studio extension'
for key in mediaOverlayPosition mediaOverlayGamingPosition mediaOverlayGamingAutoHideSeconds; do
  rg -q "\"$key\"" "$SECTIONS" \
    || fail "Media Studio ownership lost control key: $key"
  rg -q "RaohaneConfig\.$key" "$STUDIO" \
    || fail "Media Position Studio lost config binding: $key"
done

for key in mediaOverlayPosition mediaOverlayGamingPosition; do
  if rg -q "type: \"choice\", key: \"$key\"" "$SETTINGS"; then
    fail "Media & OSD duplicated $key as both generic choice and visual studio"
  fi
  rg -q "section: \"general\", key: \"$key\"" "$SETTINGS" \
    || fail "Settings search lost visual studio route: $key"
done

for value in top-left top-right bottom-left bottom-right; do
  rg -q "value: \"$value\"" "$STUDIO" \
    || fail "Media Position Studio lost position option: $value"
done

for contract in \
  'import qs\.modules\.raohane\.services' \
  'readonly property bool gamingActive: RaohaneScenes\.gaming' \
  'function previewPlayer\(\)' \
  'RaohaneState\.mediaOverlayOpen = true' \
  'qsTr\("LIVE · GAMING"\)' \
  'qsTr\("LIVE · DESKTOP"\)' \
  'title: qsTr\("Desktop"\)' \
  'title: qsTr\("Gaming"\)' \
  'qsTr\("Gaming auto-hide"\)' \
  'value: 0, label: qsTr\("Off"\)' \
  'value: 4, label: "4s"' \
  'value: 8, label: "8s"' \
  'value: 15, label: "15s"' \
  'activePolicy: !root\.gamingActive' \
  'activePolicy: root\.gamingActive' \
  'onSelected: position => RaohaneConfig\.mediaOverlayPosition = position' \
  'onSelected: position => RaohaneConfig\.mediaOverlayGamingPosition = position' \
  'onClicked: RaohaneConfig\.mediaOverlayGamingAutoHideSeconds = autoHideButton\.optionValue' \
  'MouseArea[[:space:]]*\{' \
  'cursorShape: Qt\.PointingHandCursor'; do
  rg -q "$contract" "$STUDIO" || fail "Media Position Studio lost interaction contract: $contract"
done

jq -e '.schemaVersion == 13' "$DEFAULTS" >/dev/null \
  || fail 'native defaults schema unexpectedly changed'
jq -e '.features.mediaOverlayPosition == "bottom-right" and .features.mediaOverlayGamingPosition == "bottom-right" and .features.mediaOverlayGamingAutoHideSeconds == 8' "$DEFAULTS" >/dev/null \
  || fail 'native defaults lost media placement or Gaming auto-hide defaults'

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

# Gaming auto-hide is opt-out, hover-aware and must never dismiss lyrics.
rg -q '!root\.lyricsOpen' "$MEDIA" \
  || fail 'Gaming auto-hide no longer protects expanded lyrics'
rg -q '!root\.lyricsFocus' "$MEDIA" \
  || fail 'Gaming auto-hide no longer protects lyrics-only focus mode'
rg -q 'if \(hovered\)' "$MEDIA" \
  || fail 'Gaming auto-hide no longer pauses on pointer hover'
rg -q 'gamingAutoHideTimer\.stop\(\)' "$MEDIA" \
  || fail 'Gaming auto-hide lost explicit timer cancellation'

# Timeline feedback must reuse the existing compact geometry rather than
# growing the Gaming surface or adding a detached status strip.
rg -q 'Layout\.preferredWidth: root\.gamingEdgeMode \? 31 : 35' "$MEDIA" \
  || fail 'elapsed timeline label lost compact Gaming sizing'
rg -q 'Layout\.preferredWidth: root\.gamingEdgeMode \? 35 : 40' "$MEDIA" \
  || fail 'remaining timeline label lost compact Gaming sizing'

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
if rg -n '\bProcess[[:space:]]*\{|Quickshell\.execDetached|playerctl' "$MEDIA" "$STUDIO" "$CONTEXT" "$ISLAND"; then
  fail 'media presentation bypasses native RaohaneMedia/config services'
fi

printf 'media-overlay-boundary-audit: visual corner studio, compact timeline, Gaming auto-hide, context handoff, media island entrypoint, scene coalescing, live scene preview, native MPRIS controls and stable lyric typography are valid\n'
