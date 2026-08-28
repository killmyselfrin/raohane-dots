#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'wallpaper-boundary-audit: %s\n' "$*" >&2
  exit 1
}

selector='modules/raohane/RaohaneWallpaperSelector.qml'
service='modules/raohane/services/RaohaneWallpapers.qml'
paths='modules/raohane/config/RaohanePaths.qml'
focus='modules/raohane/RaohaneFocusGrab.qml'
thumb_wrapper='scripts/thumbnails/thumbgen-venv.sh'
thumb_generator='scripts/thumbnails/thumbgen.py'
magick_generator='scripts/thumbnails/generate-thumbnails-magick.sh'
features='install/arch/features.txt'

for file in "$selector" "$service" "$paths" "$focus" "$thumb_wrapper" "$thumb_generator" "$magick_generator" "$features"; do
  [[ -f "$file" ]] || fail "missing required file: $file"
done

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

if rg -n \
  '^import QtCore$|^import qs\.services$|^import qs\.modules\.common|GlobalFocusGrab|MaterialSymbol|StandardPaths|\bDirectories\.|\bConfig\.|\bAppearance\.|GlobalStates\.wallpaperSelector' \
  "$selector"; then
  fail 'wallpaper selector regressed to inherited focus/widgets/paths/config state'
fi

for contract in \
  'scripts/thumbnails/thumbgen-venv\.sh' \
  'scripts/thumbnails/generate-thumbnails-magick\.sh' \
  'RaohaneConfig\.wallpaperDirectory' \
  'thumbnailGenerationProgress'; do
  rg -q "$contract" "$service" || fail "wallpaper service lost thumbnail contract: $contract"
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
python3 -m py_compile "$thumb_generator"

printf 'wallpaper-boundary-audit: selector and standalone Pillow/ffmpeg/ImageMagick thumbnail pipeline are Raohane-owned\n'
