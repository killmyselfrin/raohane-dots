#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'raohane-audit: %s\n' "$*" >&2
  exit 1
}

[[ -f shell.qml ]] || fail 'shell.qml is missing'
[[ -d modules/raohane ]] || fail 'modules/raohane is missing'
[[ -f panelFamilies/RaohaneFamily.qml ]] || fail 'RaohaneFamily.qml is missing'
[[ -f scripts/raohane ]] || fail 'Raohane CLI is missing'

required_native=(
  modules/raohane/RaohaneTheme.qml
  modules/raohane/RaohaneState.qml
  modules/raohane/RaohanePrivacy.qml
  modules/raohane/RaohaneContext.qml
  modules/raohane/RaohaneContextIsland.qml
  modules/raohane/RaohaneBar.qml
  modules/raohane/RaohaneLauncher.qml
  modules/raohane/RaohaneControlCenter.qml
  modules/raohane/RaohaneSettings.qml
  modules/raohane/RaohaneMediaOverlay.qml
  modules/raohane/RaohaneOsd.qml
  modules/raohane/RaohaneNotificationPopup.qml
)

for path in "${required_native[@]}"; do
  [[ -f "$path" ]] || fail "required native surface is missing: $path"
done

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

while IFS= read -r import_line; do
  import_path="${import_line#import }"
  module_path="${import_path#qs.}"
  module_path="${module_path//./\/}"
  [[ -d "$module_path" ]] || fail "unresolved local module $import_path"
done < <(rg -o --no-filename '^import qs\.[A-Za-z0-9_.]+$' shell.qml modules/raohane | sort -u || true)

for surface in RaohaneBar RaohaneLauncher RaohaneControlCenter RaohaneSettings RaohaneMediaOverlay RaohaneOsd RaohaneNotificationPopup; do
  rg -q "component: ${surface} \{\}" panelFamilies/RaohaneFamily.qml \
    || fail "RaohaneFamily does not load $surface"
done

rg -q '^singleton RaohanePrivacy .*RaohanePrivacy.qml$' modules/raohane/qmldir \
  || fail 'RaohanePrivacy is not registered as a singleton'
rg -q 'RaohanePrivacy\.(recordingActive|microphoneActive|cameraActive)' modules/raohane/RaohaneContext.qml \
  || fail 'Context Island is not wired to the privacy provider'

rg -q 'ipc raohaneLauncher toggle' scripts/raohane \
  || fail 'raohane launcher is not routed to the native launcher IPC'
rg -q 'ipc raohaneMedia toggle' scripts/raohane \
  || fail 'raohane media is not routed to the native media IPC'

if rg -n 'GlobalStates\.raohane[A-Za-z0-9_]+' modules/raohane panelFamilies/RaohaneFamily.qml; then
  fail 'Raohane-owned state leaked back into upstream-refreshed GlobalStates'
fi

if rg -n -i 'inir|niri|waffle|ricelin' modules/raohane shell.qml panelFamilies/RaohaneFamily.qml; then
  fail 'Raohane product runtime contains a forbidden legacy/non-target identity'
fi

rg -q 'import Quickshell.Hyprland' shell.qml \
  || fail 'Raohane shell no longer declares Hyprland integration'
rg -q 'config}/raohane' modules/common/Directories.qml \
  || fail 'Raohane config namespace is not active'

bash -n scripts/raohane
bash -n scripts/sync-end4-foundation.sh
bash -n scripts/install-foundation-deps.sh
bash -n install-raohane.sh

printf 'raohane-audit: native surfaces and primary QML graph are structurally valid\n'
