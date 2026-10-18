#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'wallpaper-boundary-audit: %s\n' "$*" >&2
  exit 1
}

selector='modules/raohane/RaohaneWallpaperSelector.qml'
cinema='modules/raohane/RaohaneWallpaperCinema.qml'
qmldir='modules/raohane/qmldir'
background='modules/raohane/RaohaneBackground.qml'
service='modules/raohane/services/RaohaneWallpapers.qml'
paths='modules/raohane/config/RaohanePaths.qml'
focus='modules/raohane/RaohaneFocusGrab.qml'
thumb_wrapper='scripts/thumbnails/thumbgen.sh'
retired_wrapper='scripts/thumbnails/thumbgen-venv.sh'
thumb_generator='scripts/thumbnails/thumbgen.py'
magick_generator='scripts/thumbnails/generate-thumbnails-magick.sh'
features='install/arch/features.txt'

for file in "$selector" "$cinema" "$qmldir" "$background" "$service" "$paths" "$focus" "$thumb_wrapper" "$thumb_generator" "$magick_generator" "$features"; do
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

# Grid mode keeps the full keyboard/folder/thumbnail browser. Cinematic
# mode loads only when selected, and uses the same FolderListModel/backend.
for symbol in \
  'GridView[[:space:]]*\{' \
  'cellWidth:[[:space:]]*width[[:space:]]*/' \
  'ScrollBar\.vertical' \
  'readonly property bool selected:' \
  'gallery\.currentIndex[[:space:]]*=[[:space:]]*cell\.index' \
  'RaohaneWallpapers\.startPreview\(cell\.filePath\)' \
  'RaohaneWallpapers\.stopPreview\(\)' \
  'root\.selectPath\(cell\.filePath,[[:space:]]*cell\.isDirectory\)'; do
  rg -q "$symbol" "$selector" || fail "wallpaper gallery lost interaction contract: $symbol"
done

rg -Fq 'RaohaneWallpaperCinema 1.0 RaohaneWallpaperCinema.qml' "$qmldir" \
  || fail 'cinematic wallpaper picker is not a registered native QML type'
rg -Fq 'Qt.resolvedUrl("RaohaneWallpaperCinema.qml")' "$selector" \
  || fail 'cinematic wallpaper must be loaded by URL for safe fallback'
rg -Fq 'if (status === Loader.Error && selector.cinematicMode)' "$selector" \
  || fail 'failed cinematic view must fall back to working grid mode'
rg -Fq 'model: selector.cinematicMode ? null : RaohaneWallpapers.folderModel' "$selector" \
  || fail 'hidden grid continues decoding images alongside cinematic carousel'
rg -Fq 'signal entryChosen(string path, bool directory)' "$cinema" \
  || fail 'cinematic carousel cannot select the existing wallpaper backend'
rg -Fq 'signal applyRequested()' "$cinema" \
  || fail 'cinematic carousel cannot apply a wallpaper'
rg -Fq 'ListView {' "$cinema" \
  || fail 'cinematic carousel lost its virtualized card view'
rg -Fq 'sourceSize.width: 660' "$cinema" \
  || fail 'cinematic carousel thumbnails may decode full-resolution images'
if rg -Fq 'required property var folderModel' "$cinema"; then
  fail 'dynamically loaded cinema has an unsatisfied required property'
fi
rg -Fq 'if (tile && tile.filePath.length > 0 && !tile.isDirectory)' "$cinema" \
  || fail 'cinematic scrolling may accidentally open folders'

# The Wallpaper Picker alone uses translucent material colors. Applying
# opacity to the entire PanelWindow/selector would fade text and image cards;
# the scrim and glass backing must be separate from the contents.
rg -Fq 'Qt.rgba(0.01, 0.015, 0.035, 0.24)' "$selector" \
  || fail 'wallpaper picker fullscreen scrim became too opaque'
rg -Fq 'idleColor: Qt.rgba(RaohaneTheme.background.r,' "$selector" \
  || fail 'wallpaper picker lost its translucent glass backing'
rg -Fq 'RaohaneTheme.dark ? 0.53 : 0.76' "$selector" \
  || fail 'wallpaper picker lost theme-aware glass density'
rg -Fq 'RaohaneTheme.dark ? 0.34 : 0.64' "$selector" \
  || fail 'grid sidebar became opaque again'
rg -Fq 'color: Qt.rgba(RaohaneTheme.background.r, RaohaneTheme.background.g,' "$cinema" \
  || fail 'cinematic backdrop no longer lets the desktop show through'
rg -Fq 'GradientStop { position: 0.52; color: RaohaneTheme.dark ? "#26080b13" : "#38f6f4f9" }' "$cinema" \
  || fail 'cinematic backdrop gradient became opaque'
rg -Fq 'sourceSize.width: 660' "$cinema" \
  || fail 'cinematic preview lost bounded decode'
if rg -Fq 'opacity: entered ? 0.' "$selector"; then
  fail 'selector is fading all content instead of its glass backing'
fi

# Hidden QQuickImage items still evaluate and decode their source. Gallery image
# sources therefore must be empty for directories and video files instead of
# relying on visible:false, which produces noisy decode/open warnings at runtime.
rg -U -q 'source:[[:space:]]*!cell\.isDirectory[[:space:]]*&&[[:space:]]*!cell\.video[[:space:]]*&&[[:space:]]*cell\.filePath\.length[[:space:]]*>[[:space:]]*0[[:space:]]*\n[[:space:]]*\?[[:space:]]*"file://"[[:space:]]*\+[[:space:]]*cell\.filePath[[:space:]]*\n[[:space:]]*:[[:space:]]*""' "$selector" \
  || fail 'wallpaper gallery image source is not guarded against directories/video files'

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

printf 'wallpaper-boundary-audit: responsive selector gallery, guarded image sources, fullscreen-aware video background and standalone thumbnails are Raohane-owned\n'
