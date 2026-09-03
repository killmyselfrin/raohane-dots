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
desktop_widgets='modules/raohane/RaohaneDesktopWidgets.qml'
desktop_host='modules/raohane/RaohaneDesktopWidgetHost.qml'
desktop_context='modules/raohane/RaohaneDesktopContextWidget.qml'
desktop_system='modules/raohane/RaohaneDesktopSystemWidget.qml'
workspaces='modules/raohane/RaohaneWorkspaces.qml'
settings='modules/raohane/RaohaneSettings.qml'
settings_v3='modules/raohane/RaohaneSettingsContentV3.qml'
settings_navigation='modules/raohane/RaohaneSettingsNavigation.qml'
settings_header='modules/raohane/RaohaneSettingsPageHeader.qml'
settings_registry='modules/raohane/RaohaneSettingsPageRegistry.qml'
settings_section_registry='modules/raohane/RaohaneSettingsSectionRegistry.qml'
settings_section='modules/raohane/RaohaneSettingsSectionPage.qml'
settings_control='modules/raohane/RaohaneSettingsControlRow.qml'
settings_search='modules/raohane/RaohaneSettingsSearch.qml'
control='modules/raohane/RaohaneControlCenter.qml'
quick='modules/raohane/RaohaneQuickControls.qml'
quick_tile='modules/raohane/RaohaneQuickControlTile.qml'
notifications='modules/raohane/RaohaneNotificationCenter.qml'
osd='modules/raohane/RaohaneOsd.qml'

for file in "$sidebar" "$systray" "$about" "$desktop" "$desktop_widgets" "$desktop_host" "$desktop_context" "$desktop_system" "$workspaces" "$settings" "$settings_v3" "$settings_navigation" "$settings_header" "$settings_registry" "$settings_section_registry" "$settings_section" "$settings_control" "$settings_search" "$control" "$quick" "$quick_tile" "$notifications" "$osd"; do
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

rg -q 'RaohaneMotion\.' "$desktop_widgets" || fail 'Desktop widget host no longer follows the shared motion scale'
rg -q 'RaohaneConfig\.sanitizeDesktopWidgetComposition\(RaohaneConfig\.desktopWidgetComposition\)' "$desktop_widgets" || fail 'Desktop widget host lost persisted composition ownership'
rg -q 'RaohaneDesktopWidgetRegistry\.definition' "$desktop_host" || fail 'Desktop widget loader lost registry-backed metadata'
rg -q 'RaohaneContext\.icon' "$desktop_context" || fail 'Desktop context widget lost its live context binding'
rg -q 'RaohaneIcon[[:space:]]*\{' "$desktop_context" || fail 'Desktop context widget no longer renders through Material icons'
rg -q 'RaohaneNetwork\.' "$desktop_system" || fail 'Desktop system widget lost live network status'
if rg -n 'duration:[[:space:]]*180' "$desktop" "$desktop_widgets" "$desktop_context" "$desktop_system"; then
  fail 'Desktop canvas reintroduced a fixed animation duration outside RaohaneMotion'
fi

rg -q 'component WorkspaceButton:[[:space:]]*RaohaneSurface[[:space:]]*\{' "$workspaces" || fail 'Workspace buttons no longer use the shared reusable surface component'
rg -q 'property string orientation:[[:space:]]*"horizontal"' "$workspaces" || fail 'Workspace renderer lost orientation state'
rg -q 'sourceComponent:[[:space:]]*root\.vertical[[:space:]]*\?[[:space:]]*verticalWorkspaces[[:space:]]*:[[:space:]]*horizontalWorkspaces' "$workspaces" || fail 'Workspace renderer no longer switches orientation through one loader'
rg -q 'id:[[:space:]]*horizontalWorkspaces' "$workspaces" || fail 'Workspace renderer lost horizontal composition'
rg -q 'id:[[:space:]]*verticalWorkspaces' "$workspaces" || fail 'Workspace renderer lost vertical composition'
rg -q 'verticalMode:[[:space:]]*false' "$workspaces" || fail 'Workspace renderer lost horizontal button mode'
rg -q 'verticalMode:[[:space:]]*true' "$workspaces" || fail 'Workspace renderer lost vertical button mode'
rg -q 'RaohaneTheme\.critical' "$workspaces" || fail 'Workspace urgency no longer uses the semantic critical token'
rg -q 'RaohaneMotion\.' "$workspaces" || fail 'Workspace buttons lost shared motion'
if rg -n '#24ffffff|#ff7373|readonly property bool active:' "$workspaces"; then
  fail 'Workspace buttons reintroduced legacy colors or the RaohaneSurface active-property collision'
fi

rg -q 'readonly property int panelHeight:' "$control" || fail 'Control Center lost bounded floating height'
rg -q 'implicitHeight:[[:space:]]*root\.panelHeight' "$control" || fail 'Control Center window no longer follows its floating height'
rg -q 'RaohaneQuickControls[[:space:]]*\{' "$control" || fail 'Control Center lost the direct Quick Controls composition'
rg -q 'RaohaneNotificationCenter[[:space:]]*\{' "$control" || fail 'Control Center lost the direct notification composition'
rg -q 'RaohaneIconButton[[:space:]]*\{' "$control" || fail 'Control Center lost shared action buttons'
rg -q 'RaohaneMotion\.(standard|enter)' "$control" || fail 'Control Center lost the shared entrance motion'
if rg -n 'anchors[[:space:]]*\{[^}]*bottom:[[:space:]]*true|shortDuration|mediumDuration|property bool active:[[:space:]]*false' "$control"; then
  fail 'Control Center regressed to a full-height/stale interaction contract'
fi

rg -q 'RaohaneQuickControlTile[[:space:]]*\{' "$quick" || fail 'Quick Controls host lost registry-backed command tiles'
rg -q '^RaohaneSurface[[:space:]]*\{' "$quick_tile" || fail 'Quick Control tile renderer lost shared command-tile surface'
rg -q 'transparentIdle:[[:space:]]*!root\.active[[:space:]]*&&[[:space:]]*!root\.menuOpen' "$quick_tile" || fail 'Quick Control tiles lost the flat inactive hierarchy'
rg -q 'RaohaneSlider[[:space:]]*\{' "$quick" || fail 'Quick Controls lost shared sliders'
rg -q 'RaohaneMotion\.' "$quick" || fail 'Quick Controls host lost tactile slider/picker motion'
rg -q 'RaohaneMotion\.' "$quick_tile" || fail 'Quick Control tiles lost tactile motion'
rg -q 'RaohaneTheme\.surfaceSubtle' "$quick_tile" || fail 'Quick Control tiles lost the restrained inactive state token'
rg -q 'RaohaneTheme\.borderStrong' "$quick_tile" || fail 'Quick Control tiles lost explicit hover-border hierarchy'

# Settings V3 is a coordinator around extracted navigation/header plus a
# declarative page registry. Generic section layout stays in SectionPage,
# config-bound controls live in ControlRow and concrete editors are selected by
# the section registry.
rg -q 'RaohaneSettingsContentV3[[:space:]]*\{' "$settings" || fail 'Settings regressed from the active V3 workspace'
rg -q 'RaohaneSettingsSearch[[:space:]]*\{' "$settings" || fail 'Settings lost integrated global search'
rg -q 'RaohaneMotion\.(standard|enter)' "$settings" || fail 'Settings lost shared window motion'
rg -q 'RaohaneSettingsNavigation[[:space:]]*\{' "$settings_v3" || fail 'Settings coordinator lost extracted navigation'
rg -q 'RaohaneSettingsPageHeader[[:space:]]*\{' "$settings_v3" || fail 'Settings coordinator lost extracted page header'
rg -q 'RaohaneSettingsPageRegistry\.pages' "$settings_v3" || fail 'Settings coordinator lost registry-backed navigation state'
rg -q 'source:[[:space:]]*root\.currentPageInfo\?\.source' "$settings_v3" || fail 'Settings coordinator lost declarative registry page loading'
rg -q 'text:[[:space:]]*"RAOHANE"' "$settings_navigation" || fail 'Settings navigation lost its restrained product identity'
rg -q 'text:[[:space:]]*qsTr\("System settings"\)' "$settings_navigation" || fail 'Settings navigation lost the sidebar hierarchy'
rg -q 'RaohaneTheme\.surfaceSubtle' "$settings_navigation" || fail 'Settings navigation lost the quiet sidebar plane'
rg -q 'root\.pageInfo\?\.name' "$settings_header" || fail 'Settings page header lost active page name'
rg -q 'root\.pageInfo\?\.subtitle' "$settings_header" || fail 'Settings page header lost active page subtitle'
rg -q 'source:[[:space:]]*"RaohaneSettingsSectionPage\.qml"' "$settings_registry" || fail 'Settings registry lost extracted generic section source'
rg -q 'source:[[:space:]]*"RaohaneBarStudio\.qml"' "$settings_section_registry" || fail 'Settings section registry lost Bar Studio extension ownership'
rg -q 'source:[[:space:]]*"RaohaneQuickControlsStudio\.qml"' "$settings_section_registry" || fail 'Settings section registry lost Quick Controls Studio extension ownership'
if rg -q 'function componentForKind\(|sourceComponent:|text:[[:space:]]*"RAOHANE"|RaohaneConfig\.profile' "$settings_v3"; then
  fail 'Settings coordinator reintroduced imperative routing or navigation/profile presentation'
fi
rg -q 'RaohaneSettingsControlRow[[:space:]]*\{' "$settings_section" || fail 'Settings section renderer lost reusable control-row composition'
rg -q 'RaohaneSettingsSectionRegistry\.source' "$settings_section" || fail 'Settings section renderer lost registry-backed extension loading'
rg -q 'RaohaneSwitch[[:space:]]*\{' "$settings_control" || fail 'Settings control row lost shared switches'
rg -q 'RaohaneIconButton[[:space:]]*\{' "$settings_control" || fail 'Settings control row lost shared numeric controls'
rg -q 'surfaceRadius:[[:space:]]*RaohaneTheme\.radiusLarge' "$settings_section" || fail 'Settings section renderer lost grouped native-control surface'
if rg -n 'RaohaneBarStudio[[:space:]]*\{|RaohaneQuickControlsStudio[[:space:]]*\{|sectionKey[[:space:]]*===?[[:space:]]*"(bar|quick)"' "$settings_section"; then
  fail 'Settings section renderer reabsorbed section-specific Studio logic'
fi
if rg -n '#76171420|#8b2b203b|#841c1826|shortDuration|mediumDuration|RaohaneSettingsContentV2[[:space:]]*\{' "$settings" "$settings_v3" "$settings_navigation" "$settings_header" "$settings_section" "$settings_control"; then
  fail 'Settings V3 reintroduced retired chrome, stale motion or the previous active layout'
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

printf 'ui-polish-audit: persisted registry-driven desktop widgets, floating Control Center with registry-backed tiles, coordinator-based Settings V3, shared controls, Sidebar, tray, About, workspaces, Settings Search, notifications and OSD retain the shared Zen interaction system\n'
