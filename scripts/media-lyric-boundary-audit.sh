#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'media-lyric-boundary-audit: %s\n' "$*" >&2
  exit 1
}

MEDIA='modules/raohane/RaohaneMediaOverlay.qml'
STAGE='modules/raohane/RaohaneMediaLyricsStage.qml'
VIEWPORT='modules/raohane/RaohaneMediaLyricsViewport.qml'
LINE='modules/raohane/RaohaneMediaLyricLine.qml'
EFFECT='modules/raohane/RaohaneMediaLyricEffect.qml'
WINGS='modules/raohane/RaohaneMediaLyricWings.qml'
VOCABULARY='modules/raohane/RaohaneLyricEffects.js'

for path in "$MEDIA" "$STAGE" "$VIEWPORT" "$LINE"; do
  [[ -f "$path" ]] || fail "missing lyric boundary path: $path"
done

[[ -f "$EFFECT" && -f "$VOCABULARY" && -f "$WINGS" ]] \
  || fail 'missing native word-effect component, wings or vocabulary'
rg -q 'RaohaneMediaLyricEffect[[:space:]]*\{' "$LINE" \
  || fail 'lyric line lost bounded word-effect composition'
rg -q 'active: root\.current && root\.lyricEffectActive && root\.lyricEffectMode !== "off"' "$LINE" \
  || fail 'lyric line instantiates expensive effect probes outside the active row'
rg -q 'LyricEffects\.detect' "$EFFECT" \
  || fail 'lyric effect lost semantic vocabulary matching'
rg -q 'RaohaneMediaLyricWings[[:space:]]*\{' "$EFFECT" \
  || fail 'wing semantics lost native feather geometry'
rg -q 'ctx\.bezierCurveTo' "$WINGS" \
  || fail 'wing motif regressed to a typographic placeholder'
if rg -n 'const expression.*\\p\{' "$VOCABULARY"; then
  fail 'Qt QML JS cannot tokenize with Unicode property escape regexes'
fi
rg -q 'positionToRectangle' "$EFFECT" \
  || fail 'lyric effect lost wrap-aware word positioning'
rg -q 'RaohaneConfig\.lyricEffectMode' "$MEDIA" \
  || fail 'media overlay lost persisted lyric mode'
rg -q '!root\.gamingScene' "$MEDIA" \
  || fail 'lyric effects are not disabled in Gaming Scene'
rg -q 'RaohaneMedia\.isPlaying' "$MEDIA" \
  || fail 'lyric effects are not disabled on pause'
rg -q 'onLyricEffectModeChanged: scheduleSave\(\)' modules/raohane/config/RaohaneConfig.qml \
  || fail 'lyric effect choice is not persisted'
for file in "$EFFECT" "$VOCABULARY" "$WINGS"; do
  if rg -n '(^import qs\.modules\.raohane\.(services|config)|Quickshell\.execDetached|\bProcess[[:space:]]*\{)' "$file"; then
    fail "$file crossed the native lyric presentation boundary"
  fi
done
if command -v node >/dev/null 2>&1; then
  node scripts/lyric-effects-test.cjs
else
  python3 - "$VOCABULARY" <<'PY'
import re
import sys

text = open(sys.argv[1], encoding="utf-8").read()
records = re.findall(r'^\s*\["[a-z]+", "[a-z]+", ', text, re.M)
if len(records) != 40:
    raise SystemExit(f"expected 40 lyric vocabulary families, got {len(records)}")
PY
fi

for contract in \
  'RaohaneMediaLyricsStage[[:space:]]*\{' \
  'onSeekRequested: time =>' \
  'RaohaneMedia\.seekRatio\(time / RaohaneMedia\.length\)'; do
  rg -q "$contract" "$MEDIA" || fail "media overlay lost Stage/seek contract: $contract"
done

for contract in \
  'RaohaneMediaLyricsViewport[[:space:]]*\{' \
  'onSeekRequested: time => root\.seekRequested\(time\)'; do
  rg -q "$contract" "$STAGE" || fail "lyrics stage lost viewport seek-routing contract: $contract"
done

for contract in \
  'delegate: RaohaneMediaLyricLine' \
  'onSeekRequested: time => root\.seekRequested\(time\)' \
  'current: root\.syncedAvailable && index === root\.syncedIndex'; do
  rg -q "$contract" "$VIEWPORT" || fail "synced viewport lost lyric-line composition contract: $contract"
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

# Stage, viewport and line remain presentation-only. The final seek-ratio
# calculation stays in RaohaneMediaOverlay.
for file in "$STAGE" "$VIEWPORT" "$LINE"; do
  if rg -n '^import qs\.modules\.raohane\.(services|config)' "$file"; then
    fail "$file imported service/config modules"
  fi
  if rg -n 'Raohane(Media|Lyrics|Scenes|State|Config)\.|seekRatio|playerctl|Quickshell\.execDetached|\bProcess[[:space:]]*\{' "$file"; then
    fail "$file bypasses the presentation/service boundary"
  fi
done

# Glyphs must remain stable. The viewport may animate scrolling, but the line
# component must not animate typography or transform individual lyric rows.
if rg -n 'Behavior on (scale|color|styleColor|opacity)' "$LINE"; then
  fail 'lyric line regained animated glyph/style transitions'
fi
if rg -n '^[[:space:]]*scale:[[:space:]]' "$LINE"; then
  fail 'lyric line regained transform state'
fi

if rg -n 'RaohaneMediaLyrics(Viewport|Header|Status)[[:space:]]*\{' "$MEDIA"; then
  fail 'Overlay regained direct lyrics leaf composition'
fi

printf 'media-lyric-boundary-audit: stable lyric glyphs, bounded semantic effects and overlay-owned seek ratio are valid\n'
