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
focus="modules/raohane/RaohaneFocusGrab.qml"
region="modules/raohane/RaohaneRegionSelector.qml"
bar="modules/raohane/RaohaneBar.qml"
bar_module="modules/raohane/RaohaneBarModule.qml"
[[ -f "$state" ]] || fail "missing $state"
[[ -f "$registry" ]] || fail "missing $registry"
[[ -f "$focus" ]] || fail "missing $focus"
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

# Normal screenshots preserve the currently visible shell while slurp owns
# compositor focus. OCR, image search and recording still use the destructive
# capture path and dismiss all primary surfaces before their backends start.
rg -q 'property bool dismissSuppressed:[[:space:]]*false' "$focus" \
  || fail 'focus coordinator lost screenshot dismiss suppression state'
rg -q 'function suppressDismiss\(\): void' "$focus" \
  || fail 'focus coordinator cannot suspend dismissal for shell capture'
rg -q 'function resumeDismiss\(\): void' "$focus" \
  || fail 'focus coordinator cannot restore dismissal after shell capture'
rg -q 'active:[[:space:]]*root\.dismissable\.length[[:space:]]*>[[:space:]]*0[[:space:]]*&&[[:space:]]*!root\.dismissSuppressed' "$focus" \
  || fail 'Hyprland focus grab remains active while screenshot dismissal is suppressed'

rg -q 'function prepareCapture\(preserveShell: bool\): void' "$region" \
  || fail 'region capture lost its shell-preservation policy'
rg -q 'if[[:space:]]*\(!preserveShell\)' "$region" \
  || fail 'region capture no longer distinguishes normal screenshots from destructive capture'
rg -q 'RaohaneState\.closePrimarySurfaces\(""\)' "$region" \
  || fail 'destructive capture paths no longer route dismissal through the primary coordinator'
rg -q 'RaohaneFocusGrab\.suppressDismiss\(\)' "$region" \
  || fail 'normal screenshot does not suspend focus-based shell dismissal'
rg -q 'root\.prepareCapture\(true\)' "$region" \
  || fail 'normal screenshot no longer preserves active shell surfaces'
rg -q 'RaohaneFocusGrab\.resumeDismiss\(\)' "$region" \
  || fail 'normal screenshot does not restore focus dismissal after capture'
rg -q 'root\.prepareCapture\(false\)' "$region" \
  || fail 'OCR/search/record capture paths no longer dismiss primary surfaces'
rg -q 'Quickshell\.execDetached\(' "$region" \
  || fail 'normal screenshot no longer uses the known-good detached runtime path'
rg -q 'function finishScreenshot\(\): void' "$region" \
  || fail 'screenshot lifecycle has no local completion handler'
rg -q 'function captureFinished\(\): void' "$region" \
  || fail 'detached screenshot command cannot report completion through IPC'
rg -q 'qs -c raohane ipc call region captureFinished' "$region" \
  || fail 'detached screenshot command lost its completion callback'
rg -q 'id:[[:space:]]*captureFailsafe' "$region" \
  || fail 'screenshot dismiss suppression has no failsafe recovery timer'
if rg -q 'id:[[:space:]]*screenshotProcess' "$region"; then
  fail 'normal screenshot regressed to the tracked Process path that failed at runtime'
fi
region_block="$(sed -n '/"regionSelector"[[:space:]]*:/,/^[[:space:]]*},/p' "$registry")"
printf '%s\n' "$region_block" | rg -q 'closePrimaryOnOpen:[[:space:]]*false' \
  || fail 'region selector registry policy closes shell UI before screenshot can preserve it'

# Media overlay, OSK and OSD are intentionally independent transient surfaces.
# They may coexist with a primary surface, particularly for fullscreen/game use.
for property in mediaOverlayOpen oskOpen osdOpen; do
  rg -q "property bool ${property}:" "$state" || fail "missing independent transient state: $property"
done
for surface in mediaOverlay osk osd; do
  rg -q "\"${surface}\"[[:space:]]*:" "$registry" \
    || fail "transient surface is missing from registry: $surface"
done

printf 'primary-surface-boundary-audit: registry-backed primary UI is mutually exclusive while screenshots preserve active shell UI through the detached capture path\n'
