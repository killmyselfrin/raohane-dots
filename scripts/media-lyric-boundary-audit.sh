#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'media-lyric-boundary-audit: %s\n' "$*" >&2
  exit 1
}

MEDIA='modules/raohane/RaohaneMediaOverlay.qml'
LINE='modules/raohane/RaohaneMediaLyricLine.qml'

for path in "$MEDIA" "$LINE"; do
  [[ -f "$path" ]] || fail "missing lyric boundary path: $path"
done

for contract in \
  'delegate: RaohaneMediaLyricLine' \
  'onSeekRequested: time =>' \
  'RaohaneMedia\.seekRatio\(time / RaohaneMedia\.length\)'; do
  rg -q "$contract" "$MEDIA" || fail "media overlay lost extracted lyric contract: $contract"
done

for contract in \
  'required property var lineData' \
  'property bool current: false' \
  'property bool focusMode: false' \
  'property bool seekEnabled: false' \
  'signal seekRequested\(real time\)' \
  'showStateRail: root\.current && !root\.focusMode' \
  'stateRailColor: root\.accent' \
  'style: root\.focusMode \? Text\.Outline : Text\.Normal' \
  'onClicked: root\.seekRequested'; do
  rg -q "$contract" "$LINE" || fail "lyric line lost presentation contract: $contract"
done

# The extracted line is deliberately presentation-only. Service ownership,
# current-line selection and ratio calculation stay in RaohaneMediaOverlay.
if rg -n '^import qs\.modules\.raohane\.(services|config)' "$LINE"; then
  fail 'lyric line imported service/config modules'
fi
if rg -n 'Raohane(Media|Lyrics|Scenes|State|Config)|seekRatio|playerctl|Quickshell\.execDetached|\bProcess[[:space:]]*\{' "$LINE"; then
  fail 'lyric line bypasses the overlay presentation boundary'
fi

# Glyphs must remain stable. Viewport scrolling belongs to the parent ListView;
# the line component may change semantic state but must not animate typography.
if rg -n 'Behavior on (scale|color|styleColor|opacity)' "$LINE"; then
  fail 'lyric line regained animated glyph/style transitions'
fi
if rg -n '^[[:space:]]*scale:[[:space:]]' "$LINE"; then
  fail 'lyric line regained transform state'
fi

printf 'media-lyric-boundary-audit: extracted lyric lines remain presentation-only with stable typography and parent-owned seeking\n'
