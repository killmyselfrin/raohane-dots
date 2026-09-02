#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'primary-surface-boundary-audit: %s\n' "$*" >&2
  exit 1
}

state="modules/raohane/RaohaneState.qml"
registry="modules/raohane/RaohaneSurfaceRegistry.qml"
bar="modules/raohane/RaohaneBar.qml"
bar_module="modules/raohane/RaohaneBarModule.qml"
[[ -f "$state" ]] || fail "missing $state"
[[ -f "$registry" ]] || fail "missing $registry"
[[ -f "$bar" ]] || fail "missing $bar"
[[ -f "$bar_module" ]] || fail "missing $bar_module"

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
  modules/raohane/RaohaneBarModule.qml
  modules/raohane/RaohaneVerticalBar.qml
  modules/raohane/RaohaneDock.qml
)
for file in "${coordinated_surfaces[@]}"; do
  [[ -f "$file" ]] || fail "missing coordinated surface: $file"
  rg -q 'RaohaneState\.(setPrimaryOpen|togglePrimary)\(' "$file" \
    || fail "$file does not route primary navigation through RaohaneState coordinator"
done

rg -q 'RaohaneBarModule[[:space:]]*\{' "$bar" \
  || fail 'horizontal bar no longer delegates primary actions through the coordinated module host'

rg -q 'property bool taskManagerOpen:' "$state" \
  || fail 'RaohaneState does not own native Task Manager visibility'
rg -q '"taskManager"[[:space:]]*:' "$registry" \
  || fail 'Task Manager is not registered as a coordinated surface'
rg -q 'stateProperty:[[:space:]]*"taskManagerOpen"' "$registry" \
  || fail 'Task Manager registry entry lost its RaohaneState binding'
rg -q 'RaohaneSurfaceRegistry\.primarySurfaceIds' "$state" \
  || fail 'primary coordinator no longer derives exclusivity from the surface registry'

rg -q 'RaohaneState\.closePrimarySurfaces\(""\)' modules/raohane/RaohaneRegionSelector.qml \
  || fail 'region capture no longer dismisses primary surfaces before selection'

# Media overlay, OSK and OSD are intentionally independent transient surfaces.
# They may coexist with a primary surface, particularly for fullscreen/game use.
for property in mediaOverlayOpen oskOpen osdOpen; do
  rg -q "property bool ${property}:" "$state" || fail "missing independent transient state: $property"
done
for surface in mediaOverlay osk osd; do
  rg -q "\"${surface}\"[[:space:]]*:" "$registry" \
    || fail "transient surface is missing from registry: $surface"
done

printf 'primary-surface-boundary-audit: registry-backed primary UI including composable bar actions is mutually exclusive and capture dismisses it before selection\n'
