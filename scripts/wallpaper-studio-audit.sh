#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() { printf 'wallpaper-studio-audit: %s\n' "$*" >&2; exit 1; }
config=modules/raohane/config/RaohaneConfig.qml
wallpapers=modules/raohane/services/RaohaneWallpapers.qml
selector=modules/raohane/RaohaneWallpaperSelector.qml
background=modules/raohane/RaohaneBackground.qml
theme=modules/raohane/RaohaneTheme.qml
palette=scripts/wallpaper-palette.py
defaults=defaults/native.json
for path in "$config" "$wallpapers" "$selector" "$background" "$theme" "$palette" "$defaults"; do
  [[ -f "$path" ]] || fail "missing $path"
done

for key in wallpaperFavorites wallpaperCollections wallpaperMonitors wallpaperAutoSource wallpaperAdaptiveAccent wallpaperAdaptiveColor; do
  rg -q "property (var|string|bool) $key:" "$config" || fail "missing native property $key"
done
for fn in sanitizeWallpaperPaths sanitizeWallpaperCollections sanitizeWallpaperMonitors wallpaperPathForScreen setWallpaperForScreen; do
  rg -Fq "function $fn(" "$config" || fail "missing sanitizer/API $fn"
done
for name in favorites collections monitors autoSource adaptiveAccent adaptiveColor; do
  rg -Fq "$name: " "$config" || fail "wallpaper preferences not serialized: $name"
  rg -Fq "assignIfPresent(wallpaper, \"$name\"" "$config" || fail "wallpaper preferences not restored: $name"
done

for contract in \
  'function isFavorite(path: string): bool' \
  'function toggleFavorite(path: string): void' \
  'function saveCurrentCollection(): void' \
  'function removeCollection(path): void' \
  'function autoAdvance(): void' \
  'function generatedVideoPosterUrl(path: string): string' \
  'function queueAdaptiveAccent(): void' \
  'id: accentProcess' \
  'id: accentDebounce' \
  'id: fileProbe' \
  'fileProbe.exec(["test", "-f", selectProbe.filePath])'; do
  rg -Fq "$contract" "$wallpapers" || fail "missing wallpaper service contract: $contract"
done

for contract in \
  'property bool studioExpanded: false' \
  'RaohaneWallpapers.toggleFavorite(root.pendingPath)' \
  'RaohaneWallpapers.saveCurrentCollection()' \
  'RaohaneWallpapers.removeCollection(modelData.path)' \
  'RaohaneConfig.wallpaperAdaptiveAccent =' \
  'root.targetScreenName = index > 0' \
  'RaohaneConfig.wallpaperChangeInterval = intervals[index]' \
  'RaohaneConfig.wallpaperAutoSource =' \
  'RaohaneWallpapers.videoPreviewPaused =' \
  'RaohaneWallpapers.apply(finalPath, true, root.targetScreenName)'; do
  rg -Fq "$contract" "$selector" || fail "wallpaper Studio UI lost action: $contract"
done
rg -Fq 'RaohaneConfig.wallpaperPathForScreen(String(modelData.name))' "$background" \
  || fail 'monitor-specific backgrounds do not use saved override'
rg -Fq 'RaohaneWallpapers.previewScreenName === String(modelData.name)' "$background" \
  || fail 'preview leaks onto other monitors'
rg -Fq 'RaohaneWallpapers.autoAdvance()' "$background" \
  || fail 'background lost native scheduler source selection'
rg -Fq 'onVideoPreviewPausedChanged' "$background" \
  || fail 'wallpaper video preview cannot be paused'

# QtMultimedia.MediaPlayer is not an Item and cannot contain QML objects.
# The pause notification must be a sibling of MediaPlayer inside Item.
python3 - "$background" <<'PY'
from pathlib import Path
import re
import sys

source = Path(sys.argv[1]).read_text(encoding="utf-8")
for player in re.finditer(r'\bMediaPlayer\s*\{', source):
    cursor = player.end()
    depth = 1
    while cursor < len(source) and depth:
        if source[cursor] == "{":
            depth += 1
        elif source[cursor] == "}":
            depth -= 1
        cursor += 1
    if depth or re.search(r'\bConnections\s*\{', source[player.end():cursor-1]):
        raise SystemExit("MediaPlayer illegally contains a Connections child or unclosed block")
PY
rg -Fq 'RaohaneConfig.wallpaperAdaptiveAccent' "$theme" \
  || fail 'adaptive accent is not wired to native theme'
for token in background backgroundElevated surface surfaceRaised surfaceDeep surfaceSubtle surfaceHover surfacePressed border borderStrong borderFaint; do
  rg -Fq "readonly property color $token: root.tintedMaterial(" "$theme" \
    || fail "adaptive wallpaper palette does not reach shared $token material"
done
rg -Fq 'readonly property bool adaptivePaletteActive: RaohaneConfig.wallpaperAdaptiveAccent' "$theme" \
  || fail 'adaptive material tint cannot be disabled independently'
rg -Fq 'root.accentProbePath = root.cleanPath(RaohaneConfig.wallpaperPath)' "$wallpapers" \
  || fail 'applied video cannot be sampled without a pre-existing gallery poster'
rg -Fq 'accentProcess.sourcePath === root.cleanPath(RaohaneConfig.wallpaperPath)' "$wallpapers" \
  || fail 'stale palette subprocess may recolor newer wallpaper'
rg -Fq 'VIDEO_SUFFIXES' "$palette" \
  || fail 'wallpaper palette extractor lost video wallpaper support'
if rg -Fq 'Process {' "$theme"; then
  fail 'adaptive theme creates a rendering subprocess'
fi
rg -Fq 'readonly property string paletteScriptPath: Quickshell.shellPath("scripts/wallpaper-palette.py")' "$wallpapers" \
  || fail 'palette helper is not invoked through the native wallpaper service'

python3 - "$palette" "$defaults" <<'PY'
import ast
import json
import pathlib
import sys

script = pathlib.Path(sys.argv[1])
ast.parse(script.read_text(encoding="utf-8"), filename=str(script))
data = json.loads(pathlib.Path(sys.argv[2]).read_text(encoding="utf-8"))
wallpaper = data["wallpaper"]
expected = dict(favorites=[], collections=[], monitors={}, autoSource="folder",
                adaptiveAccent=False, adaptiveColor="#94b5e5")
for key, expected_value in expected.items():
    assert wallpaper.get(key) == expected_value, f"unsafe default: {key}"
assert wallpaper["changeInterval"] == 0, "automatic changes must remain opt-in"
PY

# Real one-shot palette fixture when Pillow is available.
if python3 -c 'from PIL import Image' >/dev/null 2>&1; then
  temp_dir="$(mktemp -d)"
  trap 'rm -rf "$temp_dir"' EXIT
  python3 - "$temp_dir" <<'PY'
from PIL import Image
from pathlib import Path
import sys
Image.new("RGB", (32, 32), (50, 115, 220)).save(Path(sys.argv[1]) / "accent.png")
PY
  color="$(python3 "$palette" "$temp_dir/accent.png")" || fail 'palette extractor failed for fixture'
  [[ "$color" =~ ^#[[:xdigit:]]{6}$ ]] || fail "invalid adaptive accent: $color"

  if command -v ffmpeg >/dev/null 2>&1; then
    ffmpeg -hide_banner -loglevel error -nostdin -y \
      -f lavfi -i 'color=c=#bd4a32:size=96x54:rate=1:duration=7' \
      -c:v mpeg4 -q:v 6 "$temp_dir/warm.mp4" \
      || fail 'cannot produce sample video wallpaper'
    video_color="$(python3 "$palette" "$temp_dir/warm.mp4")" \
      || fail 'adaptive palette cannot sample a video directly'
    [[ "$video_color" =~ ^#[[:xdigit:]]{6}$ ]] \
      || fail "invalid video wallpaper accent: $video_color"
    python3 - "$video_color" <<'PY'
import sys
value = sys.argv[1]
red = int(value[1:3], 16)
blue = int(value[5:7], 16)
if red <= blue:
    raise SystemExit(f"video accent is not derived from the warm red frame: {value}")
PY
  fi
fi

printf 'wallpaper-studio-audit: native library, scoped monitors, opt-in scheduler, palette and video preview contracts verified\n'
