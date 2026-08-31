#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'ui-polish-audit: %s\n' "$*" >&2
  exit 1
}

sidebar='modules/raohane/RaohaneSidebarLeft.qml'
systray='modules/raohane/RaohaneSysTray.qml'
about='modules/raohane/RaohaneSettingsAbout.qml'
desktop='modules/raohane/RaohaneDesktopCanvas.qml'
workspaces='modules/raohane/RaohaneWorkspaces.qml'
settings='modules/raohane/RaohaneSettings.qml'
settings_v2='modules/raohane/RaohaneSettingsContentV2.qml'
settings_search='modules/raohane/RaohaneSettingsSearch.qml'
control='modules/raohane/RaohaneControlCenter.qml'
quick='modules/raohane/RaohaneQuickControls.qml'
notifications='modules/raohane/RaohaneNotificationCenter.qml'
osd='modules/raohane/RaohaneOsd.qml'

for file in "$sidebar" "$systray" "$about" "$desktop" "$workspaces" "$settings" "$settings_v2" "$settings_search" "$control" "$quick" "$notifications" "$osd"; do
  [[ -f "$file" ]] || fail "missing polished UI surface: $file"
done

rg -q 'RaohaneSlider[[:space:]]*\{' "$sidebar" || fail 'Sidebar regressed from the shared slider'
rg -q 'RaohaneIconButton[[:space:]]*\{' "$sidebar" || fail 'Sidebar regressed from shared icon buttons'
rg -q 'RaohaneMotion\.' "$sidebar" || fail 'Sidebar lost shared motion'
if rg -n 'component[[:space:]]+(IconControl|ActionButton):|#24ffffff' "$sidebar"; then
  fail 'Sidebar reintroduced retired local controls or hover colors'
fi

rg -q 'delegate:[[:space:]]*RaohaneSurface[[:space:]]*\{' "$systray" || fail 'System tray no longer uses shared item surfaces'
rg -q 'RaohaneMotion\.' "$systray" || fail 'System tray lost shared tactile motion'
if rg -n '#24ffffff' "$systray"; then
  fail 'System tray reintroduced the retired white hover color'
fi

rg -q 'RaohaneSurface[[:space:]]*\{' "$about" || fail 'Settings About no longer uses shared surfaces'
rg -q 'RaohaneMotion\.' "$about" || fail 'Settings About controls lost shared motion'
rg -q 'RaohaneIcon[[:space:]]*\{' "$about" || fail 'Settings About lost Material-symbol iconography'
if rg -n 'text:[[:space:]]*"ラ"|#79191523|#61171320|#5c17141f|#4c17141f|#20ffffff|#18ffffff|#1cffffff' "$about"; then
  fail 'Settings About reintroduced retired prototype chrome'
fi

rg -q 'RaohaneMotion\.' "$desktop" || fail 'Desktop canvas no longer follows the shared motion scale'
rg -q 'text:[[:space:]]*RaohaneContext\.icon' "$desktop" || fail 'Desktop context icon lost its live context binding'
rg -q 'RaohaneIcon[[:space:]]*\{' "$desktop" || fail 'Desktop context no longer renders through the Material icon wrapper'
if rg -n 'duration:[[:space:]]*180' "$desktop"; then
  fail 'Desktop canvas reintroduced a fixed animation duration outside RaohaneMotion'
fi

rg -q 'delegate:[[:space:]]*RaohaneSurface[[:space:]]*\{' "$workspaces" || fail 'Workspace buttons no longer use shared surfaces'
rg -q 'RaohaneTheme\.critical' "$workspaces" || fail 'Workspace urgency no longer uses the semantic critical token'
rg -q 'RaohaneMotion\.' "$workspaces" || fail 'Workspace buttons lost shared motion'
if rg -n '#24ffffff|#ff7373|readonly property bool active:' "$workspaces"; then
  fail 'Workspace buttons reintroduced legacy colors or the RaohaneSurface active-property collision'
fi

# Control Center is one coherent panel now. Quick Controls and notifications are
# composed directly into it instead of being wrapped in another level of cards.
rg -q 'RaohaneQuickControls[[:space:]]*\{' "$control" || fail 'Control Center lost the direct Quick Controls composition'
rg -q 'RaohaneNotificationCenter[[:space:]]*\{' "$control" || fail 'Control Center lost the direct notification composition'
rg -q 'RaohaneIconButton[[:space:]]*\{' "$control" || fail 'Control Center lost shared action buttons'
rg -q 'RaohaneMotion\.(standard|enter)' "$control" || fail 'Control Center lost the shared entrance motion'
if rg -n 'shortDuration|mediumDuration|property bool active:[[:space:]]*false' "$control"; then
  fail 'Control Center reintroduced stale motion names or inherited active-state collisions'
fi

# Quick Controls deliberately use flat transparent-idle tiles and slim shared
# sliders rather than the previous card stack.
rg -q 'component QuickTile:[[:space:]]*RaohaneSurface' "$quick" || fail 'Quick Controls lost shared command-tile surfaces'
rg -q 'transparentIdle:[[:space:]]*!tile\.active' "$quick" || fail 'Quick Controls lost the flat inactive tile hierarchy'
rg -q 'RaohaneSlider[[:space:]]*\{' "$quick" || fail 'Quick Controls lost shared sliders'
rg -q 'RaohaneMotion\.' "$quick" || fail 'Quick Controls lost tactile motion'
rg -q 'RaohaneTheme\.surfaceSubtle' "$quick" || fail 'Quick Controls lost the restrained inactive state token'
rg -q 'RaohaneTheme\.borderStrong' "$quick" || fail 'Quick Controls lost explicit hover-border hierarchy'

# The active Settings window must route through V2. V2 uses one navigation rail,
# a divider and flat setting rows instead of nested card-on-card chrome.
rg -q 'RaohaneSettingsContentV2[[:space:]]*\{' "$settings" || fail 'Settings regressed from the flat V2 workspace'
rg -q 'RaohaneSettingsSearch[[:space:]]*\{' "$settings" || fail 'Settings lost integrated global search'
rg -q 'RaohaneMotion\.(standard|enter)' "$settings" || fail 'Settings lost shared window motion'
rg -q 'RaohaneSurface[[:space:]]*\{' "$settings_v2" || fail 'Settings V2 lost shared navigation surfaces'
rg -q 'RaohaneSwitch[[:space:]]*\{' "$settings_v2" || fail 'Settings V2 lost shared switches'
rg -q 'RaohaneIconButton[[:space:]]*\{' "$settings_v2" || fail 'Settings V2 lost shared number controls'
rg -q 'color:[[:space:]]*RaohaneTheme\.borderFaint' "$settings_v2" || fail 'Settings V2 lost flat divider hierarchy'
if rg -n '#76171420|#8b2b203b|#841c1826|shortDuration|mediumDuration' "$settings" "$settings_v2"; then
  fail 'Settings V2 reintroduced retired chrome or stale motion names'
fi

rg -q 'RaohaneSurface[[:space:]]*\{' "$settings_search" || fail 'Settings Search no longer uses shared surfaces'
rg -q 'RaohaneIconButton[[:space:]]*\{' "$settings_search" || fail 'Settings Search lost the shared clear button'
rg -q 'RaohaneMotion\.' "$settings_search" || fail 'Settings Search lost shared motion'

rg -q 'RaohaneMotion\.standard' "$notifications" || fail 'Notification Center lost the current shared motion token'
if rg -n 'shortDuration|mediumDuration|property bool active:[[:space:]]*false' "$notifications"; then
  fail 'Notification Center reintroduced stale motion names or inherited active-state collisions'
fi

rg -q 'id:[[:space:]]*cardTranslate' "$osd" || fail 'OSD lost its runtime-safe Translate target'
rg -q 'RaohaneMotion\.' "$osd" || fail 'OSD no longer follows shared motion'
rg -q 'RaohaneSurface[[:space:]]*\{' "$osd" || fail 'OSD lost shared surface hierarchy'
if rg -n 'RaohaneTheme\.animation(Fast|Duration|Slow)' "$osd"; then
  fail 'OSD bypasses the shared RaohaneMotion layer'
fi

printf 'ui-polish-audit: Control Center, flat Settings V2, Quick Controls, Sidebar, tray, About, desktop context, workspaces, Settings Search, notifications and OSD retain the shared Zen interaction system\n'
