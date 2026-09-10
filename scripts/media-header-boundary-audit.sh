#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'media-header-boundary-audit: %s\n' "$*" >&2
  exit 1
}

MEDIA='modules/raohane/RaohaneMediaOverlay.qml'
HEADER='modules/raohane/RaohaneMediaLyricsHeader.qml'

for path in "$MEDIA" "$HEADER"; do
  [[ -f "$path" ]] || fail "missing media header boundary path: $path"
done

# The Overlay owns service/state transitions and hands display-ready values to
# the extracted header.
for contract in \
  'RaohaneMediaLyricsHeader[[:space:]]*\{' \
  'artUrl: RaohaneMedia\.artUrl' \
  'accent: root\.playerAccent' \
  'title: RaohaneMedia\.title\.length > 0' \
  'subtitle: RaohaneLyrics\.syncedAvailable' \
  'mediaAvailable: RaohaneMedia\.available' \
  'lyricsLoading: RaohaneLyrics\.loading' \
  'lyricsAvailable: RaohaneLyrics\.available' \
  'onBackRequested:' \
  'root\.lyricsOpen = false' \
  'Qt\.callLater\(root\.armGamingAutoHide\)' \
  'onRefreshRequested: RaohaneLyrics\.forceRefresh\(\)' \
  'onFocusRequested: root\.toggleLyricsFocus\(\)' \
  'onCloseRequested: root\.close\(\)'; do
  rg -q "$contract" "$MEDIA" || fail "overlay lost lyrics-header coordinator contract: $contract"
done

for contract in \
  'property url artUrl: ""' \
  'property color accent: RaohaneTheme\.accent' \
  'property string title: ""' \
  'property string subtitle: ""' \
  'property bool mediaAvailable: false' \
  'property bool lyricsLoading: false' \
  'property bool lyricsAvailable: false' \
  'signal backRequested\(\)' \
  'signal refreshRequested\(\)' \
  'signal focusRequested\(\)' \
  'signal closeRequested\(\)' \
  'implicitHeight: 46' \
  'id: cover' \
  'text: root\.title' \
  'text: root\.subtitle' \
  'onClicked: root\.backRequested\(\)' \
  'onClicked: root\.refreshRequested\(\)' \
  'onClicked: root\.focusRequested\(\)' \
  'onClicked: root\.closeRequested\(\)' \
  'component MiniButton: RaohaneIconButton'; do
  rg -q "$contract" "$HEADER" || fail "lyrics header lost presentation contract: $contract"
done

# Header stays presentation-only: no config/services, state mutation, MPRIS or
# lyrics fetching is allowed inside the extracted UI component.
if rg -n '^import qs\.modules\.raohane\.(services|config)' "$HEADER"; then
  fail 'lyrics header imported service/config modules'
fi
if rg -n 'Raohane(Media|Lyrics|Scenes|State|Config)|forceRefresh|toggleLyricsFocus|playerctl|Quickshell\.execDetached|\bProcess[[:space:]]*\{' "$HEADER"; then
  fail 'lyrics header bypasses the overlay/service boundary'
fi

# The coordinator should not silently grow the old local header/buttons again.
if rg -n 'id:[[:space:]]*lyricsMiniCover|component MiniButton:[[:space:]]*RaohaneIconButton' "$MEDIA"; then
  fail 'Overlay regained inline lyrics-header presentation'
fi

printf 'media-header-boundary-audit: lyrics header remains presentation-only with parent-owned lyrics actions and state transitions\n'
