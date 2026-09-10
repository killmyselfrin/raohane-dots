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

for path in "$MEDIA" "$STATUS"; do
  [[ -f "$path" ]] || fail "missing media status boundary path: $path"
done

for contract in \
  'RaohaneMediaLyricsStatus[[:space:]]*\{' \
  'loading: RaohaneLyrics\.loading' \
  'instrumental: RaohaneLyrics\.instrumental' \
  'available: RaohaneLyrics\.available' \
  'errorText: RaohaneLyrics\.errorText' \
  'accent: root\.playerAccent' \
  'id: lyricsList' \
  'visible: !RaohaneLyrics\.loading && RaohaneLyrics\.available && !RaohaneLyrics\.instrumental' \
  'id: lyricsScrollAnimation'; do
  rg -q "$contract" "$MEDIA" || fail "overlay lost lyrics-status/list ownership contract: $contract"
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

# Scrolling and seeking are deliberately not part of this extraction yet.
if rg -n 'ListView[[:space:]]*\{|RaohaneMediaLyricLine|seekRequested|contentY' "$STATUS"; then
  fail 'lyrics status absorbed synced-list/seek responsibilities'
fi

printf 'media-status-boundary-audit: loading/instrumental/unavailable states remain presentation-only while synced scrolling stays in the coordinator\n'
