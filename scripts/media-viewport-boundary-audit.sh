#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'media-viewport-boundary-audit: %s\n' "$*" >&2
  exit 1
}

MEDIA='modules/raohane/RaohaneMediaOverlay.qml'
STAGE='modules/raohane/RaohaneMediaLyricsStage.qml'
VIEWPORT='modules/raohane/RaohaneMediaLyricsViewport.qml'
LINE='modules/raohane/RaohaneMediaLyricLine.qml'

for path in "$MEDIA" "$STAGE" "$VIEWPORT" "$LINE"; do
  [[ -f "$path" ]] || fail "missing synced-lyrics viewport path: $path"
done

# Overlay remains the service/state coordinator and delegates viewport access
# through the presentation-only Stage.
for contract in \
  'function centerCurrentLyric\(animated: bool\): void' \
  'lyricsStage\.centerCurrentLine\(animated\)' \
  'RaohaneMediaLyricsStage[[:space:]]*\{' \
  'id: lyricsStage' \
  'lines: RaohaneLyrics\.displayLines' \
  'focusMode: root\.lyricsFocus' \
  'syncedAvailable: RaohaneLyrics\.syncedAvailable' \
  'syncedIndex: RaohaneLyrics\.currentLineIndex' \
  'canSeek: RaohaneMedia\.canSeek' \
  'onSeekRequested: time =>' \
  'RaohaneMedia\.seekRatio\(time / RaohaneMedia\.length\)'; do
  rg -q "$contract" "$MEDIA" || fail "overlay lost synced-stage coordinator contract: $contract"
done

# Stage forwards display-ready state into the viewport and raw seek intents out.
for contract in \
  'function centerCurrentLine\(animated: bool\): void' \
  'lyricsViewport\.centerCurrentLine\(animated\)' \
  'RaohaneMediaLyricsViewport[[:space:]]*\{' \
  'id: lyricsViewport' \
  'lines: root\.lines' \
  'focusMode: root\.focusMode' \
  'syncedAvailable: root\.syncedAvailable' \
  'syncedIndex: root\.syncedIndex' \
  'canSeek: root\.canSeek' \
  'onSeekRequested: time => root\.seekRequested\(time\)'; do
  rg -q "$contract" "$STAGE" || fail "lyrics stage lost viewport wiring contract: $contract"
done

# Scrolling mechanics and line composition belong only to the viewport.
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

for file in "$STAGE" "$VIEWPORT"; do
  if rg -n '^import qs\.modules\.raohane\.(services|config)' "$file"; then
    fail "$file imported service/config modules"
  fi
  if rg -n 'Raohane(Media|Lyrics|Scenes|State|Config)\.|seekRatio|playerctl|Quickshell\.execDetached|\bProcess[[:space:]]*\{' "$file"; then
    fail "$file bypasses the overlay/service boundary"
  fi
done

# Coordinator and Stage should not regain direct ListView/contentY mechanics.
if rg -n 'id:[[:space:]]*lyricsScrollAnimation|lyricsList\.(itemAtIndex|positionViewAtIndex|contentY|contentHeight)|ListView[[:space:]]*\{' "$MEDIA" "$STAGE"; then
  fail 'Overlay or Stage regained synced viewport implementation details'
fi
if rg -n 'RaohaneMediaLyricsViewport[[:space:]]*\{' "$MEDIA"; then
  fail 'Overlay regained direct viewport composition'
fi

printf 'media-viewport-boundary-audit: Stage routes synced lyrics while viewport owns scrolling/line composition and Overlay owns final seek math\n'
