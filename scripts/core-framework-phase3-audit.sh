#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'phase3-core-framework-audit: %s\n' "$*" >&2
  exit 1
}

config='modules/raohane/config/RaohaneConfig.qml'
paths='modules/raohane/config/RaohanePaths.qml'
root_qmldir='modules/raohane/qmldir'
helper_qmldir='modules/raohane/helpers/qmldir'
helpers='modules/raohane/helpers/RaohaneUtils.qml'
model_qmldir='modules/raohane/models/qmldir'
selection='modules/raohane/models/RaohaneSelectionModel.qml'
launcher='modules/raohane/RaohaneLauncher.qml'
notifications='modules/raohane/services/RaohaneNotifications.qml'
settings='modules/raohane/RaohaneSettingsContent.qml'
family='panelFamilies/RaohaneFamily.qml'

required_files=(
  "$config"
  "$paths"
  "$root_qmldir"
  "$helper_qmldir"
  "$helpers"
  "$model_qmldir"
  "$selection"
  "$launcher"
  "$notifications"
  "$settings"
  "$family"
  modules/raohane/RaohaneSurface.qml
  modules/raohane/RaohaneDivider.qml
  modules/raohane/RaohaneIconButton.qml
)
for path in "${required_files[@]}"; do
  [[ -f "$path" ]] || fail "missing Phase 3 framework file: $path"
done

# Complete persisted product schema: every behavior-bearing property owned by
# the current native product must remain in the standalone config singleton.
product_properties=(
  wallpaperPath lockWallpaperPath wallpaperDirectory wallpaperPreview wallpaperColumns
  wallpaperChangeInterval wallpaperHideWhenFullscreen wallpaperTransitionDuration
  wallpaperDim lockWallpaperDim
  overviewWorkspaceCount overviewColumns
  dockEnabled dockAutoHide dockPinned dockExclusiveZone dockHeight dockIconSize
  dockBottomMargin dockPinnedApps
  barBottom barVertical barAutoHide barAutoHidePushWindows barShowOnSuper
  barShowOnSuperDelay barScreenList barShowDate
  frameEnabled frameThickness frameColor frameBarSideVisible
  screenRoundingMode screenCornerRadius deadPixelWorkaround hotCornersEnabled
  hotCornerValueScroll hotCornerClickless hotCornerRegionWidth hotCornerRegionHeight
  hotCornerBottomLeftAction hotCornerBottomRightAction hotCornerVisualize
  hotCornerClicklessEnd hotCornerVerticalOffset
  oskPinned oskLayout osdTimeout colorTemperature nightLightAutomatic
  networkCommand networkEthernetCommand bluetoothCommand taskManagerCommand
  changePasswordCommand profileDisplayName profileAvatarPath
  quickSliderBrightness quickSliderVolume quickSliderMic
  contextIslandEnabled mediaOverlayEnabled integrationMode
)
for property_name in "${product_properties[@]}"; do
  rg -q "property [^:]+ ${property_name}:" "$config" \
    || fail "complete product schema lost property: $property_name"
  rg -q "on${property_name^}Changed:[[:space:]]*scheduleSave\(\)" "$config" \
    || fail "persisted property lost save handler: $property_name"
done

# Every actual Settings control key must resolve directly into RaohaneConfig.
# Navigation page keys such as home/about are deliberately excluded.
mapfile -t settings_keys < <(rg -o '\{[[:space:]]*type:[[:space:]]*"[^"]+",[[:space:]]*key:[[:space:]]*"[A-Za-z0-9_]+"' "$settings" \
  | sed -E 's/.*key:[[:space:]]*"([A-Za-z0-9_]+)"/\1/' | sort -u)
[[ "${#settings_keys[@]}" -gt 0 ]] || fail 'could not discover native Settings control keys'
for key in "${settings_keys[@]}"; do
  rg -q "property [^:]+ ${key}:" "$config" \
    || fail "Settings control key is not owned by RaohaneConfig: $key"
done

for section in wallpaper overview dock bar frame corners osk osd display apps profile quickControls features; do
  rg -q "${section}:[[:space:]]*\{" "$config" \
    || fail "snapshot lost product section: $section"
done
rg -q 'schemaVersion:[[:space:]]*10' "$config" || fail 'RaohaneConfig schema contract is not v10'
rg -q 'RaohanePaths\.nativeConfigFile' "$config" || fail 'RaohaneConfig bypasses RaohanePaths'

# Raohane owns all directory resolution needed by active runtime/services.
for symbol in \
  'configDirectory' 'nativeConfigFile' 'autostartFile' 'notificationsFile' \
  'stateDirectory' 'cacheDirectory' 'wallpaperCacheDirectory' 'thumbnailDirectory' \
  'coverArtDirectory' 'runtimeDirectory' 'captureTempDirectory' \
  'screenshotTempDirectory' 'screenshotsDirectory' 'recordingsDirectory' \
  'shellDirectory' 'assetsPath' 'scriptsPath' 'defaultsPath' 'fileUrl'; do
  rg -q "$symbol" "$paths" || fail "RaohanePaths lost owned path API: $symbol"
done
if rg -n 'compatibilityConfigFile|illogical-impulse|modules/common|modules/ii' "$paths"; then
  fail 'RaohanePaths exposes compatibility/upstream paths'
fi
rg -q 'RaohanePaths\.notificationsFile' "$notifications" \
  || fail 'notification persistence bypasses RaohanePaths'
if rg -n 'StandardPaths\.standardLocations' "$notifications"; then
  fail 'notification service still constructs XDG paths independently'
fi

# Common widgets are Raohane-owned and used by active UI.
for registration in \
  '^RaohaneSurface .*RaohaneSurface.qml$' \
  '^RaohaneDivider .*RaohaneDivider.qml$' \
  '^RaohaneIconButton .*RaohaneIconButton.qml$'; do
  rg -q "$registration" "$root_qmldir" || fail "missing common widget registration: $registration"
done
rg -q 'RaohaneSurface[[:space:]]*\{' "$launcher" \
  || fail 'active Launcher is not consuming Raohane common widgets'

# Models and helpers are separate native modules and have an active consumer
# chain: Launcher -> SelectionModel -> Utils.
rg -q '^module qs\.modules\.raohane\.models$' "$model_qmldir" \
  || fail 'native models module is not declared'
rg -q '^RaohaneSelectionModel .*RaohaneSelectionModel.qml$' "$model_qmldir" \
  || fail 'selection model is not registered'
rg -q '^module qs\.modules\.raohane\.helpers$' "$helper_qmldir" \
  || fail 'native helpers module is not declared'
rg -q '^singleton RaohaneUtils .*RaohaneUtils.qml$' "$helper_qmldir" \
  || fail 'RaohaneUtils is not registered'
rg -q '^import qs\.modules\.raohane\.models$' "$launcher" \
  || fail 'active Launcher does not consume native models'
rg -q '^import qs\.modules\.raohane\.helpers$' "$selection" \
  || fail 'native model does not consume native helpers'
rg -q 'RaohaneUtils\.clampInt' "$selection" \
  || fail 'selection model lost helper contract'

# The active startup/UI graph must resolve only Raohane-owned framework.
for retired_path in modules/common modules/ii services GlobalStates.qml; do
  [[ ! -e "$retired_path" ]] || fail "retired compatibility path returned: $retired_path"
done
[[ ! -e modules/raohane/RaohaneLegacyBridge.qml ]] \
  || fail 'compatibility config bridge returned to active source'

if rg -n \
  '^import qs\.modules\.common|^import qs\.modules\.ii|^import qs\.services$|\bGlobalStates\.|\bRaohaneLegacyBridge\b|\.\./ii/|modules/common|modules/ii' \
  modules/raohane panelFamilies/RaohaneFamily.qml shell.qml; then
  fail 'active Raohane UI/framework can resolve compatibility/common code'
fi
if rg -n 'IllogicalImpulse|illogical-impulse|end4-pC' "$family" shell.qml; then
  fail 'startup graph contains upstream family/runtime identity'
fi

printf 'phase3-core-framework-audit: complete config, owned paths/widgets/models/helpers and compatibility-free active UI are valid\n'
