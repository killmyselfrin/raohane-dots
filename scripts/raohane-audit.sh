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
  scripts/raohane
  scripts/raohane-audit.sh
  scripts/service-boundary-audit.sh
  scripts/install-deps.sh
  install-raohane.sh
  install/arch/required.txt
  install/arch/features.txt
)
for path in "${required_root[@]}"; do
  [[ -e "$path" ]] || fail "required project path is missing: $path"
done

required_native=(
  modules/raohane/RaohaneTheme.qml
  modules/raohane/RaohaneState.qml
  modules/raohane/RaohanePrivacy.qml
  modules/raohane/RaohaneContext.qml
  modules/raohane/RaohaneLegacyBridge.qml
  modules/raohane/RaohaneBackground.qml
  modules/raohane/RaohaneDesktopCanvas.qml
  modules/raohane/RaohaneOverview.qml
  modules/raohane/RaohaneDock.qml
  modules/raohane/RaohaneContextIsland.qml
  modules/raohane/RaohaneBar.qml
  modules/raohane/RaohaneLauncher.qml
  modules/raohane/RaohaneControlCenter.qml
  modules/raohane/RaohaneQuickControls.qml
  modules/raohane/RaohaneNotificationCard.qml
  modules/raohane/RaohaneNotificationCenter.qml
  modules/raohane/RaohaneSettings.qml
  modules/raohane/RaohaneSettingsContent.qml
  modules/raohane/RaohaneSettingsHome.qml
  modules/raohane/RaohaneMediaOverlay.qml
  modules/raohane/RaohaneOsd.qml
  modules/raohane/RaohaneNotificationPopup.qml
  modules/raohane/RaohaneWallpaperSelector.qml
  modules/raohane/RaohaneDesktopMenu.qml
  modules/raohane/RaohaneSessionScreen.qml
  modules/raohane/config/RaohaneConfig.qml
  modules/raohane/services/RaohaneMedia.qml
  modules/raohane/services/RaohaneBluetooth.qml
  modules/raohane/services/RaohaneAudio.qml
  modules/raohane/services/RaohaneNetwork.qml
  modules/raohane/services/RaohaneDisplay.qml
  modules/raohane/services/RaohaneNotifications.qml
  modules/raohane/services/RaohaneWallpapers.qml
  modules/raohane/services/RaohaneSearch.qml
  modules/raohane/services/RaohaneSession.qml
  modules/raohane/services/RaohaneSessionWarnings.qml
  modules/raohane/services/RaohaneSystemInfo.qml
)
for path in "${required_native[@]}"; do
  [[ -f "$path" ]] || fail "required Raohane-owned file is missing: $path"
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

for surface in RaohaneBackground RaohaneDesktopCanvas RaohaneOverview RaohaneDock RaohaneBar RaohaneLauncher RaohaneControlCenter RaohaneSettings RaohaneMediaOverlay RaohaneOsd RaohaneNotificationPopup RaohaneWallpaperSelector RaohaneDesktopMenu RaohaneSessionScreen; do
  rg -q "component: ${surface} \{\}" panelFamilies/RaohaneFamily.qml \
    || fail "RaohaneFamily does not load $surface"
done

rg -q '^singleton RaohanePrivacy .*RaohanePrivacy.qml$' modules/raohane/qmldir || fail 'RaohanePrivacy is not registered'
rg -q '^singleton RaohaneLegacyBridge .*RaohaneLegacyBridge.qml$' modules/raohane/qmldir || fail 'RaohaneLegacyBridge is not registered'
rg -q '^singleton RaohaneConfig .*RaohaneConfig.qml$' modules/raohane/config/qmldir || fail 'RaohaneConfig is not registered'
rg -q 'RaohaneLegacyBridge\.load' panelFamilies/RaohaneFamily.qml || fail 'RaohaneFamily does not initialize the temporary config bridge'

if rg -n '^import qs\.modules\.ii\.background$|component: Background \{\}' panelFamilies/RaohaneFamily.qml; then
  fail 'RaohaneFamily regressed to the inherited background renderer'
fi
rg -q 'RaohaneWallpapers\.' modules/raohane/RaohaneBackground.qml || fail 'RaohaneBackground does not consume the native wallpaper service'
rg -q 'RaohaneConfig\.wallpaper' modules/raohane/RaohaneBackground.qml || fail 'RaohaneBackground does not consume native wallpaper settings'
if rg -n '\bConfig\.|\bWallpapers\.|\bAppearance\.' modules/raohane/RaohaneBackground.qml; then
  fail 'RaohaneBackground consumes inherited wallpaper/theme state'
fi
rg -q 'RaohaneContext\.' modules/raohane/RaohaneDesktopCanvas.qml || fail 'RaohaneDesktopCanvas is not connected to living context state'

if rg -n '^import qs\.modules\.ii\.overview$|component: Overview \{\}' panelFamilies/RaohaneFamily.qml; then
  fail 'RaohaneFamily regressed to the inherited overview'
fi
for symbol in 'Hyprland\.workspaces' 'RaohaneState\.overviewOpen' 'RaohaneConfig\.overview'; do
  rg -q "$symbol" modules/raohane/RaohaneOverview.qml || fail "RaohaneOverview lost required native workspace dependency: $symbol"
done
if rg -n 'NiriOverview|OverviewWidget|LauncherSearch|GlobalStates\.overviewOpen|\bConfig\.' modules/raohane/RaohaneOverview.qml; then
  fail 'RaohaneOverview regressed to inherited overview/search state'
fi
rg -q 'name: "overviewWorkspacesToggle"' modules/raohane/RaohaneOverview.qml || fail 'RaohaneOverview lost compatibility workspace shortcut'
rg -q 'target: "search"' modules/raohane/RaohaneOverview.qml || fail 'RaohaneOverview lost compatibility search IPC target'

if rg -n '^import qs\.modules\.ii\.dock$|component: Dock \{\}' panelFamilies/RaohaneFamily.qml; then
  fail 'RaohaneFamily regressed to the inherited dock'
fi
for symbol in 'ToplevelManager\.toplevels' 'DesktopEntries\.' 'RaohaneConfig\.dock'; do
  rg -q "$symbol" modules/raohane/RaohaneDock.qml || fail "RaohaneDock lost required native dependency: $symbol"
done
if rg -n 'TaskbarApps|AppSearch|MprisController|\bAppearance\.|\bConfig\.|qs\.modules\.ii' modules/raohane/RaohaneDock.qml; then
  fail 'RaohaneDock regressed to inherited dock/taskbar plumbing'
fi
rg -q '\.activate\(\)' modules/raohane/RaohaneDock.qml || fail 'RaohaneDock cannot activate native toplevels'
rg -q '\.close\(\)' modules/raohane/RaohaneDock.qml || fail 'RaohaneDock cannot close native toplevels'
rg -q 'RaohaneMedia\.' modules/raohane/RaohaneDock.qml || fail 'RaohaneDock media affordance does not use RaohaneMedia'
rg -q 'RaohaneState\.overviewOpen' modules/raohane/RaohaneDock.qml || fail 'RaohaneDock Spaces button is not connected to native overview state'

if rg -n '^import qs\.modules\.ii\.mediaControls$|component: MediaControls \{\}' panelFamilies/RaohaneFamily.qml; then
  fail 'RaohaneFamily regressed to inherited MediaControls'
fi
for symbol in 'RaohaneMedia\.' 'target: "raohaneMedia"' 'target: "mediaControls"' 'name: "mediaControlsToggle"' 'name: "mediaControlsOpen"' 'name: "mediaControlsClose"'; do
  rg -q "$symbol" modules/raohane/RaohaneMediaOverlay.qml || fail "RaohaneMediaOverlay lost required media compatibility/native contract: $symbol"
done
if rg -n '^import qs$|qs\.modules\.common|MprisController|\bWM\.|\bConfig\.|\bAppearance\.' modules/raohane/RaohaneMediaOverlay.qml; then
  fail 'RaohaneMediaOverlay regressed to inherited media/common plumbing'
fi

if rg -n '^import qs\.modules\.ii\.sidebarRight' modules/raohane/RaohaneControlCenter.qml; then
  fail 'Control Center regressed to compatibility sidebar UI'
fi
if rg -n '^import qs\.modules\.ii\.settings$' modules/raohane/RaohaneSettings.qml; then
  fail 'Settings regressed to compatibility settings shell'
fi
if rg -n '^import qs\.modules\.ii\.(wallpaperSelector|desktopMenu|sessionScreen)' panelFamilies/RaohaneFamily.qml; then
  fail 'RaohaneFamily regressed to compatibility desktop/session entry points'
fi

rg -q 'RaohaneSearch\.' modules/raohane/RaohaneLauncher.qml || fail 'Launcher is not consuming RaohaneSearch'
if rg -n 'LauncherSearch|LauncherSearchResult|AppSearch' modules/raohane/RaohaneLauncher.qml; then
  fail 'Launcher regressed to inherited search plumbing'
fi

rg -q 'import Quickshell.Hyprland' shell.qml || fail 'shell.qml no longer declares Hyprland integration'
if rg -n -i 'inir|\bniri\b|waffle|ricelin' modules/raohane shell.qml panelFamilies/RaohaneFamily.qml; then
  fail 'Raohane product runtime contains a legacy/non-target compositor identity'
fi

if rg -n 'GlobalStates\.raohane[A-Za-z0-9_]+' modules/raohane panelFamilies/RaohaneFamily.qml; then
  fail 'Raohane-owned transient state leaked into GlobalStates'
fi

rg -q 'ipc raohaneLauncher toggle' scripts/raohane || fail 'launcher CLI route is missing'
rg -q 'ipc raohaneMedia toggle' scripts/raohane || fail 'media CLI route is missing'
rg -q 'ipc raohaneDesktop toggle' scripts/raohane || fail 'desktop CLI route is missing'
rg -q 'ipc wallpaperSelector toggle' scripts/raohane || fail 'wallpaper CLI route is missing'
rg -q 'ipc session toggle' scripts/raohane || fail 'session CLI route is missing'

rg -q 'scripts/install-deps\.sh' install-raohane.sh || fail 'main installer is not using the Raohane dependency installer'
if rg -n 'install-foundation-deps|sync-end4-foundation|git[[:space:]]+clone' install-raohane.sh scripts/install-deps.sh scripts/raohane; then
  fail 'normal install/doctor path executes upstream shell infrastructure'
fi

if rg -n -i 'illogical-impulse|\bniri\b' scripts/videos/record.sh; then
  fail 'screen recorder contains a legacy shell/compositor dependency'
fi
rg -q 'raohane/config\.json' scripts/videos/record.sh || fail 'screen recorder is not reading the Raohane config namespace'

bash -n scripts/raohane
bash -n scripts/raohane-audit.sh
bash -n scripts/service-boundary-audit.sh
bash -n scripts/install-deps.sh
bash -n scripts/videos/record.sh
bash -n install-raohane.sh

printf 'raohane-audit: native desktop/overview/dock/media, product graph, installation and config boundaries are valid\n'
