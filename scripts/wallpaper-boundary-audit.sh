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
# Deployed Quickshell QML rejects typed default arguments. Any reintroduction
# makes the loader fail, even while the rest of the shell is running.
if rg -n 'function[[:space:]]+[A-Za-z0-9_]+\\([^)]*:[[:space:]]*[A-Za-z0-9_]+[[:space:]]*=' \
  "$cinema" "$selector"; then
  fail 'wallpaper QML contains a typed default function parameter'
fi
rg -Fq 'function highlightPath(path: string, previewImmediately): void' "$cinema" \
  || fail 'cinematic preview arguments changed unexpectedly'
rg -Fq 'source: Qt.resolvedUrl("RaohaneWallpaperCinema.qml")' "$selector" \
  || fail 'cinematic Loader.source must be independent from Loader.active'
rg -Fq 'Qt.callLater(() => {' "$selector" \
  || fail 'cinematic Loader.error recovery must defer state changes'

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

# Browsing must update the active selection immediately while deferring
# expensive live preview and preview background decodes until the motion settles.
for contract in \
  'signal entryHighlighted(string path)' \
  'signal previewRequested(string path)' \
  'readonly property int previewDelay:' \
  'function commitPreview(): void' \
  'function finishPreview(): void' \
  'id: previewTimer' \
  'previewTimer.restart()' \
  'id: incomingPreview' \
  'id: previewFade' \
  'asynchronous: true' \
  'onFinished: root.finishPreview()' \
  'Layout.preferredWidth: Math.min(root.width - 28, 480)'; do
  rg -Fq "$contract" "$cinema" || fail "cinematic preview/crossfade lost $contract"
done
rg -Fq 'function onEntryHighlighted(path: string): void' "$selector" \
  || fail 'carousel focus no longer updates pending selection without applying'
rg -Fq 'function onPreviewRequested(path: string): void' "$selector" \
  || fail 'carousel settled preview no longer reaches wallpaper background'
rg -Fq 'root.pendingPath === path' "$selector" \
  || fail 'stale preview can override more recent carousel selection'
rg -Fq 'root.applyPending()' "$selector" \
  || fail 'wallpaper Apply action was lost in cinematic refactor'
rg -Fq 'root.previewRequested(root.incomingPreviewPath)' "$cinema" \
  || fail 'live preview triggers before bounded image decoding finishes'
rg -Fq 'root.pendingPath === path' "$selector" \
  || fail 'stale carousel preview is no longer rejected'
rg -Fq 'cinemaLoader.item.focusCurrent()' "$selector" \
  || fail 'lazy carousel can lose its initial selection event'
rg -Fq 'function onFolderChanged(): void' "$cinema" \
  || fail 'carousel does not reset pending transitions across folders'

rg -Fq 'root.entryChosen(tile.filePath, false)' "$cinema" \
  || fail 'cinematic double-click can no longer apply a selected file'
if rg -Fq 'RaohaneWallpapers.apply(' "$cinema"; then
  fail 'cinematic browsing bypassed the existing wallpaper confirmation flow'
fi

# Regression from live screenshot: FolderListModel can show N entries while
# the cinematic ListView creates no delegates. Use the named Qt roles directly,
# pass the model/geometry to the dynamically loaded viewport, and fall back to
# Grid if delegates never materialize.
for role in 'required property string filePath' \
            'required property string fileName' \
            'required property bool fileIsDir' \
            'required property int index'; do
  rg -Fq "$role" "$cinema" || fail "carousel lost named FolderListModel role $role"
done
if rg -Fq 'required property var modelData' "$cinema"; then
  fail 'carousel reintroduced fragile modelData binding'
fi
rg -Fq 'item.folderModel = RaohaneWallpapers.folderModel' "$selector" \
  || fail 'lazy carousel does not receive the real file model on load'
rg -Fq 'property: "width"' "$selector" \
  || fail 'lazy carousel loses visible viewport width'
rg -Fq 'property: "height"' "$selector" \
  || fail 'lazy carousel loses visible viewport height'
rg -Fq 'id: cinemaHealthCheck' "$selector" \
  || fail 'blank carousel no longer falls back to Grid'
rg -Fq 'gallery.hasCurrentCard' "$selector" \
  || fail 'cinema delegate watchdog is missing'
rg -Fq 'function thumbnailUrl(path: string): string' "$cinema" \
  || fail 'video entries have no poster thumbnail resolver'
rg -Fq 'RaohaneWallpapers.generateThumbnail("x-large")' "$cinema" \
  || fail 'video posters cannot be generated from existing thumbnail pipeline'
rg -Fq 'Qt.md5("file://" + encodedPath)' "$cinema" \
  || fail 'Freedesktop thumbnail URI lookup no longer matches generator'
rg -Fq 'id: videoPoster' "$cinema" \
  || fail 'video card is back to a blank placeholder'
rg -Fq 'tile.video && root.thumbnailsReady' "$cinema" \
  || fail 'video poster is loaded before the thumbnail job has finished'

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
