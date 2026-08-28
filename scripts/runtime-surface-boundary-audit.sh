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
  modules/raohane/RaohaneDesktopMenu.qml
  modules/raohane/RaohaneBackground.qml
  modules/raohane/RaohaneDesktopCanvas.qml
  modules/raohane/services/RaohaneDropShelf.qml
)

active_roots=(
  modules/raohane/RaohaneBackground.qml
  modules/raohane/RaohaneDesktopCanvas.qml
  modules/raohane/RaohaneBar.qml
  modules/raohane/RaohaneVerticalBar.qml
  modules/raohane/RaohaneDock.qml
  modules/raohane/RaohaneLock.qml
  modules/raohane/RaohaneNotificationPopup.qml
  modules/raohane/RaohaneOsd.qml
  modules/raohane/RaohaneOnScreenKeyboard.qml
  modules/raohane/RaohaneOverlay.qml
  modules/raohane/RaohaneOverview.qml
  modules/raohane/RaohanePolkit.qml
  modules/raohane/RaohaneRegionSelector.qml
  modules/raohane/RaohaneScreenCorners.qml
  modules/raohane/RaohaneScreenTranslator.qml
  modules/raohane/RaohaneSidebarLeft.qml
  modules/raohane/RaohaneLauncher.qml
  modules/raohane/RaohaneControlCenter.qml
  modules/raohane/RaohaneSettings.qml
  modules/raohane/RaohaneMediaOverlay.qml
  modules/raohane/RaohaneWallpaperSelector.qml
  modules/raohane/RaohaneDesktopMenu.qml
  modules/raohane/RaohaneSessionScreen.qml
  modules/raohane/RaohaneDropShelfPanel.qml
  modules/raohane/RaohaneScreenFrame.qml
)

for path in "$family" "$qmldir" "$services_qmldir" "$required" "$features" "${native_surfaces[@]}" "${active_roots[@]}"; do
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

for file in "${active_roots[@]}"; do
  if rg -n '^import qs\.modules\.common\.widgets(\.|$)|^import qs\.modules\.ii(\.|$)' "$file"; then
    fail "$file can resolve inherited widget/ii types during boot"
  fi
done

if rg -n '\bMaterialSymbol[[:space:]]*\{' modules/raohane/RaohaneDesktopMenu.qml; then
  fail 'RaohaneDesktopMenu regressed to inherited MaterialSymbol instead of RaohaneIcon'
fi

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

for contract in \
  'RaohaneState\.desktopMenuOpen' \
  'RaohaneConfig\.wallpaperPath' \
  'RaohaneWallpapers\.randomFromCurrentFolder' \
  'RaohaneDropShelf\.show' \
  'RaohaneIcon[[:space:]]*\{'; do
  rg -q "$contract" modules/raohane/RaohaneDesktopMenu.qml \
    || fail "native desktop menu lost contract: $contract"
done

printf 'runtime-surface-boundary-audit: active family no longer resolves inherited ii/common widget surfaces at boot\n'
