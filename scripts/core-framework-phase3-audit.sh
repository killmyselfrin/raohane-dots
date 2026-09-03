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
state='modules/raohane/RaohaneState.qml'
surface_registry='modules/raohane/RaohaneSurfaceRegistry.qml'
settings_registry='modules/raohane/RaohaneSettingsPageRegistry.qml'
settings_section_registry='modules/raohane/RaohaneSettingsSectionRegistry.qml'
settings_router='modules/raohane/RaohaneSettingsRouter.qml'
settings_navigation='modules/raohane/RaohaneSettingsNavigation.qml'
settings_header='modules/raohane/RaohaneSettingsPageHeader.qml'
settings_content='modules/raohane/RaohaneSettingsContentV3.qml'
settings_section='modules/raohane/RaohaneSettingsSectionPage.qml'
settings_control='modules/raohane/RaohaneSettingsControlRow.qml'
settings_preferences='modules/raohane/RaohaneSettingsPreferences.qml'
settings_language='modules/raohane/RaohaneSettingsLanguage.qml'
settings_search='modules/raohane/RaohaneSettingsSearch.qml'
helper_qmldir='modules/raohane/helpers/qmldir'
helpers='modules/raohane/helpers/RaohaneUtils.qml'
model_qmldir='modules/raohane/models/qmldir'
selection='modules/raohane/models/RaohaneSelectionModel.qml'
launcher='modules/raohane/RaohaneLauncher.qml'
notifications='modules/raohane/services/RaohaneNotifications.qml'
family='panelFamilies/RaohaneFamily.qml'

required=(
  "$config" "$paths" "$root_qmldir" "$state" "$surface_registry"
  "$settings_registry" "$settings_section_registry" "$settings_router" "$settings_navigation" "$settings_header"
  "$settings_content" "$settings_section" "$settings_control" "$settings_preferences" "$settings_language" "$settings_search"
  "$helper_qmldir" "$helpers" "$model_qmldir" "$selection" "$launcher" "$notifications" "$family"
  modules/raohane/RaohaneSurface.qml modules/raohane/RaohaneDivider.qml modules/raohane/RaohaneIconButton.qml
)
for path in "${required[@]}"; do
  [[ -f "$path" ]] || fail "missing Phase 3 framework file: $path"
done

product_properties=(
  wallpaperPath lockWallpaperPath wallpaperDirectory wallpaperPreview wallpaperColumns
  wallpaperChangeInterval wallpaperHideWhenFullscreen wallpaperTransitionDuration wallpaperDim lockWallpaperDim
  overviewWorkspaceCount overviewColumns dockEnabled dockAutoHide dockPinned dockExclusiveZone dockHeight dockIconSize
  dockBottomMargin dockPinnedApps barBottom barVertical barAutoHide barAutoHidePushWindows barShowOnSuper
  barShowOnSuperDelay barScreenList barShowDate frameEnabled frameThickness frameColor frameBarSideVisible
  screenRoundingMode screenCornerRadius deadPixelWorkaround hotCornersEnabled hotCornerValueScroll hotCornerClickless
  hotCornerRegionWidth hotCornerRegionHeight hotCornerBottomLeftAction hotCornerBottomRightAction hotCornerVisualize
  hotCornerClicklessEnd hotCornerVerticalOffset oskPinned oskLayout osdTimeout colorTemperature nightLightAutomatic
  networkCommand networkEthernetCommand bluetoothCommand taskManagerCommand changePasswordCommand
  profileDisplayName profileAvatarPath quickSliderBrightness quickSliderVolume quickSliderMic
  desktopWidgetsEnabled desktopWidgetClock desktopWidgetContext desktopWidgetSystem desktopWidgetMotto desktopWidgetsCompact
  contextIslandEnabled mediaOverlayEnabled integrationMode themePreset
)
for property_name in "${product_properties[@]}"; do
  rg -q "property [^:]+ ${property_name}:" "$config" || fail "complete product schema lost property: $property_name"
  rg -q "on${property_name^}Changed:[[:space:]]*scheduleSave\(\)" "$config" || fail "persisted property lost save handler: $property_name"
done

mapfile -t settings_keys < <(rg -o 'type:[[:space:]]*"(toggle|number|text)",[[:space:]]*key:[[:space:]]*"[A-Za-z0-9_]+"' "$settings_registry" \
  | sed -E 's/.*key:[[:space:]]*"([A-Za-z0-9_]+)"/\1/' | sort -u)
[[ "${#settings_keys[@]}" -gt 0 ]] || fail 'could not discover native Settings control keys from registry'
for key in "${settings_keys[@]}"; do
  rg -q "property [^:]+ ${key}:" "$config" || fail "Settings registry control key is not owned by RaohaneConfig: $key"
done

for section_name in wallpaper overview dock bar frame corners osk osd display apps profile quickControls desktopWidgets features; do
  rg -q "${section_name}:[[:space:]]*\{" "$config" || fail "snapshot lost product section: $section_name"
done
rg -q 'schemaVersion:[[:space:]]*12' "$config" || fail 'RaohaneConfig schema contract is not v12'
rg -q 'themePreset:[[:space:]]*root\.themePreset' "$config" || fail 'theme selection is not persisted in native config'
rg -q 'RaohanePaths\.nativeConfigFile' "$config" || fail 'RaohaneConfig bypasses RaohanePaths'

for symbol in \
  'configDirectory' 'nativeConfigFile' 'autostartFile' 'notificationsFile' 'stateDirectory' 'cacheDirectory' \
  'wallpaperCacheDirectory' 'thumbnailDirectory' 'coverArtDirectory' 'runtimeDirectory' 'captureTempDirectory' \
  'screenshotTempDirectory' 'screenshotsDirectory' 'recordingsDirectory' 'shellDirectory' 'assetsPath' 'scriptsPath' 'defaultsPath' 'fileUrl'; do
  rg -q "$symbol" "$paths" || fail "RaohanePaths lost owned path API: $symbol"
done
if rg -n 'compatibilityConfigFile|illogical-impulse|modules/common|modules/ii' "$paths"; then
  fail 'RaohanePaths exposes compatibility/upstream paths'
fi
rg -q 'RaohanePaths\.notificationsFile' "$notifications" || fail 'notification persistence bypasses RaohanePaths'

for registration in \
  '^RaohaneSurface .*RaohaneSurface.qml$' '^RaohaneDivider .*RaohaneDivider.qml$' '^RaohaneIconButton .*RaohaneIconButton.qml$' \
  '^singleton RaohaneSurfaceRegistry .*RaohaneSurfaceRegistry.qml$' \
  '^singleton RaohaneSettingsPageRegistry .*RaohaneSettingsPageRegistry.qml$' \
  '^singleton RaohaneSettingsSectionRegistry .*RaohaneSettingsSectionRegistry.qml$' \
  '^singleton RaohaneSettingsRouter .*RaohaneSettingsRouter.qml$' \
  '^RaohaneSettingsNavigation .*RaohaneSettingsNavigation.qml$' '^RaohaneSettingsPageHeader .*RaohaneSettingsPageHeader.qml$' \
  '^RaohaneSettingsSectionPage .*RaohaneSettingsSectionPage.qml$' '^RaohaneSettingsControlRow .*RaohaneSettingsControlRow.qml$' \
  '^RaohaneSettingsPreferences .*RaohaneSettingsPreferences.qml$' '^RaohaneSettingsLanguage .*RaohaneSettingsLanguage.qml$'; do
  rg -q "$registration" "$root_qmldir" || fail "missing native framework registration: $registration"
done
rg -q 'RaohaneSurface[[:space:]]*\{' "$launcher" || fail 'active Launcher is not consuming Raohane common widgets'

for surface_id in launcher wallpaper overview controlCenter leftSidebar overlay screenTranslator settings displaySettings welcome session taskManager desktopMenu mediaOverlay regionSelector osk osd; do
  rg -q "\"${surface_id}\"[[:space:]]*:" "$surface_registry" || fail "surface registry lost product surface: $surface_id"
done
for contract in primarySurfaceIds transientSurfaceIds actionAliases normalizeId definition stateProperty isPrimary isTransient; do
  rg -q "$contract" "$surface_registry" || fail "surface registry lost contract: $contract"
done
for consumer in surfaceOpen setSurfaceOpen toggleSurface closePrimarySurfaces closeTransientSurfaces; do
  rg -q "$consumer" "$state" || fail "RaohaneState lost registry-backed API: $consumer"
done
if rg -n 'case[[:space:]]+"(launcher|wallpaper|overview|controlCenter|settings|session|desktopMenu)"' "$state"; then
  fail 'RaohaneState regressed to duplicated primary-surface switch tables'
fi

for contract in pages aliases routeAliases resolvePageIndex resolveRoute sectionEntries searchEntries; do
  rg -q "$contract" "$settings_registry" || fail "Settings page registry lost contract: $contract"
done
for page_key in preferences backup language; do
  rg -q "key:[[:space:]]*\"${page_key}\"" "$settings_registry" || fail "Settings page registry lost unified page: $page_key"
done
for contract in extensions extension source ownsControl; do
  rg -q "$contract" "$settings_section_registry" || fail "Settings section registry lost contract: $contract"
done
for contract in splitRoute request requestSearch pageRequested; do
  rg -q "$contract" "$settings_router" || fail "Settings router lost framework contract: $contract"
done
rg -q 'RaohaneSettingsPageRegistry\.resolveRoute' "$settings_router" || fail 'Settings router bypasses registry route resolution'
if rg -n 'specialAliases|preferencesRequested|backupRequested|languageRequested' "$settings_router"; then
  fail 'Settings router reintroduced special route transport'
fi
rg -q 'target:[[:space:]]*RaohaneSettingsRouter' "$settings_content" || fail 'Settings coordinator does not consume the Settings router'
rg -q 'pageOwnsHeader' "$settings_content" || fail 'Settings coordinator lost page-owned-header contract'
rg -q 'RaohaneSettingsRouter\.requestSearch' "$settings_search" || fail 'Settings search bypasses Settings router'
rg -q 'RaohaneSettingsPageRegistry\.isFirstInGroup' "$settings_navigation" || fail 'Settings navigation bypasses registry groups'
rg -q 'RaohaneConfig\.profileDisplayName' "$settings_navigation" || fail 'Settings navigation lost profile ownership'
rg -q 'root\.pageInfo\?\.name' "$settings_header" || fail 'Settings page header lost page metadata ownership'
rg -q 'RaohaneSettingsSectionRegistry\.source' "$settings_section" || fail 'generic Settings section does not consume extension registry'
rg -q 'RaohaneSettingsControlRow[[:space:]]*\{' "$settings_section" || fail 'generic Settings section does not compose reusable control rows'
rg -q 'RaohaneConfig\[' "$settings_control" || fail 'Settings control row lost native config binding ownership'
rg -q 'RaohanePreferencesHub[[:space:]]*\{' "$settings_preferences" || fail 'unified preferences page lost PreferencesHub'
rg -q 'RaohaneI18n\.supportedLanguages' "$settings_language" || fail 'unified language page lost language source'
if rg -n 'RaohaneBarStudio[[:space:]]*\{|sectionKey[[:space:]]*===?[[:space:]]*"bar"' "$settings_section"; then
  fail 'generic Settings section reabsorbed Bar Studio-specific ownership'
fi

rg -q '^module qs\.modules\.raohane\.models$' "$model_qmldir" || fail 'native models module is not declared'
rg -q '^RaohaneSelectionModel .*RaohaneSelectionModel.qml$' "$model_qmldir" || fail 'selection model is not registered'
rg -q '^module qs\.modules\.raohane\.helpers$' "$helper_qmldir" || fail 'native helpers module is not declared'
rg -q '^singleton RaohaneUtils .*RaohaneUtils.qml$' "$helper_qmldir" || fail 'RaohaneUtils is not registered'
rg -q '^import qs\.modules\.raohane\.models$' "$launcher" || fail 'active Launcher does not consume native models'
rg -q 'RaohaneUtils\.clampInt' "$selection" || fail 'selection model lost helper contract'

for retired_path in modules/common modules/ii services GlobalStates.qml; do
  [[ ! -e "$retired_path" ]] || fail "retired compatibility path returned: $retired_path"
done
[[ ! -e modules/raohane/RaohaneLegacyBridge.qml ]] || fail 'compatibility config bridge returned to active source'
if rg -n '^import qs\.modules\.common|^import qs\.modules\.ii|^import qs\.services$|\bGlobalStates\.|\bRaohaneLegacyBridge\b|\.\./ii/|modules/common|modules/ii' \
  modules/raohane panelFamilies/RaohaneFamily.qml shell.qml; then
  fail 'active Raohane UI/framework can resolve compatibility/common code'
fi
if rg -n 'IllogicalImpulse|illogical-impulse|end4-pC' "$family" shell.qml; then
  fail 'startup graph contains upstream family/runtime identity'
fi

printf 'phase3-core-framework-audit: complete config, owned paths/widgets/models/helpers/surface registries and a unified registry-routed Settings workspace are valid\n'
