#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'phase4-visible-runtime-audit: %s\n' "$*" >&2
  exit 1
}

family='panelFamilies/RaohaneFamily.qml'
qmldir='modules/raohane/qmldir'
config='modules/raohane/config/RaohaneConfig.qml'
settings='modules/raohane/RaohaneSettings.qml'
settings_content='modules/raohane/RaohaneSettingsContentV3.qml'
settings_registry='modules/raohane/RaohaneSettingsPageRegistry.qml'
settings_search='modules/raohane/RaohaneSettingsSearch.qml'
runtime_probe='modules/raohane/RaohaneRuntimeProbe.qml'
live_check='scripts/phase4-live-check.sh'
cli='scripts/raohane'

phase4_surfaces=(
  modules/raohane/RaohaneBackground.qml
  modules/raohane/RaohaneDesktopCanvas.qml
  modules/raohane/RaohaneOverview.qml
  modules/raohane/RaohaneDock.qml
  modules/raohane/RaohaneMediaOverlay.qml
  modules/raohane/RaohaneLock.qml
  modules/raohane/RaohaneLockContext.qml
  modules/raohane/RaohaneLockSurface.qml
  modules/raohane/RaohaneBar.qml
  modules/raohane/RaohaneVerticalBar.qml
  modules/raohane/RaohaneOverlay.qml
  modules/raohane/RaohaneSidebarLeft.qml
  modules/raohane/RaohaneRegionSelector.qml
  modules/raohane/RaohaneScreenTranslator.qml
  modules/raohane/RaohaneScreenFrame.qml
  modules/raohane/RaohaneScreenCorners.qml
  modules/raohane/RaohaneDropShelfPanel.qml
  modules/raohane/RaohaneOnScreenKeyboard.qml
  "$settings"
  "$settings_content"
  "$settings_registry"
  "$settings_search"
  "$runtime_probe"
)

for path in "$family" "$qmldir" "$config" "$live_check" "$cli" "${phase4_surfaces[@]}"; do
  [[ -f "$path" ]] || fail "missing Phase 4 path: $path"
done

for retired in modules/ii modules/common services GlobalStates.qml; do
  [[ ! -e "$retired" ]] || fail "retired runtime source returned: $retired"
done

if rg -n '^import qs\.modules\.ii|^import qs\.modules\.common|^import qs\.services$|\bGlobalStates\.|\bRaohaneLegacyBridge\b' \
  "${phase4_surfaces[@]}" "$family"; then
  fail 'Phase 4 surface graph resolves inherited runtime code'
fi

for type in \
  RaohaneBackground RaohaneDesktopCanvas RaohaneOverview RaohaneDock \
  RaohaneMediaOverlay RaohaneLock RaohaneVerticalBar RaohaneOverlay \
  RaohaneSidebarLeft RaohaneRegionSelector RaohaneScreenTranslator \
  RaohaneScreenFrame RaohaneScreenCorners RaohaneDropShelfPanel \
  RaohaneOnScreenKeyboard RaohaneSettings RaohaneRuntimeProbe; do
  rg -q "^${type} .*${type}\.qml$" "$qmldir" \
    || fail "Phase 4 type is not registered: $type"
  rg -q "component:[[:space:]]*${type}[[:space:]]*\\{" "$family" \
    || fail "active family does not load Phase 4 type: $type"
done

rg -q 'WlSessionLock[[:space:]]*\{' modules/raohane/RaohaneLock.qml \
  || fail 'native Lock lost WlSessionLock'
rg -q 'function status\(\): string' modules/raohane/RaohaneLock.qml \
  || fail 'native Lock lost runtime status IPC'
rg -q 'PamContext[[:space:]]*\{' modules/raohane/RaohaneLockContext.qml \
  || fail 'native Lock lost PAM transaction'

for file in modules/raohane/RaohaneBar.qml modules/raohane/RaohaneVerticalBar.qml; do
  for symbol in \
    'monitorHasFullscreen' \
    'fullscreenSuppressed' \
    'RaohaneConfig\.barShowOnSuper' \
    'RaohaneState\.superDown' \
    'target:[[:space:]]*"bar"' \
    'function mode\(\): string' \
    'name:[[:space:]]*"barToggle"'; do
    rg -q "$symbol" "$file" || fail "$file lost Phase 4 bar contract: $symbol"
  done
done
rg -q 'return[[:space:]]+"horizontal"' modules/raohane/RaohaneBar.qml \
  || fail 'horizontal bar lost runtime mode identity'
rg -q 'return[[:space:]]+"vertical"' modules/raohane/RaohaneVerticalBar.qml \
  || fail 'vertical bar lost runtime mode identity'

for file in \
  modules/raohane/RaohaneOverlay.qml \
  modules/raohane/RaohaneSidebarLeft.qml \
  modules/raohane/RaohaneRegionSelector.qml \
  modules/raohane/RaohaneScreenTranslator.qml \
  modules/raohane/RaohaneScreenFrame.qml \
  modules/raohane/RaohaneScreenCorners.qml \
  modules/raohane/RaohaneDropShelfPanel.qml; do
  [[ -s "$file" ]] || fail "empty Phase 4 chrome/capture surface: $file"
done
rg -q 'region-ocr\.sh' modules/raohane/RaohaneRegionSelector.qml \
  || fail 'region selector lost native OCR backend'
rg -q 'region-search\.sh' modules/raohane/RaohaneRegionSelector.qml \
  || fail 'region selector lost native image-search backend'
rg -q 'screen-translate\.sh' modules/raohane/RaohaneScreenTranslator.qml \
  || fail 'screen translator lost native translation backend'
if rg -n -i 'still being migrated|migration placeholder|temporary compatibility' \
  modules/raohane/RaohaneRegionSelector.qml modules/raohane/RaohaneScreenTranslator.qml \
  modules/raohane/RaohaneSidebarLeft.qml modules/raohane/RaohaneVerticalBar.qml; then
  fail 'Phase 4 visible surface regressed to migration-only UX'
fi

# Final Settings parity: navigation, exact-control search and persisted values
# are linked through one Raohane-owned registry instead of duplicated UI tables.
rg -q '^RaohaneSettingsSearch .*RaohaneSettingsSearch.qml$' "$qmldir" \
  || fail 'global Settings search is not registered'
rg -q '^singleton RaohaneSettingsPageRegistry .*RaohaneSettingsPageRegistry.qml$' "$qmldir" \
  || fail 'Settings page registry is not registered'
rg -q 'RaohaneSettingsSearch[[:space:]]*\{' "$settings" \
  || fail 'Settings window does not consume native global search'
rg -q 'Qt\.ControlModifier' "$settings" \
  || fail 'Settings lost Ctrl+F search focus shortcut'
rg -q 'function page\(page: string\)' "$settings" \
  || fail 'Settings lost direct page IPC routing'
rg -q 'function status\(\): string' "$settings" \
  || fail 'Settings lost runtime status IPC'
rg -q 'RaohaneState\.settingsPage = entry\.section \+ ":" \+ entry\.key' "$settings_search" \
  || fail 'Settings search does not route to exact native controls'
rg -q 'RaohaneSettingsPageRegistry\.searchEntries\(\)' "$settings_search" \
  || fail 'Settings search does not consume the page registry'

mapfile -t registry_keys < <(rg -o 'type:[[:space:]]*"(toggle|number|text)",[[:space:]]*key:[[:space:]]*"[A-Za-z0-9_]+"' "$settings_registry" \
  | sed -E 's/.*key:[[:space:]]*"([A-Za-z0-9_]+)"/\1/' | sort -u)
[[ "${#registry_keys[@]}" -gt 0 ]] || fail 'Settings registry exposes no native control keys'
for key in "${registry_keys[@]}" themePreset barModuleLayout desktopWidgetsLayout; do
  rg -q "property [^:]+ ${key}:" "$config" \
    || fail "Settings registry points to non-native config key: $key"
done

for symbol in \
  'target:[[:space:]]*"runtime"' \
  'function phase4\(\): string' \
  'function monitors\(\): string' \
  'focusedMonitor' \
  'bar:' 'lock:' 'settings:' 'chrome:' 'capture:' \
  'RaohaneConfig\.barVertical' \
  'RaohaneState\.screenLocked' \
  'RaohaneState\.screenTranslatorOpen' \
  'RaohaneDropShelf\.open' \
  'dropShelfOpen:'; do
  rg -q "$symbol" "$runtime_probe" || fail "runtime probe lost contract: $symbol"
done

for symbol in \
  'phase4_json' \
  'ipc runtime phase4' \
  '--exercise' \
  '--vertical' \
  '--lock' \
  '--capture' \
  '--translate' \
  '--full' \
  'wait_for_bar_mode' \
  'set_config_vertical' \
  'restore_vertical_config' \
  'trap cleanup EXIT' \
  'ipc sidebarLeft open' \
  'ipc dropShelf open' \
  'ipc bar close' \
  'ipc bar open' \
  'ipc lock activate' \
  'ipc region screenshot' \
  'ipc screenTranslator translate' \
  'retired compatibility source trees are absent' \
  'Phase 4 live validation: PASS'; do
  rg -q -- "$symbol" "$live_check" || fail "live Phase 4 validator lost contract: $symbol"
done
bash -n "$live_check"

for symbol in \
  'doctor \[all\|graphics\|deps\|services\|runtime\|phase4\]' \
  'validate phase4' \
  'find_phase4_validator' \
  'run_phase4_validator' \
  '^[[:space:]]*phase4\)' \
  'run_phase4_validator "\$@"'; do
  rg -q "$symbol" "$cli" || fail "Raohane CLI lost Phase 4 route: $symbol"
done

printf 'phase4-visible-runtime-audit: native visible surfaces, bar parity, runtime probe, registry-backed Settings search and full live validation workflow are valid\n'
