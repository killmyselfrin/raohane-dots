#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'raohane-audit: %s\n' "$*" >&2
  exit 1
}

required_root=(
  shell.qml
  qmldir
  VERSION
  LICENSE
  NOTICE-UPSTREAM.md
  panelFamilies/RaohaneFamily.qml
  modules/raohane/qmldir
  modules/raohane/config/qmldir
  modules/raohane/services/qmldir
  modules/raohane/RaohaneState.qml
  modules/raohane/RaohaneTheme.qml
  modules/raohane/RaohaneThemeLibrary.qml
  modules/raohane/RaohaneIcon.qml
  modules/raohane/RaohaneRuntimeProbe.qml
  modules/raohane/RaohaneSettingsSearch.qml
  modules/raohane/RaohaneTaskManager.qml
  modules/raohane/config/RaohaneConfig.qml
  modules/raohane/config/RaohanePaths.qml
  modules/raohane/services/RaohaneProcesses.qml
  modules/raohane/services/RaohaneLyrics.qml
  defaults/native.json
  defaults/themes/serpantinum.json
  scripts/raohane
  scripts/lyrics-resolve.py
  scripts/theme-catalog.py
  scripts/raohane-audit.sh
  scripts/source-lineage-audit.sh
  scripts/theme-library-audit.sh
  scripts/nix-boundary-audit.sh
  scripts/runtime-payload-audit.sh
  scripts/package-release.sh
  scripts/release-live-check.sh
  scripts/runtime-surface-boundary-audit.sh
  scripts/phase4-visible-runtime-audit.sh
  scripts/phase4-live-check.sh
  scripts/multimonitor-boundary-audit.sh
  scripts/fullscreen-boundary-audit.sh
  scripts/primary-surface-boundary-audit.sh
  scripts/overview-pointer-boundary-audit.sh
  scripts/privacy-performance-audit.sh
  scripts/sidebar-performance-audit.sh
  scripts/bluetooth-performance-audit.sh
  scripts/easyeffects-performance-audit.sh
  scripts/keyboard-layout-boundary-audit.sh
  scripts/desktop-widget-boundary-audit.sh
  scripts/install-deps.sh
  scripts/migrate-legacy-config.py
  scripts/screen-translate.sh
  scripts/region-ocr.sh
  scripts/region-search.sh
  install-raohane.sh
  install/arch/required.txt
  install/arch/features.txt
)
for path in "${required_root[@]}"; do
  [[ -e "$path" ]] || fail "required project path is missing: $path"
done

while IFS= read -r module_dir; do
  directory="$(dirname -- "$module_dir")"
  while read -r first second third rest; do
    [[ -z "${first:-}" || "$first" == module || "$first" == plugin || "$first" == classname || "$first" == depends || "$first" == optional || "$first" == prefer || "$first" == typeinfo || "$first" == internal ]] && continue
    if [[ "$first" == singleton ]]; then
      file="${rest:-}"
    else
      file="${third:-}"
    fi
    [[ -z "$file" || "$file" == *.so ]] && continue
    [[ -f "$directory/$file" ]] || fail "$module_dir references missing file $directory/$file"
  done < "$module_dir"
done < <(find . -name qmldir -not -path './.git/*' -print)

rg -q '^module[[:space:]]+qs$' qmldir \
  || fail 'root qmldir no longer declares module qs'
if rg -n '^[[:space:]]*(singleton[[:space:]]+)?GlobalStates\b' qmldir; then
  fail 'root qmldir exports GlobalStates and can pull the inherited service graph into shell bootstrap'
fi

rg -q '^import "modules/raohane/config"$' shell.qml \
  || fail 'shell.qml does not import native Raohane config'
rg -q '^import "panelFamilies"$' shell.qml \
  || fail 'shell.qml does not import panel families'
rg -q 'active:[[:space:]]*RaohaneConfig\.ready' shell.qml \
  || fail 'shell.qml is not gated by RaohaneConfig readiness'
rg -q 'component:[[:space:]]*RaohaneFamily[[:space:]]*\{' shell.qml \
  || fail 'shell.qml does not load RaohaneFamily'

if rg -n \
  '^import "modules/common"|^import "services"|\bIllogicalImpulseFamily\b|\bPanelFamilyLoader\b|\bConfig\.|\bGlobalStates\.|\bMaterialThemeLoader\b|\bHyprsunset\b|\bFirstRunExperience\b|\bConflictKiller\b|\bCliphist\b|\bUpdates\b|\bLyricsService\b' \
  shell.qml; then
  fail 'shell bootstrap resolves inherited framework or services'
fi

family='panelFamilies/RaohaneFamily.qml'
if rg -n '^import qs\.modules\.ii(\.|$)|\bRaohaneLegacyBridge\b|\bIllogicalImpulseFamily\b' "$family"; then
  fail 'RaohaneFamily resolves a legacy presentation/bootstrap path'
fi

if [[ -e modules/raohane/RaohaneLegacyBridge.qml ]]; then
  fail 'retired RaohaneLegacyBridge returned to the runtime tree'
fi
if rg -n '\bRaohaneLegacyBridge\b' modules/raohane/qmldir; then
  fail 'native qmldir exports the retired compatibility bridge'
fi

active_surfaces=(
  RaohaneBackground
  RaohaneDesktopCanvas
  RaohaneBar
  RaohaneVerticalBar
  RaohaneDock
  RaohaneLock
  RaohaneNotificationPopup
  RaohaneOsd
  RaohaneOnScreenKeyboard
  RaohaneOverlay
  RaohaneOverview
  RaohanePolkit
  RaohaneRegionSelector
  RaohaneScreenCorners
  RaohaneScreenTranslator
  RaohaneSidebarLeft
  RaohaneLauncher
  RaohaneControlCenter
  RaohaneSettings
  RaohaneMediaOverlay
  RaohaneWallpaperSelector
  RaohaneDesktopMenu
  RaohaneSessionScreen
  RaohaneTaskManager
  RaohaneDropShelfPanel
  RaohaneScreenFrame
)
for surface in "${active_surfaces[@]}"; do
  rg -q "component:[[:space:]]*${surface}[[:space:]]*\\{" "$family" \
    || fail "RaohaneFamily does not load $surface"
  rg -q "^${surface} .*${surface}\.qml$" modules/raohane/qmldir \
    || fail "$surface is not registered in native qmldir"
done

rg -q '^RaohaneRuntimeProbe .*RaohaneRuntimeProbe.qml$' modules/raohane/qmldir \
  || fail 'RaohaneRuntimeProbe is not registered'
rg -q 'component:[[:space:]]*RaohaneRuntimeProbe[[:space:]]*\{' "$family" \
  || fail 'RaohaneFamily does not load the runtime probe'

active_root_files=()
for surface in "${active_surfaces[@]}"; do
  active_root_files+=("modules/raohane/${surface}.qml")
done
for file in "${active_root_files[@]}"; do
  [[ -f "$file" ]] || fail "missing active root file: $file"
  if rg -n '^import qs\.modules\.common\.widgets(\.|$)|^import qs\.modules\.ii(\.|$)' "$file"; then
    fail "$file can resolve inherited widget/ii types during boot"
  fi
done

rg -q '^singleton RaohaneState .*RaohaneState.qml$' modules/raohane/qmldir \
  || fail 'RaohaneState is not registered'
rg -q '^singleton RaohaneConfig .*RaohaneConfig.qml$' modules/raohane/config/qmldir \
  || fail 'RaohaneConfig is not registered'
rg -q '^RaohaneIcon .*RaohaneIcon.qml$' modules/raohane/qmldir \
  || fail 'RaohaneIcon is not registered'
rg -q '^singleton RaohaneDropShelf .*RaohaneDropShelf.qml$' modules/raohane/services/qmldir \
  || fail 'RaohaneDropShelf is not registered'
rg -q '^singleton RaohaneAutostart .*RaohaneAutostart.qml$' modules/raohane/services/qmldir \
  || fail 'RaohaneAutostart is not registered'
rg -q '^singleton RaohaneProcesses .*RaohaneProcesses.qml$' modules/raohane/services/qmldir \
  || fail 'RaohaneProcesses is not registered'
rg -q '^singleton RaohaneLyrics .*RaohaneLyrics.qml$' modules/raohane/services/qmldir \
  || fail 'RaohaneLyrics is not registered'

if rg -n -i 'inir|\bniri\b|waffle|ricelin' modules/raohane shell.qml "$family"; then
  fail 'Raohane product runtime contains a non-target/legacy identity'
fi
rg -q '^import Quickshell\.Hyprland$' modules/raohane/RaohaneBar.qml \
  || fail 'native bar lost Hyprland integration'

while IFS= read -r qml; do
  if rg -q '\bConnections[[:space:]]*\{' "$qml"; then
    rg -q '^import (QtQuick|QtQml)([[:space:]]|;|$)' "$qml" \
      || fail "$qml uses Connections without QtQuick/QtQml"
  fi
  if rg -q '\b(IpcHandler|Process|StdioCollector|SplitParser)\b' "$qml"; then
    rg -q '^import Quickshell\.Io([[:space:]]|;|$)' "$qml" \
      || fail "$qml uses Quickshell.Io types without importing Quickshell.Io"
  fi
done < <(find modules/raohane -type f -name '*.qml' -print)

# Lyrics network resolution belongs in an owned backend helper. Keep networking
# out of QML so UI state, request lifecycle and LRCLIB HTTP behavior stay separate.
rg -q 'Quickshell\.shellPath\("scripts/lyrics-resolve\.py"\)' modules/raohane/services/RaohaneLyrics.qml \
  || fail 'RaohaneLyrics does not invoke the owned resolver backend'
if rg -n 'XMLHttpRequest|https://lrclib\.net/api' modules/raohane/services/RaohaneLyrics.qml; then
  fail 'RaohaneLyrics regressed to direct QML HTTP requests'
fi
python3 - scripts/lyrics-resolve.py <<'PY'
import pathlib
import sys
path = pathlib.Path(sys.argv[1])
compile(path.read_text(encoding="utf-8"), str(path), "exec")
PY

for route in \
  'ipc raohaneLauncher toggle' \
  'ipc raohaneMedia toggle' \
  'ipc raohaneDesktop toggle' \
  'ipc wallpaperSelector toggle' \
  'ipc session toggle' \
  'ipc screenTranslator translate'; do
  rg -q "$route" scripts/raohane || fail "CLI route missing: $route"
done

rg -q 'validate release' scripts/raohane \
  || fail 'CLI usage does not expose live release validation'
rg -q '^find_release_validator\(\)' scripts/raohane \
  || fail 'CLI does not resolve the installed live release validator'
rg -q '\$RUNTIME/scripts/release-live-check\.sh' scripts/raohane \
  || fail 'CLI does not prefer the installed live release validator'
rg -q 'run_release_validator "\$@"' scripts/raohane \
  || fail 'validate release route does not execute the release validator'

rg -q 'RAOHANE_CONFIG_FILE="\$RAOHANE_CONFIG/native\.json"' install-raohane.sh \
  || fail 'installer does not use native.json as the authoritative config'
rg -q 'RAOHANE_AUTOSTART_FILE="\$RAOHANE_CONFIG/autostart\.conf"' install-raohane.sh \
  || fail 'installer does not use native Raohane autostart'
rg -q 'defaults/native\.json' install-raohane.sh \
  || fail 'installer does not seed native schema defaults'
rg -q 'migrate-legacy-config\.py' install-raohane.sh \
  || fail 'installer lost safe legacy conversion'
rg -q 'scripts/install-deps\.sh' install-raohane.sh \
  || fail 'main installer is not using the Raohane dependency installer'

if rg -n '^[[:space:]]+"(modules/common|modules/ii|services|panelFamilies/IllogicalImpulseFamily\.qml)"' install-raohane.sh; then
  fail 'installer still requires inherited runtime trees'
fi
if rg -n '\bAUTOSTART_SOURCE_LINE\b' install-raohane.sh; then
  fail 'installer can still source the retired Hyprland autostart path'
fi
if rg -n 'install-foundation-deps|sync-end4-foundation|git[[:space:]]+clone' install-raohane.sh scripts/install-deps.sh scripts/raohane; then
  fail 'normal install/doctor path executes upstream shell infrastructure'
fi

rg -q '"schemaVersion"[[:space:]]*:[[:space:]]*12' defaults/native.json \
  || fail 'native defaults are not schema v12'
python3 scripts/migrate-legacy-config.py --help >/dev/null

bash -n scripts/raohane
bash -n scripts/raohane-audit.sh
bash -n scripts/source-lineage-audit.sh
bash -n scripts/theme-library-audit.sh
bash -n scripts/nix-boundary-audit.sh
bash -n scripts/runtime-payload-audit.sh
bash -n scripts/package-release.sh
bash -n scripts/release-live-check.sh
bash -n scripts/runtime-surface-boundary-audit.sh
bash -n scripts/phase4-visible-runtime-audit.sh
bash -n scripts/phase4-live-check.sh
bash -n scripts/multimonitor-boundary-audit.sh
bash -n scripts/fullscreen-boundary-audit.sh
bash -n scripts/primary-surface-boundary-audit.sh
bash -n scripts/overview-pointer-boundary-audit.sh
bash -n scripts/privacy-performance-audit.sh
bash -n scripts/sidebar-performance-audit.sh
bash -n scripts/bluetooth-performance-audit.sh
bash -n scripts/easyeffects-performance-audit.sh
bash -n scripts/keyboard-layout-boundary-audit.sh
bash -n scripts/desktop-widget-boundary-audit.sh
bash -n scripts/install-deps.sh
bash -n scripts/screen-translate.sh
bash -n scripts/region-ocr.sh
bash -n scripts/region-search.sh
bash -n scripts/videos/record.sh
bash -n install-raohane.sh

bash scripts/source-lineage-audit.sh
bash scripts/theme-library-audit.sh
bash scripts/nix-boundary-audit.sh
bash scripts/phase4-visible-runtime-audit.sh
bash scripts/multimonitor-boundary-audit.sh
bash scripts/fullscreen-boundary-audit.sh
bash scripts/primary-surface-boundary-audit.sh
bash scripts/overview-pointer-boundary-audit.sh
bash scripts/privacy-performance-audit.sh
bash scripts/sidebar-performance-audit.sh
bash scripts/bluetooth-performance-audit.sh
bash scripts/easyeffects-performance-audit.sh
bash scripts/keyboard-layout-boundary-audit.sh
bash scripts/desktop-widget-boundary-audit.sh

printf 'raohane-audit: native bootstrap, source lineage, release CLI, coordinated Task Manager, owned lyrics resolver, Phase 4 runtime contract, overview routing, multi-monitor/fullscreen behavior and native release boundaries are valid\n'
