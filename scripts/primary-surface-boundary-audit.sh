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
region="modules/raohane/RaohaneRegionSelector.qml"
bar="modules/raohane/RaohaneBar.qml"
bar_module="modules/raohane/RaohaneBarModule.qml"
[[ -f "$state" ]] || fail "missing $state"
[[ -f "$registry" ]] || fail "missing $registry"
[[ -f "$region" ]] || fail "missing $region"
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

# Screenshot capture is intentionally able to preserve an already-open Control
# Center so the shell itself can be captured for UI validation. OCR, image
# search and recording still use the destructive capture path and dismiss all
# primary surfaces before their backend starts.
rg -q 'function prepareCapture\(preserveControlCenter: bool\): void' "$region" \
  || fail 'region capture lost its explicit preservation policy'
rg -q 'preserveControlCenter[[:space:]]*&&[[:space:]]*RaohaneState\.controlCenterOpen' "$region" \
  || fail 'region screenshot no longer detects an open Control Center'
rg -q 'RaohaneState\.closePrimarySurfaces\(keep\)' "$region" \
  || fail 'region capture no longer routes dismissal through the primary coordinator'
rg -q 'root\.prepareCapture\(true\)' "$region" \
  || fail 'screenshot path no longer preserves Control Center'
rg -q 'root\.prepareCapture\(false\)' "$region" \
  || fail 'destructive capture paths no longer dismiss primary surfaces'
region_block="$(sed -n '/"regionSelector"[[:space:]]*:/,/^[[:space:]]*},/p' "$registry")"
printf '%s\n' "$region_block" | rg -q 'closePrimaryOnOpen:[[:space:]]*false' \
  || fail 'region selector registry policy closes Control Center before screenshot can preserve it'

# Media overlay, OSK and OSD are intentionally independent transient surfaces.
# They may coexist with a primary surface, particularly for fullscreen/game use.
for property in mediaOverlayOpen oskOpen osdOpen; do
  rg -q "property bool ${property}:" "$state" || fail "missing independent transient state: $property"
done
for surface in mediaOverlay osk osd; do
  rg -q "\"${surface}\"[[:space:]]*:" "$registry" \
    || fail "transient surface is missing from registry: $surface"
done

printf 'primary-surface-boundary-audit: registry-backed primary UI is mutually exclusive while screenshots may preserve Control Center for UI capture\n'
