#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'runtime-surface-boundary-audit: %s\n' "$*" >&2
  exit 1
}

shell='shell.qml'
family='panelFamilies/RaohaneFamily.qml'
qmldir='modules/raohane/qmldir'
services_qmldir='modules/raohane/services/qmldir'
required='install/arch/required.txt'
features='install/arch/features.txt'
translator_backend='scripts/screen-translate.sh'
region_ocr_backend='scripts/region-ocr.sh'
region_search_backend='scripts/region-search.sh'

aoverlay='modules/raohane/RaohaneOverlay.qml'

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

for path in "$shell" "$family" "$qmldir" "$services_qmldir" "$required" "$features" "$translator_backend" "$region_ocr_backend" "$region_search_backend" "${native_surfaces[@]}" "${active_roots[@]}"; do
  [[ -f "$path" ]] || fail "missing native runtime surface path: $path"
done

rg -q 'active:[[:space:]]*RaohaneConfig\.ready' "$shell" \
  || fail 'shell.qml is not gated by native RaohaneConfig readiness'
rg -q 'component:[[:space:]]*RaohaneFamily[[:space:]]*\{' "$shell" \
  || fail 'shell.qml no longer resolves RaohaneFamily'

if rg -n \
  '^import "modules/common"|^import "services"|\bIllogicalImpulseFamily\b|\bPanelFamilyLoader\b|\bConfig\.|\bMaterialThemeLoader\b|\bHyprsunset\b|\bFirstRunExperience\b|\bConflictKiller\b|\bCliphist\b|\bUpdates\b|\bLyricsService\b|\bWallpapers\.load\b' \
  "$shell"; then
  fail 'shell.qml can resolve inherited bootstrap framework/services'
fi

if rg -n '\bRaohaneLegacyBridge\b' "$family"; then
  fail 'RaohaneFamily still resolves the legacy bridge during startup'
fi

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
  'running:[[:space:]]*RaohaneState\.overlayOpen' \
  'target:[[:space:]]*"overlay"' \
  'name:[[:space:]]*"overlayToggle"'; do
  rg -q "$contract" "$aoverlay" \
    || fail "native overlay lost contract: $contract"
done
if rg -n 'running:[[:space:]]*true' "$aoverlay"; then
  fail 'hidden overlay can keep an unconditional repeating timer alive'
fi

for contract in \
  'target:[[:space:]]*"region"' \
  'name:[[:space:]]*"regionScreenshot"' \
  'name:[[:space:]]*"regionSearch"' \
  'name:[[:space:]]*"regionOcr"' \
  'name:[[:space:]]*"regionRecord"' \
  'region-search\.sh' \
  'region-ocr\.sh' \
  'RaohanePaths.*videos/record\.sh'; do
  rg -q "$contract" modules/raohane/RaohaneRegionSelector.qml \
    || fail "native region capture lost contract: $contract"
done
if rg -n 'OCR is still being migrated|Native OCR is still being migrated' modules/raohane/RaohaneRegionSelector.qml; then
  fail 'native region OCR regressed to a migration placeholder'
fi

for tool in grim slurp wf-recorder; do
  rg -q "^${tool}$" "$features" || fail "feature package manifest lost ${tool}"
done
rg -q '^wl-clipboard$' "$required" || fail 'required package manifest lost wl-clipboard'
rg -q '^xdg-utils$' "$required" || fail 'required package manifest lost xdg-utils for image-search handoff'

for package in tesseract tesseract-data-eng tesseract-data-rus translate-shell; do
  rg -q "^${package}$" "$features" || fail "screen translation/OCR package manifest lost ${package}"
done

for command in slurp grim tesseract wl-copy; do
  rg -q "for command in .*${command}" "$region_ocr_backend" \
    || rg -q "${command}" "$region_ocr_backend" \
    || fail "region OCR backend lost command contract: ${command}"
done
rg -q 'wl-copy --type text/plain' "$region_ocr_backend" \
  || fail 'region OCR backend no longer copies recognized text'
rg -q 'tesseract .* -l eng\+rus' "$region_ocr_backend" \
  || fail 'region OCR backend lost English/Russian OCR languages'

for command in slurp grim wl-copy xdg-open; do
  rg -q "${command}" "$region_search_backend" \
    || fail "region image-search backend lost command contract: ${command}"
done
rg -q 'https://lens\.google\.com/' "$region_search_backend" \
  || fail 'region image-search backend lost Lens handoff'
rg -q 'wl-copy --type image/png' "$region_search_backend" \
  || fail 'region image-search backend no longer places capture in clipboard'

rg -q 'for command in slurp grim tesseract trans python3; do' "$translator_backend" \
  || fail 'screen translation backend lost required command list'
rg -q 'command -v "\$command"' "$translator_backend" \
  || fail 'screen translation backend lost generic command probe'
for contract in \
  'scripts/screen-translate\.sh' \
  'function startTranslation\(\)' \
  'target:[[:space:]]*"screenTranslator"' \
  'function translate\(\)' \
  'name:[[:space:]]*"screenTranslate"' \
  'Quickshell\.clipboardText'; do
  rg -q "$contract" modules/raohane/RaohaneScreenTranslator.qml \
    || fail "native screen translator lost contract: $contract"
done

bash -n "$region_ocr_backend"
bash -n "$region_search_backend"
bash -n "$translator_backend"

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

printf 'runtime-surface-boundary-audit: native bootstrap, idle-safe overlay, capture/OCR/search and active family boundaries are valid\n'
