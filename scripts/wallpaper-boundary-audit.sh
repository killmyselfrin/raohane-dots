#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'wallpaper-boundary-audit: %s\n' "$*" >&2
  exit 1
}

selector='modules/raohane/RaohaneWallpaperSelector.qml'
paths='modules/raohane/config/RaohanePaths.qml'
focus='modules/raohane/RaohaneFocusGrab.qml'

for file in "$selector" "$paths" "$focus"; do
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

printf 'wallpaper-boundary-audit: selector focus, icons, paths, config and wallpaper services are Raohane-owned\n'
