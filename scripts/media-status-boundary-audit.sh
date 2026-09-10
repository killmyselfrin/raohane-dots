#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'media-status-boundary-audit: %s\n' "$*" >&2
  exit 1
}

MEDIA='modules/raohane/RaohaneMediaOverlay.qml'
STATUS='modules/raohane/RaohaneMediaLyricsStatus.qml'
VIEWPORT='modules/raohane/RaohaneMediaLyricsViewport.qml'

for path in "$MEDIA" "$STATUS" "$VIEWPORT"; do
  [[ -f "$path" ]] || fail "missing media status boundary path: $path"
done

for contract in \
  'RaohaneMediaLyricsStatus[[:space:]]*\{' \
  'loading: RaohaneLyrics\.loading' \
  'instrumental: RaohaneLyrics\.instrumental' \
  'available: RaohaneLyrics\.available' \
  'errorText: RaohaneLyrics\.errorText' \
  'accent: root\.playerAccent' \
  'RaohaneMediaLyricsViewport[[:space:]]*\{' \
  'id: lyricsViewport' \
  'visible: !RaohaneLyrics\.loading && RaohaneLyrics\.available && !RaohaneLyrics\.instrumental'; do
  rg -q "$contract" "$MEDIA" || fail "overlay lost lyrics-status/viewport ownership contract: $contract"
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

if rg -n '^import qs\.modules\.raohane\.(services|config)' "$STATUS"; then
  fail 'lyrics status imported service/config modules'
fi
if rg -n 'Raohane(Media|Lyrics|Scenes|State|Config)|playerctl|Quickshell\.execDetached|\bProcess[[:space:]]*\{' "$STATUS"; then
  fail 'lyrics status bypasses the overlay/service boundary'
fi

# Status rendering stays isolated from synced-line mechanics. The extracted
# viewport owns ListView/scrolling/seek signaling and is validated separately.
if rg -n 'ListView[[:space:]]*\{|RaohaneMediaLyricLine|seekRequested|contentY' "$STATUS"; then
  fail 'lyrics status absorbed synced-list/seek responsibilities'
fi
rg -q 'ListView[[:space:]]*\{' "$VIEWPORT" \
  || fail 'synced viewport lost ListView ownership after status extraction'

printf 'media-status-boundary-audit: loading/instrumental/unavailable states remain presentation-only while synced scrolling belongs to the extracted viewport\n'
