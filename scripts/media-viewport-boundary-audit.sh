#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'media-viewport-boundary-audit: %s\n' "$*" >&2
  exit 1
}

MEDIA='modules/raohane/RaohaneMediaOverlay.qml'
VIEWPORT='modules/raohane/RaohaneMediaLyricsViewport.qml'
LINE='modules/raohane/RaohaneMediaLyricLine.qml'

for path in "$MEDIA" "$VIEWPORT" "$LINE"; do
  [[ -f "$path" ]] || fail "missing synced-lyrics viewport path: $path"
done

# Overlay stays the service/state coordinator and delegates all viewport math.
for contract in \
  'function centerCurrentLyric\(animated: bool\): void' \
  'lyricsViewport\.centerCurrentLine\(animated\)' \
  'RaohaneMediaLyricsViewport[[:space:]]*\{' \
  'id: lyricsViewport' \
  'lines: RaohaneLyrics\.displayLines' \
  'focusMode: root\.lyricsFocus' \
  'syncedAvailable: RaohaneLyrics\.syncedAvailable' \
  'syncedIndex: RaohaneLyrics\.currentLineIndex' \
  'canSeek: RaohaneMedia\.canSeek' \
  'onSeekRequested: time =>' \
  'RaohaneMedia\.seekRatio\(time / RaohaneMedia\.length\)'; do
  rg -q "$contract" "$MEDIA" || fail "overlay lost synced-viewport coordinator contract: $contract"
done

# Scrolling mechanics and line composition belong to the presentation viewport.
for contract in \
  'ListView[[:space:]]*\{' \
  'property var lines: \[\]' \
  'property bool focusMode: false' \
  'property bool syncedAvailable: false' \
  'property int syncedIndex: -1' \
  'property bool canSeek: false' \
  'signal seekRequested\(real time\)' \
  'currentIndex: root\.syncedAvailable \? root\.syncedIndex : -1' \
  'function centerCurrentLine\(animated: bool\): void' \
  'root\.itemAtIndex\(root\.syncedIndex\)' \
  'root\.positionViewAtIndex\(root\.syncedIndex, ListView\.Center\)' \
  'property: "contentY"' \
  'duration: RaohaneMotion\.standard' \
  'delegate: RaohaneMediaLyricLine' \
  'onSeekRequested: time => root\.seekRequested\(time\)'; do
  rg -q "$contract" "$VIEWPORT" || fail "synced viewport lost presentation contract: $contract"
done

# The viewport may own scroll mechanics but never service state or ratio math.
if rg -n '^import qs\.modules\.raohane\.(services|config)' "$VIEWPORT"; then
  fail 'synced viewport imported service/config modules'
fi
if rg -n 'Raohane(Media|Lyrics|Scenes|State|Config)\.|seekRatio|playerctl|Quickshell\.execDetached|\bProcess[[:space:]]*\{' "$VIEWPORT"; then
  fail 'synced viewport bypasses the overlay/service boundary'
fi

# Coordinator should not regain direct ListView/contentY implementation.
if rg -n 'id:[[:space:]]*lyricsScrollAnimation|lyricsList\.(itemAtIndex|positionViewAtIndex|contentY|contentHeight)' "$MEDIA"; then
  fail 'Overlay regained synced viewport implementation details'
fi

printf 'media-viewport-boundary-audit: synced scrolling and lyric-line composition are presentation-owned while service seek math stays in the overlay\n'
