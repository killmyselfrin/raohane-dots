#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'primary-surface-boundary-audit: %s\n' "$*" >&2
  exit 1
}

state="modules/raohane/RaohaneState.qml"
[[ -f "$state" ]] || fail "missing $state"

for contract in \
  'function primaryOpen\(name: string\): bool' \
  'function closePrimarySurfaces\(except: string\): void' \
  'function setPrimaryOpen\(name: string, open: bool\): void' \
  'function togglePrimary\(name: string\): void'; do
  rg -q "$contract" "$state" || fail "RaohaneState lost coordinator contract: $contract"
done

primary_pattern='RaohaneState\.(launcherOpen|wallpaperSelectorOpen|overviewOpen|controlCenterOpen|leftSidebarOpen|overlayOpen|screenTranslatorOpen|settingsOpen|sessionOpen|taskManagerOpen|desktopMenuOpen)[[:space:]]*='
mapfile -t qml_files < <(find modules/raohane -type f -name '*.qml' ! -path "$state" -print | sort)

if rg -n "$primary_pattern" "${qml_files[@]}"; then
  fail 'primary surface boolean is written directly outside RaohaneState; use setPrimaryOpen/togglePrimary'
fi

coordinated_surfaces=(
  modules/raohane/RaohaneLauncher.qml
  modules/raohane/RaohaneControlCenter.qml
  modules/raohane/RaohaneSettings.qml
  modules/raohane/RaohaneOverview.qml
  modules/raohane/RaohaneSidebarLeft.qml
  modules/raohane/RaohaneOverlay.qml
  modules/raohane/RaohaneWallpaperSelector.qml
  modules/raohane/RaohaneScreenTranslator.qml
  modules/raohane/RaohaneSessionScreen.qml
  modules/raohane/RaohaneTaskManager.qml
  modules/raohane/RaohaneDesktopMenu.qml
  modules/raohane/RaohaneBar.qml
  modules/raohane/RaohaneVerticalBar.qml
  modules/raohane/RaohaneDock.qml
)
for file in "${coordinated_surfaces[@]}"; do
  [[ -f "$file" ]] || fail "missing coordinated surface: $file"
  rg -q 'RaohaneState\.(setPrimaryOpen|togglePrimary)\(' "$file" \
    || fail "$file does not route primary navigation through RaohaneState coordinator"
done

rg -q 'property bool taskManagerOpen:' "$state" \
  || fail 'RaohaneState does not own native Task Manager visibility'
rg -q 'case "taskManager"' "$state" \
  || fail 'Task Manager is not part of the primary coordinator switch'

rg -q 'RaohaneState\.closePrimarySurfaces\(""\)' modules/raohane/RaohaneRegionSelector.qml \
  || fail 'region capture no longer dismisses primary surfaces before selection'

# Media overlay, OSK and OSD are intentionally independent transient surfaces.
# They may coexist with a primary surface, particularly for fullscreen/game use.
for property in mediaOverlayOpen oskOpen osdOpen; do
  rg -q "property bool ${property}:" "$state" || fail "missing independent transient state: $property"
done

printf 'primary-surface-boundary-audit: primary UI including native Task Manager is mutually exclusive and capture dismisses it before selection\n'
