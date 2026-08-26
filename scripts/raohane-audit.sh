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
[[ -f scripts/install-deps.sh ]] || fail 'Raohane dependency installer is missing'
[[ -f install/arch/required.txt ]] || fail 'Raohane required package manifest is missing'
[[ -f install/arch/features.txt ]] || fail 'Raohane feature package manifest is missing'

required_native=(
  modules/raohane/RaohaneTheme.qml
  modules/raohane/RaohaneState.qml
  modules/raohane/RaohanePrivacy.qml
  modules/raohane/RaohaneContext.qml
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
  modules/raohane/services/RaohaneMedia.qml
)

for path in "${required_native[@]}"; do
  [[ -f "$path" ]] || fail "required native surface/service is missing: $path"
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

for surface in RaohaneBar RaohaneLauncher RaohaneControlCenter RaohaneSettings RaohaneMediaOverlay RaohaneOsd RaohaneNotificationPopup RaohaneWallpaperSelector RaohaneDesktopMenu RaohaneSessionScreen; do
  rg -q "component: ${surface} \{\}" panelFamilies/RaohaneFamily.qml \
    || fail "RaohaneFamily does not load $surface"
done

rg -q '^singleton RaohanePrivacy .*RaohanePrivacy.qml$' modules/raohane/qmldir \
  || fail 'RaohanePrivacy is not registered as a singleton'
rg -q 'RaohanePrivacy\.(recordingActive|microphoneActive|cameraActive)' modules/raohane/RaohaneContext.qml \
  || fail 'Context Island is not wired to the privacy provider'

rg -q '^singleton RaohaneMedia .*RaohaneMedia.qml$' modules/raohane/services/qmldir \
  || fail 'RaohaneMedia is not registered as a Raohane service singleton'
rg -q 'Quickshell.Services.Mpris' modules/raohane/services/RaohaneMedia.qml \
  || fail 'RaohaneMedia is not backed directly by Quickshell MPRIS'
rg -q 'RaohaneMedia\.' modules/raohane/RaohaneContext.qml \
  || fail 'Context Island is not consuming the Raohane media service'
rg -q 'RaohaneMedia\.' modules/raohane/RaohaneMediaOverlay.qml \
  || fail 'Media overlay is not consuming the Raohane media service'
if rg -n 'MprisController' modules/raohane/RaohaneContext.qml modules/raohane/RaohaneMediaOverlay.qml; then
  fail 'Active Raohane media surfaces regressed to inherited MprisController'
fi

rg -q 'RaohaneQuickControls' modules/raohane/RaohaneControlCenter.qml \
  || fail 'Control Center is not using Raohane quick controls'
rg -q 'RaohaneNotificationCenter' modules/raohane/RaohaneControlCenter.qml \
  || fail 'Control Center is not using the Raohane notification center'
if rg -n '^import qs\.modules\.ii\.sidebarRight' modules/raohane/RaohaneControlCenter.qml; then
  fail 'Control Center regressed to the compatibility sidebar UI'
fi

rg -q 'RaohaneSettingsContent' modules/raohane/RaohaneSettings.qml \
  || fail 'Settings is not using the Raohane navigation shell'
rg -q 'RaohaneSettingsHome.qml' modules/raohane/RaohaneSettingsContent.qml \
  || fail 'Settings Control Deck is not the Raohane landing page'
if rg -n '^import qs\.modules\.ii\.settings$' modules/raohane/RaohaneSettings.qml; then
  fail 'Settings regressed to the compatibility settings shell'
fi
rg -q 'Directories\.shellConfigPath' modules/raohane/RaohaneSettingsContent.qml \
  || fail 'Settings no longer exposes the Raohane config path'
rg -q 'HyprlandConfig.qml' modules/raohane/RaohaneSettingsContent.qml \
  || fail 'Hyprland settings page is missing from Raohane settings navigation'
if rg -n 'NiriConfig.qml' modules/raohane/RaohaneSettingsContent.qml; then
  fail 'Non-target compositor settings leaked into Raohane settings navigation'
fi
if rg -n '\bjq\b' modules/raohane/RaohaneQuickControls.qml; then
  fail 'Raohane quick controls unexpectedly depend on jq'
fi

rg -q 'target: "wallpaperSelector"' modules/raohane/RaohaneWallpaperSelector.qml \
  || fail 'Native wallpaper selector did not preserve the wallpaperSelector IPC target'
rg -q 'Wallpapers\.randomFromCurrentFolder' modules/raohane/RaohaneWallpaperSelector.qml \
  || fail 'Native wallpaper selector lost random wallpaper support'
rg -q 'GlobalStates\.wallpaperSelectorTarget' modules/raohane/RaohaneWallpaperSelector.qml \
  || fail 'Native wallpaper selector lost desktop/lock target handling'
rg -q 'target: "raohaneDesktop"' modules/raohane/RaohaneDesktopMenu.qml \
  || fail 'Native desktop menu IPC is missing'
rg -q 'target: "session"' modules/raohane/RaohaneSessionScreen.qml \
  || fail 'Native session screen did not preserve the session IPC target'
rg -q 'SessionWarnings\.refresh' modules/raohane/RaohaneSessionScreen.qml \
  || fail 'Native session screen lost package/download warning refresh'
rg -q 'pendingAction' modules/raohane/RaohaneSessionScreen.qml \
  || fail 'Native session screen lost destructive-action confirmation state'
if rg -n '^import qs\.modules\.ii\.(wallpaperSelector|desktopMenu|sessionScreen)' panelFamilies/RaohaneFamily.qml; then
  fail 'RaohaneFamily regressed to compatibility desktop/session entry points'
fi

rg -q 'ipc raohaneLauncher toggle' scripts/raohane \
  || fail 'raohane launcher is not routed to the native launcher IPC'
rg -q 'ipc raohaneMedia toggle' scripts/raohane \
  || fail 'raohane media is not routed to the native media IPC'
rg -q 'ipc raohaneDesktop toggle' scripts/raohane \
  || fail 'raohane desktop is not routed to the native desktop IPC'
rg -q 'ipc wallpaperSelector toggle' scripts/raohane \
  || fail 'raohane wallpaper is not routed to the native wallpaper IPC'
rg -q 'ipc wallpaperSelector random' scripts/raohane \
  || fail 'raohane wallpaper random is not routed to the wallpaper IPC'
rg -q 'ipc session toggle' scripts/raohane \
  || fail 'raohane session is not routed to the native session IPC'

# Standalone install boundary: the normal installer and doctor may only use
# Raohane-owned manifests/scripts. Legacy migration is explicit and config-only.
rg -q 'scripts/install-deps\.sh' install-raohane.sh \
  || fail 'main installer is not using the Raohane dependency installer'
if rg -n 'install-foundation-deps|sync-end4-foundation|git[[:space:]]+clone' install-raohane.sh scripts/install-deps.sh scripts/raohane; then
  fail 'normal install/doctor path still executes upstream shell infrastructure'
fi
if rg -n -i 'illogical-impulse|\bniri\b' scripts/videos/record.sh; then
  fail 'screen recorder still contains a legacy shell/compositor dependency'
fi
rg -q 'config/raohane/config\.json' scripts/videos/record.sh \
  || fail 'screen recorder is not reading the Raohane config namespace'

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
bash -n scripts/raohane-audit.sh
bash -n scripts/install-deps.sh
bash -n scripts/videos/record.sh
bash -n scripts/sync-end4-foundation.sh
bash -n scripts/install-foundation-deps.sh
bash -n install-raohane.sh

printf 'raohane-audit: standalone boundaries and primary QML graph are structurally valid\n'
