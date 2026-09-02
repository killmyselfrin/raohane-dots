#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'wallpaper-boundary-audit: %s\n' "$*" >&2
  exit 1
}

selector='modules/raohane/RaohaneWallpaperSelector.qml'
background='modules/raohane/RaohaneBackground.qml'
service='modules/raohane/services/RaohaneWallpapers.qml'
paths='modules/raohane/config/RaohanePaths.qml'
focus='modules/raohane/RaohaneFocusGrab.qml'
thumb_wrapper='scripts/thumbnails/thumbgen.sh'
retired_wrapper='scripts/thumbnails/thumbgen-venv.sh'
thumb_generator='scripts/thumbnails/thumbgen.py'
magick_generator='scripts/thumbnails/generate-thumbnails-magick.sh'
features='install/arch/features.txt'

for file in "$selector" "$background" "$service" "$paths" "$focus" "$thumb_wrapper" "$thumb_generator" "$magick_generator" "$features"; do
  [[ -f "$file" ]] || fail "missing required file: $file"
done
[[ ! -e "$retired_wrapper" ]] || fail 'retired thumbnail venv wrapper returned'

for symbol in \
  'RaohaneWallpapers\.' \
  'RaohaneConfig\.' \
  'RaohaneState\.' \
  'RaohanePaths\.home' \
  'RaohanePaths\.pictures' \
  'RaohaneFocusGrab\.' \
  'RaohaneIcon[[:space:]]*\{'; do
  rg -q "$symbol" "$selector" || fail "selector lost native dependency: $symbol"
done

for symbol in \
  'orientation:[[:space:]]*ListView\.Horizontal' \
  'snapMode:[[:space:]]*ListView\.SnapToItem' \
  'WheelHandler[[:space:]]*\{' \
  'positionViewAtIndex\(carousel\.currentIndex,[[:space:]]*ListView\.Center\)' \
  'ScrollBar\.horizontal'; do
  rg -q "$symbol" "$selector" || fail "wallpaper carousel lost interaction contract: $symbol"
done

if rg -n \
  '^import QtCore$|^import qs\.services$|^import qs\.modules\.common|GlobalFocusGrab|MaterialSymbol|StandardPaths|\bDirectories\.|\bConfig\.|\bAppearance\.|GlobalStates\.wallpaperSelector' \
  "$selector"; then
  fail 'wallpaper selector regressed to inherited focus/widgets/paths/config state'
fi

for contract in \
  'scripts/thumbnails/thumbgen\.sh' \
  'scripts/thumbnails/generate-thumbnails-magick\.sh' \
  'RaohaneConfig\.wallpaperDirectory' \
  'thumbnailGenerationProgress'; do
  rg -q "$contract" "$service" || fail "wallpaper service lost thumbnail contract: $contract"
done
rg -q 'bash \\"\$\{root\.thumbgenScriptPath\}\\"' "$service" \
  || fail 'wallpaper service does not invoke thumbnail wrapper through bash'
if rg -n 'thumbgen-venv\.sh|ILLOGICAL_IMPULSE' "$service"; then
  fail 'wallpaper service references retired thumbnail/upstream state'
fi

# Video wallpapers must stop decoding while fullscreen hiding is enabled. Merely
# fading the background to zero keeps MediaPlayer active and wastes GPU/CPU time.
for contract in \
  'property bool hiddenForFullscreen|readonly property bool hiddenForFullscreen' \
  'RaohaneConfig\.wallpaperHideWhenFullscreen' \
  'backgroundWindow\.currentIsVideo' \
  '!backgroundWindow\.hiddenForFullscreen' \
  'MediaPlayer[[:space:]]*\{'; do
  rg -q "$contract" "$background" || fail "background lost fullscreen/video contract: $contract"
done

rg -q 'exec python3 "\$SCRIPT_DIR/thumbgen\.py" "\$@"' "$thumb_wrapper" \
  || fail 'thumbnail wrapper does not execute the Raohane Python generator directly'
if rg -n 'ILLOGICAL_IMPULSE|activate|deactivate|virtualenv|venv/bin' "$thumb_wrapper" "$thumb_generator"; then
  fail 'thumbnail pipeline still depends on inherited virtualenv state'
fi

for contract in \
  'from PIL import Image, PngImagePlugin' \
  'shutil\.which\("ffmpeg"\)' \
  'Thumb::URI' \
  'Thumb::MTime' \
  'VIDEO_SUFFIXES' \
  '"\.svg"'; do
  rg -q "$contract" "$thumb_generator" || fail "thumbnail generator lost contract: $contract"
done

for package in python-pillow ffmpeg imagemagick; do
  rg -q "^${package}$" "$features" || fail "wallpaper thumbnail package manifest lost ${package}"
done

bash -n "$thumb_wrapper"
bash -n "$magick_generator"
python3 - "$thumb_generator" <<'PY'
import ast
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
PY

printf 'wallpaper-boundary-audit: selector, fullscreen-aware video background and standalone thumbnails are Raohane-owned\n'
