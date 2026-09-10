#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'media-hud-boundary-audit: %s\n' "$*" >&2
  exit 1
}

MEDIA='modules/raohane/RaohaneMediaOverlay.qml'
HUD='modules/raohane/RaohaneMediaPlayerHud.qml'

for path in "$MEDIA" "$HUD"; do
  [[ -f "$path" ]] || fail "missing media HUD boundary path: $path"
done

# Overlay remains the coordinator: it supplies service state and translates
# presentation signals back into native RaohaneMedia actions.
for contract in \
  'RaohaneMediaPlayerHud[[:space:]]*\{' \
  'id: playerHud' \
  'mediaAvailable: RaohaneMedia\.available' \
  'playing: RaohaneMedia\.isPlaying' \
  'canSeek: RaohaneMedia\.canSeek' \
  'canRaise: RaohaneMedia\.canRaise' \
  'volumeSupported: RaohaneMedia\.volumeSupported' \
  'playerCount: RaohaneMedia\.playerCount' \
  'elapsedText: RaohaneMedia\.length > 0' \
  'RaohaneMedia\.formatTime\(RaohaneMedia\.position\)' \
  'remainingText: RaohaneMedia\.length > 0' \
  'onCyclePlayerRequested: step => RaohaneMedia\.cyclePlayer\(step\)' \
  'onSeekRequested: ratio => RaohaneMedia\.seekRatio\(ratio\)' \
  'onLyricsRequested: root\.toggleLyrics\(\)' \
  'onRaiseRequested: RaohaneMedia\.raisePlayer\(\)' \
  'onCloseRequested: root\.close\(\)' \
  'onPreviousRequested: RaohaneMedia\.previous\(\)' \
  'onTogglePlayingRequested: RaohaneMedia\.togglePlaying\(\)' \
  'onNextRequested: RaohaneMedia\.next\(\)' \
  'onVolumeRequested: value => RaohaneMedia\.setVolume\(value\)'; do
  rg -q "$contract" "$MEDIA" || fail "overlay lost HUD coordinator contract: $contract"
done

for contract in \
  'property bool lyricsOpen: false' \
  'property bool gamingEdgeMode: false' \
  'property bool mediaAvailable: false' \
  'property bool playing: false' \
  'property bool canSeek: false' \
  'property bool canRaise: false' \
  'property bool canGoPrevious: false' \
  'property bool canTogglePlaying: false' \
  'property bool canGoNext: false' \
  'property bool volumeSupported: false' \
  'signal cyclePlayerRequested\(int step\)' \
  'signal seekRequested\(real ratio\)' \
  'signal lyricsRequested\(\)' \
  'signal raiseRequested\(\)' \
  'signal closeRequested\(\)' \
  'signal previousRequested\(\)' \
  'signal togglePlayingRequested\(\)' \
  'signal nextRequested\(\)' \
  'signal volumeRequested\(real value\)' \
  'implicitHeight: root\.lyricsOpen \? 74 : root\.gamingEdgeMode \? 90 : 108' \
  'id: cover' \
  'onMoved: ratio => root\.seekRequested\(ratio\)' \
  'onClicked: root\.cyclePlayerRequested\(-1\)' \
  'onClicked: root\.cyclePlayerRequested\(1\)' \
  'onClicked: root\.previousRequested\(\)' \
  'onClicked: root\.togglePlayingRequested\(\)' \
  'onClicked: root\.nextRequested\(\)' \
  'onMoved: value => root\.volumeRequested\(value\)'; do
  rg -q "$contract" "$HUD" || fail "HUD lost presentation contract: $contract"
done

# Gaming stays a denser presentation of the same HUD. Secondary controls and
# metadata disappear in Gaming instead of creating a second player surface.
rg -q 'visible: !root\.gamingEdgeMode && root\.canRaise' "$HUD" \
  || fail 'HUD no longer suppresses Raise Player in Gaming mode'
rg -q 'visible: !root\.gamingEdgeMode && !root\.lyricsOpen && root\.volumeSupported' "$HUD" \
  || fail 'HUD no longer suppresses volume in Gaming/lyrics mode'
rg -q 'Layout\.preferredWidth: root\.gamingEdgeMode \? 31 : 35' "$HUD" \
  || fail 'HUD elapsed timeline lost compact Gaming sizing'
rg -q 'Layout\.preferredWidth: root\.gamingEdgeMode \? 35 : 40' "$HUD" \
  || fail 'HUD remaining timeline lost compact Gaming sizing'

# The HUD is presentation-only. It may emit intent, but service ownership and
# MPRIS execution stay in RaohaneMediaOverlay.
if rg -n '^import qs\.modules\.raohane\.(services|config)' "$HUD"; then
  fail 'HUD imported service/config modules'
fi
if rg -n 'Raohane(Media|Lyrics|Scenes|State|Config)|playerctl|Quickshell\.execDetached|\bProcess[[:space:]]*\{' "$HUD"; then
  fail 'HUD bypasses the overlay/service boundary'
fi

# Avoid drifting back into duplicated transport implementations inside the
# coordinator after extraction.
if rg -n 'component MainButton:|id: hudCover|onClicked: RaohaneMedia\.(previous|togglePlaying|next)\(\)' "$MEDIA"; then
  fail 'Overlay regained inline HUD/transport presentation'
fi

printf 'media-hud-boundary-audit: HUD remains presentation-only with parent-owned MPRIS actions and compact Gaming geometry\n'
