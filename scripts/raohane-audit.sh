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
  panelFamilies/RaohaneFamily.qml
  modules/raohane/qmldir
  modules/raohane/config/qmldir
  modules/raohane/services/qmldir
  modules/raohane/RaohaneState.qml
  modules/raohane/RaohaneTheme.qml
  modules/raohane/RaohaneIcon.qml
  modules/raohane/config/RaohaneConfig.qml
  modules/raohane/config/RaohanePaths.qml
  scripts/raohane
  scripts/raohane-audit.sh
  scripts/runtime-surface-boundary-audit.sh
  scripts/install-deps.sh
  install-raohane.sh
  install/arch/required.txt
  install/arch/features.txt
)
for path in "${required_root[@]}"; do
  [[ -e "$path" ]] || fail "required project path is missing: $path"
done

# Check every qmldir points to files that actually exist. This catches broken
# registrations without forcing legacy modules to be instantiated at runtime.
while IFS= read -r qmldir; do
  directory="$(dirname -- "$qmldir")"
  while read -r first second third rest; do
    [[ -z "${first:-}" || "$first" == module || "$first" == plugin || "$first" == classname || "$first" == depends || "$first" == optional || "$first" == prefer || "$first" == typeinfo || "$first" == internal ]] && continue
    if [[ "$first" == singleton ]]; then
      file="${rest:-}"
    else
      file="${third:-}"
    fi
    [[ -z "$file" || "$file" == *.so ]] && continue
    [[ -f "$directory/$file" ]] || fail "$qmldir references missing file $directory/$file"
  done < "$qmldir"
done < <(find . -name qmldir -not -path './.git/*' -print)

# Native-only bootstrap. A legacy type referenced in a component expression is
# resolved by QML even when the corresponding loader is inactive, so startup
# must not contain fallback family or inherited service references at all.
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
if rg -n '^import qs\.modules\.ii(\.|$)|\bRaohaneLegacyBridge\.load\b|\bIllogicalImpulseFamily\b' "$family"; then
  fail 'RaohaneFamily resolves a legacy presentation/bootstrap path'
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
  RaohaneDropShelfPanel
  RaohaneScreenFrame
)
for surface in "${active_surfaces[@]}"; do
  rg -q "component:[[:space:]]*${surface}[[:space:]]*\\{" "$family" \
    || fail "RaohaneFamily does not load $surface"
  rg -q "^${surface} .*${surface}\.qml$" modules/raohane/qmldir \
    || fail "$surface is not registered in native qmldir"
done

# Active root components must not directly resolve the inherited widget or ii
# modules. Deeper feature-specific contracts are checked by dedicated audits.
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

# Product identity and target compositor remain Hyprland-only in native code.
if rg -n -i 'inir|\bniri\b|waffle|ricelin' modules/raohane shell.qml "$family"; then
  fail 'Raohane product runtime contains a non-target/legacy identity'
fi
rg -q '^import Quickshell\.Hyprland$' modules/raohane/RaohaneBar.qml \
  || fail 'native bar lost Hyprland integration'

# QML semantic import requirements that qmlformat alone does not catch.
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

# CLI and installation routes must point to Raohane-owned runtime entry points.
for route in \
  'ipc raohaneLauncher toggle' \
  'ipc raohaneMedia toggle' \
  'ipc raohaneDesktop toggle' \
  'ipc wallpaperSelector toggle' \
  'ipc session toggle'; do
  rg -q "$route" scripts/raohane || fail "CLI route missing: $route"
done

rg -q 'scripts/install-deps\.sh' install-raohane.sh \
  || fail 'main installer is not using the Raohane dependency installer'
if rg -n 'install-foundation-deps|sync-end4-foundation|git[[:space:]]+clone' install-raohane.sh scripts/install-deps.sh scripts/raohane; then
  fail 'normal install/doctor path executes upstream shell infrastructure'
fi

bash -n scripts/raohane
bash -n scripts/raohane-audit.sh
bash -n scripts/runtime-surface-boundary-audit.sh
bash -n scripts/install-deps.sh
bash -n scripts/videos/record.sh
bash -n install-raohane.sh

printf 'raohane-audit: native bootstrap, active surface graph, installation and config boundaries are valid\n'
