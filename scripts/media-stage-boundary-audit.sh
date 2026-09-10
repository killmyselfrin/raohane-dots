#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'media-stage-boundary-audit: %s\n' "$*" >&2
  exit 1
}

MEDIA='modules/raohane/RaohaneMediaOverlay.qml'
STAGE='modules/raohane/RaohaneMediaLyricsStage.qml'
HEADER='modules/raohane/RaohaneMediaLyricsHeader.qml'
STATUS='modules/raohane/RaohaneMediaLyricsStatus.qml'
VIEWPORT='modules/raohane/RaohaneMediaLyricsViewport.qml'

for path in "$MEDIA" "$STAGE" "$HEADER" "$STATUS" "$VIEWPORT"; do
  [[ -f "$path" ]] || fail "missing media lyrics stage path: $path"
done

# Overlay owns service state and actions, while Stage receives display-ready
# values and emits intent signals back to the coordinator.
for contract in \
  'RaohaneMediaLyricsStage[[:space:]]*\{' \
  'id: lyricsStage' \
  'focusMode: root\.lyricsFocus' \
  'artUrl: RaohaneMedia\.artUrl' \
  'lyricsLoading: RaohaneLyrics\.loading' \
  'lyricsAvailable: RaohaneLyrics\.available' \
  'instrumental: RaohaneLyrics\.instrumental' \
  'lines: RaohaneLyrics\.displayLines' \
  'syncedAvailable: RaohaneLyrics\.syncedAvailable' \
  'syncedIndex: RaohaneLyrics\.currentLineIndex' \
  'canSeek: RaohaneMedia\.canSeek' \
  'onBackRequested:' \
  'onRefreshRequested: RaohaneLyrics\.forceRefresh\(\)' \
  'onFocusRequested: root\.toggleLyricsFocus\(\)' \
  'onCloseRequested: root\.close\(\)' \
  'onSeekRequested: time =>' \
  'RaohaneMedia\.seekRatio\(time / RaohaneMedia\.length\)' \
  'lyricsStage\.centerCurrentLine\(animated\)'; do
  rg -q "$contract" "$MEDIA" || fail "overlay lost lyrics-stage coordinator contract: $contract"
done

# Stage owns only composition, focus-mode presentation and raw intent routing.
for contract in \
  'property bool focusMode: false' \
  'property var lines: \[\]' \
  'property bool syncedAvailable: false' \
  'property int syncedIndex: -1' \
  'signal backRequested\(\)' \
  'signal refreshRequested\(\)' \
  'signal focusRequested\(\)' \
  'signal closeRequested\(\)' \
  'signal seekRequested\(real time\)' \
  'function centerCurrentLine\(animated: bool\): void' \
  'lyricsViewport\.centerCurrentLine\(animated\)' \
  'RaohaneMediaLyricsHeader[[:space:]]*\{' \
  'RaohaneMediaLyricsStatus[[:space:]]*\{' \
  'RaohaneMediaLyricsViewport[[:space:]]*\{' \
  'id: lyricsViewport' \
  'onSeekRequested: time => root\.seekRequested\(time\)' \
  'visible: root\.focusMode' \
  'acceptedButtons: Qt\.RightButton' \
  'onClicked: root\.focusRequested\(\)'; do
  rg -q "$contract" "$STAGE" || fail "lyrics stage lost presentation/composition contract: $contract"
done

# Stage and leaves never own services/config/process execution.
for file in "$STAGE" "$HEADER" "$STATUS" "$VIEWPORT"; do
  if rg -n '^import qs\.modules\.raohane\.(services|config)' "$file"; then
    fail "$file imported service/config modules"
  fi
  if rg -n 'Raohane(Media|Lyrics|Scenes|State|Config)\.|seekRatio|playerctl|Quickshell\.execDetached|\bProcess[[:space:]]*\{' "$file"; then
    fail "$file bypasses media stage/service ownership"
  fi
done

# Overlay should compose Stage, not silently rebuild its leaf hierarchy.
if rg -n 'RaohaneMediaLyrics(Header|Status|Viewport)[[:space:]]*\{' "$MEDIA"; then
  fail 'Overlay regained direct lyrics leaf composition'
fi

printf 'media-stage-boundary-audit: lyrics stage composes presentation leaves while service state, transitions and seek ratio remain coordinator-owned\n'
