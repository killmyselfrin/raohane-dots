#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'runtime-surface-boundary-audit: %s\n' "$*" >&2
  exit 1
}

family='panelFamilies/RaohaneFamily.qml'
qmldir='modules/raohane/qmldir'
services_qmldir='modules/raohane/services/qmldir'
required='install/arch/required.txt'
features='install/arch/features.txt'

native_surfaces=(
  modules/raohane/RaohaneOverlay.qml
  modules/raohane/RaohaneSidebarLeft.qml
  modules/raohane/RaohaneRegionSelector.qml
  modules/raohane/RaohaneScreenTranslator.qml
  modules/raohane/RaohaneVerticalBar.qml
  modules/raohane/RaohaneDropShelfPanel.qml
  modules/raohane/services/RaohaneDropShelf.qml
)

for path in "$family" "$qmldir" "$services_qmldir" "$required" "$features" "${native_surfaces[@]}"; do
  [[ -f "$path" ]] || fail "missing native runtime surface path: $path"
done

if rg -n '^import qs\.modules\.ii(\.|$)' "$family"; then
  fail 'RaohaneFamily still imports inherited modules/ii presentation code'
fi

for legacy_type in Overlay RegionSelector ScreenTranslator SidebarLeft VerticalBar DropShelfPanel; do
  if rg -n "component:[[:space:]]*${legacy_type}[[:space:]]*\\{" "$family"; then
    fail "RaohaneFamily still instantiates inherited ${legacy_type}"
  fi
done

for native_type in \
  RaohaneOverlay \
  RaohaneRegionSelector \
  RaohaneScreenTranslator \
  RaohaneSidebarLeft \
  RaohaneVerticalBar \
  RaohaneDropShelfPanel; do
  rg -q "^${native_type} .*${native_type}\.qml$" "$qmldir" \
    || fail "missing native runtime registration: ${native_type}"
  rg -q "component:[[:space:]]*${native_type}[[:space:]]*\\{" "$family" \
    || fail "RaohaneFamily does not load ${native_type}"
done

rg -q '^singleton RaohaneDropShelf .*RaohaneDropShelf.qml$' "$services_qmldir" \
  || fail 'RaohaneDropShelf is not registered in native services'

for file in "${native_surfaces[@]}"; do
  if rg -n '^import qs$|^import qs\.services$|^import qs\.modules\.common|^import qs\.modules\.ii|\bConfig\.|\bGlobalStates\.|\bAppearance\.' "$file"; then
    fail "$file regressed to inherited runtime framework"
  fi
done

for contract in \
  'RaohaneState\.overlayOpen' \
  'target:[[:space:]]*"overlay"' \
  'name:[[:space:]]*"overlayToggle"'; do
  rg -q "$contract" modules/raohane/RaohaneOverlay.qml \
    || fail "native overlay lost contract: $contract"
done

for contract in \
  'target:[[:space:]]*"region"' \
  'name:[[:space:]]*"regionScreenshot"' \
  'name:[[:space:]]*"regionRecord"' \
  'RaohanePaths.*videos/record\.sh'; do
  rg -q "$contract" modules/raohane/RaohaneRegionSelector.qml \
    || fail "native region capture lost contract: $contract"
done

for tool in grim slurp wf-recorder; do
  rg -q "^${tool}$" "$features" || fail "feature package manifest lost ${tool}"
done
rg -q '^wl-clipboard$' "$required" || fail 'required package manifest lost wl-clipboard'

for contract in \
  'RaohaneDropShelf\.addItems' \
  'RaohaneDropShelf\.copyAll' \
  'RaohaneDropShelf\.clear' \
  'RaohaneDropShelf\.hide'; do
  rg -q "$contract" modules/raohane/RaohaneDropShelfPanel.qml \
    || fail "native drop shelf panel lost contract: $contract"
done
rg -q 'wl-copy --type text/uri-list' modules/raohane/services/RaohaneDropShelf.qml \
  || fail 'native drop shelf backend lost clipboard transfer contract'

printf 'runtime-surface-boundary-audit: active family no longer resolves modules/ii overlay/sidebar/capture/vertical/drop-shelf surfaces\n'
