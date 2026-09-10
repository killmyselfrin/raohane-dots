#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'media-header-boundary-audit: %s\n' "$*" >&2
  exit 1
}

MEDIA='modules/raohane/RaohaneMediaOverlay.qml'
STAGE='modules/raohane/RaohaneMediaLyricsStage.qml'
HEADER='modules/raohane/RaohaneMediaLyricsHeader.qml'

for path in "$MEDIA" "$STAGE" "$HEADER"; do
  [[ -f "$path" ]] || fail "missing media header boundary path: $path"
done

# Overlay owns service/state transitions and sends display-ready header values
# through the presentation-only Stage.
for contract in \
  'RaohaneMediaLyricsStage[[:space:]]*\{' \
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

# Stage forwards only presentation values and raw user intents to/from Header.
for contract in \
  'RaohaneMediaLyricsHeader[[:space:]]*\{' \
  'artUrl: root\.artUrl' \
  'accent: root\.accent' \
  'title: root\.title' \
  'subtitle: root\.subtitle' \
  'mediaAvailable: root\.mediaAvailable' \
  'lyricsLoading: root\.lyricsLoading' \
  'lyricsAvailable: root\.lyricsAvailable' \
  'onBackRequested: root\.backRequested\(\)' \
  'onRefreshRequested: root\.refreshRequested\(\)' \
  'onFocusRequested: root\.focusRequested\(\)' \
  'onCloseRequested: root\.closeRequested\(\)'; do
  rg -q "$contract" "$STAGE" || fail "lyrics stage lost header wiring contract: $contract"
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

# Header and Stage stay presentation-only: no config/services, state mutation,
# MPRIS or lyrics fetching may be owned below the Overlay coordinator.
for file in "$STAGE" "$HEADER"; do
  if rg -n '^import qs\.modules\.raohane\.(services|config)' "$file"; then
    fail "$file imported service/config modules"
  fi
  if rg -n 'Raohane(Media|Lyrics|Scenes|State|Config)\.|forceRefresh|toggleLyricsFocus|playerctl|Quickshell\.execDetached|\bProcess[[:space:]]*\{' "$file"; then
    fail "$file bypasses the overlay/service boundary"
  fi
done

# Overlay should never rebuild the old inline header/buttons hierarchy.
if rg -n 'RaohaneMediaLyricsHeader[[:space:]]*\{|id:[[:space:]]*lyricsMiniCover|component MiniButton:[[:space:]]*RaohaneIconButton' "$MEDIA"; then
  fail 'Overlay regained inline lyrics-header presentation'
fi

printf 'media-header-boundary-audit: lyrics header remains presentation-only behind Stage with coordinator-owned lyrics actions and state transitions\n'
