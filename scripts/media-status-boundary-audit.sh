#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'media-status-boundary-audit: %s\n' "$*" >&2
  exit 1
}

MEDIA='modules/raohane/RaohaneMediaOverlay.qml'
STAGE='modules/raohane/RaohaneMediaLyricsStage.qml'
STATUS='modules/raohane/RaohaneMediaLyricsStatus.qml'
VIEWPORT='modules/raohane/RaohaneMediaLyricsViewport.qml'

for path in "$MEDIA" "$STAGE" "$STATUS" "$VIEWPORT"; do
  [[ -f "$path" ]] || fail "missing media status boundary path: $path"
done

# Overlay owns service state and passes status-ready values through Stage.
for contract in \
  'RaohaneMediaLyricsStage[[:space:]]*\{' \
  'lyricsLoading: RaohaneLyrics\.loading' \
  'instrumental: RaohaneLyrics\.instrumental' \
  'lyricsAvailable: RaohaneLyrics\.available' \
  'errorText: RaohaneLyrics\.errorText' \
  'accent: root\.playerAccent'; do
  rg -q "$contract" "$MEDIA" || fail "overlay lost lyrics-status stage contract: $contract"
done

# Stage owns the status/viewport composition, never the underlying services.
for contract in \
  'RaohaneMediaLyricsStatus[[:space:]]*\{' \
  'loading: root\.lyricsLoading' \
  'instrumental: root\.instrumental' \
  'available: root\.lyricsAvailable' \
  'errorText: root\.errorText' \
  'accent: root\.accent' \
  'RaohaneMediaLyricsViewport[[:space:]]*\{' \
  'id: lyricsViewport' \
  'visible: !root\.lyricsLoading && root\.lyricsAvailable && !root\.instrumental'; do
  rg -q "$contract" "$STAGE" || fail "lyrics stage lost status/viewport ownership contract: $contract"
done

for contract in \
  'property bool loading: false' \
  'property bool instrumental: false' \
  'property bool available: false' \
  'property string errorText: ""' \
  'property color accent: RaohaneTheme\.accent' \
  'visible: root\.loading \|\| root\.instrumental \|\| !root\.available' \
  'text: qsTr\("Looking for lyrics…"\)' \
  'text: qsTr\("Instrumental track"\)' \
  'text: qsTr\("No vocal lyrics are expected for this recording\."\)' \
  'qsTr\("Lyrics are not available yet"\)'; do
  rg -q "$contract" "$STATUS" || fail "lyrics status lost presentation contract: $contract"
done

for file in "$STAGE" "$STATUS"; do
  if rg -n '^import qs\.modules\.raohane\.(services|config)' "$file"; then
    fail "$file imported service/config modules"
  fi
  if rg -n 'Raohane(Media|Lyrics|Scenes|State|Config)\.|playerctl|Quickshell\.execDetached|\bProcess[[:space:]]*\{' "$file"; then
    fail "$file bypasses the overlay/service boundary"
  fi
done

# Status rendering stays isolated from synced-line mechanics. Stage may compose
# the separate viewport, but the Status leaf itself must never absorb it.
if rg -n 'ListView[[:space:]]*\{|RaohaneMediaLyricLine|seekRequested|contentY' "$STATUS"; then
  fail 'lyrics status absorbed synced-list/seek responsibilities'
fi
rg -q 'ListView[[:space:]]*\{' "$VIEWPORT" \
  || fail 'synced viewport lost ListView ownership after Stage extraction'
if rg -n 'RaohaneMediaLyrics(Status|Viewport)[[:space:]]*\{' "$MEDIA"; then
  fail 'Overlay regained direct lyrics status/viewport composition'
fi

printf 'media-status-boundary-audit: status states remain presentation-only behind Stage while synced scrolling belongs to the extracted viewport\n'
