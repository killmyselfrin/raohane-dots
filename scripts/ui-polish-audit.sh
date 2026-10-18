#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'ui-polish-audit: %s\n' "$*" >&2
  exit 1
}

settings='modules/raohane/RaohaneSettings.qml'
settings_v3='modules/raohane/RaohaneSettingsContentV3.qml'
settings_navigation='modules/raohane/RaohaneSettingsNavigation.qml'
settings_header='modules/raohane/RaohaneSettingsPageHeader.qml'
settings_section='modules/raohane/RaohaneSettingsSectionPage.qml'
settings_control='modules/raohane/RaohaneSettingsControlRow.qml'
settings_search='modules/raohane/RaohaneSettingsSearch.qml'
settings_home='modules/raohane/RaohaneSettingsHome.qml'
settings_about='modules/raohane/RaohaneSettingsAbout.qml'
settings_graphics='modules/raohane/RaohaneSettingsGraphics.qml'
control='modules/raohane/RaohaneControlCenter.qml'
control_header='modules/raohane/RaohaneControlCenterHeader.qml'
control_footer='modules/raohane/RaohaneControlCenterFooter.qml'
control_status='modules/raohane/RaohaneControlCenterStatusStrip.qml'
control_actions='modules/raohane/RaohaneControlCenterActionDock.qml'
control_media='modules/raohane/RaohaneControlCenterMediaCard.qml'
quick='modules/raohane/RaohaneQuickControls.qml'
quick_tile='modules/raohane/RaohaneQuickControlTile.qml'
device_picker='modules/raohane/RaohaneDevicePicker.qml'
bluetooth='modules/raohane/services/RaohaneBluetooth.qml'
context='modules/raohane/RaohaneContext.qml'
context_island='modules/raohane/RaohaneContextIsland.qml'
performance='modules/raohane/services/RaohanePerformance.qml'
notifications='modules/raohane/RaohaneNotificationCenter.qml'
osd='modules/raohane/RaohaneOsd.qml'
systray='modules/raohane/RaohaneSysTray.qml'
adaptive_icon='modules/raohane/RaohaneAdaptiveIcon.qml'
icon_resolver='modules/raohane/RaohaneIconResolver.qml'
workspaces='modules/raohane/RaohaneWorkspaces.qml'
sidebar='modules/raohane/RaohaneSidebarLeft.qml'

for file in \
  "$settings" "$settings_v3" "$settings_navigation" "$settings_header" \
  "$settings_section" "$settings_control" "$settings_search" "$settings_home" "$settings_about" "$settings_graphics" \
  "$control" "$control_header" "$control_footer" "$control_status" "$control_actions" "$control_media" \
  "$quick" "$quick_tile" "$device_picker" "$bluetooth" "$context" "$context_island" "$performance" "$notifications" \
  "$osd" "$systray" "$adaptive_icon" "$icon_resolver" "$workspaces" "$sidebar"; do
  [[ -f "$file" ]] || fail "missing polished UI/runtime surface: $file"
done

# Settings is intentionally a coordinator: one moving selection rail, one
# animated page loader, one shared motion language. Do not regress to a static
# Loader.source binding or per-row active backgrounds.
rg -q 'id:[[:space:]]*selectionRail' "$settings_navigation" \
  || fail 'Settings navigation lost the moving selection rail'
rg -q 'RaohaneMotion\.selectionTravel' "$settings_navigation" \
  || fail 'Settings selection rail no longer uses shared motion'
rg -q 'function loadCurrentPage\(animated: bool\)' "$settings_v3" \
  || fail 'Settings coordinator lost animated page loading'
rg -q 'pageLoader\.source[[:space:]]*=' "$settings_v3" \
  || fail 'Settings coordinator lost programmatic page switching'
rg -q 'id:[[:space:]]*pageExit' "$settings_v3" \
  || fail 'Settings coordinator lost page exit motion'
rg -q 'id:[[:space:]]*pageEnter' "$settings_v3" \
  || fail 'Settings coordinator lost page enter motion'
rg -q 'RaohaneSettingsPageHeader[[:space:]]*\{' "$settings_v3" \
  || fail 'Settings coordinator lost the shared page header'
rg -q 'RaohaneSettingsSearch[[:space:]]*\{' "$settings" \
  || fail 'Settings lost integrated search'
rg -q 'RaohaneSettingsControlRow[[:space:]]*\{' "$settings_section" \
  || fail 'Settings sections lost reusable control rows'
rg -q 'RaohaneSwitch[[:space:]]*\{' "$settings_control" \
  || fail 'Settings control rows lost the shared switch'
if rg -n 'source:[[:space:]]*root\.currentPageInfo\?\.source|property bool active:[[:space:]]*false' \
  "$settings_v3" "$settings_navigation"; then
  fail 'Settings reintroduced a stale static-page or active-property contract'
fi

# Settings Home has one keyboard-operable route per overview row. Its
# shared cards must not crowd long machine names or animate in Gaming Mode.
for contract in \
  'width: Math.max(1, Math.min(flick.width - RaohaneTheme.spacingLarge * 2, 900))' \
  'activeFocusOnTab: true' \
  'border.width: row.activeFocus ? 1 : 0' \
  'enabled: RaohaneMotion.panelMotionEnabled && root.visible' \
  'row.forceActiveFocus()' \
  'row.triggered()' \
  'event.key === Qt.Key_Space' \
  'event.key === Qt.Key_Return' \
  'event.key === Qt.Key_Enter' \
  'row.width < 580' \
  'Layout.minimumWidth: 0' \
  'showInnerRim: true'; do
  rg -Fq "$contract" "$settings_home" \
    || fail "Settings Home lost keyboard/responsive glass contract: $contract"
done
[[ "$(rg -Fc 'showInnerRim: true' "$settings_home")" == 3 ]] \
  || fail 'Settings Home lost shared glass on its three section cards'
[[ "$(rg -Fc 'OverviewRow {' "$settings_home")" == 4 ]] \
  || fail 'Settings Home routes were added or removed unexpectedly'


# Read-only hardware metadata can be much longer than its left-hand label.
# Both specialized pages reserve label space on compact logical outputs and
# use the same subtle Raohane Flow glass material as Settings Home.
for page in "$settings_about" "$settings_graphics"; do
  for contract in \
    'Layout.minimumWidth: 0' \
    'width < 600' \
    'Math.min(180,' \
    'showSheen: true' \
    'showInnerRim: true' \
    'font.pixelSize: 10'; do
    rg -Fq "$contract" "$page" \
      || fail "Settings hardware rows lost readable layout/material: $page / $contract"
  done
done
rg -Fq 'Layout.preferredWidth: systemRow.width < 600' "$settings_about" \
  || fail 'About hardware values can crowd their labels'
rg -Fq 'Layout.preferredWidth: hardwareRow.width < 600' "$settings_graphics" \
  || fail 'Graphics hardware values can crowd their labels'


# Multiline diagnostics and graphics update descriptions must not be
# cropped or compete with update buttons at compact Settings widths.
for contract in \
  'Layout.preferredHeight: Math.max(secondary.length > 0 ? 82 : 70,' \
  'railContents.implicitHeight + RaohaneTheme.spacingSmall * 2)' \
  'id: railContents' \
  'showInnerRim: true' \
  'Layout.minimumWidth: 0' \
  'font.pixelSize: 9'; do
  rg -Fq "$contract" "$settings_about" \
    || fail "About information rail lost adaptive content height: $contract"
done
for contract in \
  'columns: root.compactLayout ? 2 : 3' \
  'Layout.row: root.compactLayout ? 1 : 0' \
  'Layout.column: root.compactLayout ? 0 : 2' \
  'Layout.columnSpan: root.compactLayout ? 2 : 1' \
  'Layout.minimumWidth: 0'; do
  rg -Fq "$contract" "$settings_graphics" \
    || fail "Graphics update controls lost compact row layout: $contract"
done


# Control Center is a wide glass dashboard with one Quick Controls path,
# dedicated media/activity panes and one action dock/device-picker owner.
rg -q 'readonly property int panelHeight:' "$control" \
  || fail 'Control Center lost bounded floating height'
# Small logical outputs must not clip the dashboard or create duplicate controls.
rg -q 'readonly property bool compactPanel:' "$control" \
  || fail 'Control Center lost compact-output layout policy'
rg -Fq 'root.screenWidth - 32' "$control" \
  || fail 'Control Center width can exceed the output again'
rg -Fq 'root.screenHeight - 32' "$control" \
  || fail 'Control Center height can exceed the output again'
rg -Fq 'Flickable {' "$control" \
  || fail 'Control Center lost overflow scrolling'
rg -Fq 'columns: root.compactPanel ? 1 : 3' "$control" \
  || fail 'Control Center lost responsive single/three column switching'
[[ "$(rg -Fc 'RaohaneQuickControls {' "$control")" == 1 ]] \
  || fail 'Control Center duplicated the live Quick Controls owner'
[[ "$(rg -Fc 'RaohaneNotificationCenter {' "$control")" == 1 ]] \
  || fail 'Control Center duplicated notification composition'
rg -q 'property bool heldVisible:[[:space:]]*false' "$control" \
  || fail 'Control Center lost animated close hold'
rg -q 'quickControls\.pickerMode[[:space:]]*=[[:space:]]*""' "$control" \
  || fail 'Control Center no longer closes device picker during dismissal'
rg -q 'event\.key[[:space:]]*!==[[:space:]]*Qt\.Key_Escape' "$control" \
  || fail 'Control Center lost Escape handling'
rg -q 'RaohaneQuickControls[[:space:]]*\{' "$control" \
  || fail 'Control Center lost Quick Controls composition'
rg -q 'tileColumns:[[:space:]]*2' "$control" \
  || fail 'Control Center lost dashboard two-column Quick Controls'
rg -q 'RaohaneNotificationCenter[[:space:]]*\{' "$control" \
  || fail 'Control Center lost notification composition'
for component in \
  RaohaneControlCenterHeader \
  RaohaneControlCenterFooter \
  RaohaneControlCenterActionDock \
  RaohaneControlCenterMediaCard; do
  rg -q "${component}[[:space:]]*\\{" "$control" \
    || fail "Control Center lost frame/content component: ${component}"
done
if rg -n 'component (HeaderButton|MediaCard):' "$control"; then
  fail 'Control Center regained inline header/media presentation'
fi

# A fixed-width header search box can squeeze the profile/time/actions off
# smaller logical outputs. Search stays actionable when its text is hidden.
for contract in \
  'readonly property bool compactHeader: root.width < 780' \
  'Layout.preferredWidth: root.compactHeader ? 36 : 210' \
  'idleBorderColor: RaohaneTheme.borderFaint' \
  'hoverBorderColor: RaohaneTheme.borderStrong' \
  'Layout.minimumWidth: 0'; do
  rg -Fq "$contract" "$control_header" \
    || fail "Control Center header lost compact glass layout: $contract"
done
[[ "$(rg -Fc 'visible: !root.compactHeader' "$control_header")" == 3 ]] \
  || fail 'Control Center header is missing compact label/date suppression'
for contract in \
  'readonly property bool compactFooter: root.width < 520' \
  'visible: !root.compactFooter && root.systemIdentity.length > 0' \
  'Layout.maximumWidth: root.width * 0.36' \
  'Layout.minimumWidth: 0' \
  'font.pixelSize: 9'; do
  rg -Fq "$contract" "$control_footer" \
    || fail "Control Center footer lost bounded compact layout: $contract"
done

# Header/footer are presentation-only and emit intents back to the coordinator.
for contract in \
  'required property string identityText' \
  'required property string timeText' \
  'required property string dateText' \
  'signal launcherRequested\(\)' \
  'signal settingsRequested\(\)' \
  'signal powerRequested\(\)'; do
  rg -q "$contract" "$control_header" \
    || fail "Control Center header lost presentation contract: ${contract}"
done
for contract in \
  'property bool privacyActive: false' \
  'property string systemIdentity: ""' \
  'signal reloadRequested\(\)' \
  'signal closeRequested\(\)'; do
  rg -q "$contract" "$control_footer" \
    || fail "Control Center footer lost presentation contract: ${contract}"
done
for contract in \
  'onLauncherRequested: panelWindow\.openSurface\("launcher"\)' \
  'onSettingsRequested: panelWindow\.openSurface\("settings"\)' \
  'onPowerRequested: panelWindow\.openSurface\("session"\)' \
  'onReloadRequested: RaohaneSession\.reloadDesktop\(\)' \
  'onCloseRequested: panelWindow\.hide\(\)'; do
  rg -q "$contract" "$control" \
    || fail "Control Center lost coordinator-owned frame action: ${contract}"
done
if rg -n 'RaohaneNotifications\.silent[[:space:]]*=[[:space:]]*!RaohaneNotifications\.silent' "$control"; then
  fail 'Control Center header regained duplicate notification-silent toggle'
fi

for signal in screenshotRequested translatorRequested oskRequested wallpaperRequested powerRequested; do
  rg -q "signal ${signal}\\(\\)" "$control_actions" \
    || fail "Control Center action dock lost signal: ${signal}"
done
for action in Screenshot Translate Keyboard Wallpaper Power; do
  rg -q "label:[[:space:]]*qsTr\\(\\\"${action}\\\"\\)" "$control_actions" \
    || fail "Control Center action dock lost ${action}"
done
if rg -q 'label:[[:space:]]*qsTr\("Performance"\)|label:[[:space:]]*qsTr\("DND"\)' "$control_actions"; then
  fail 'Control Center reintroduced duplicate system toggles in the action dock'
fi

# The action dock must allocate room for all five actions at the current
# spacing; a fixed short height used to clip the last row at 2-column widths.
for contract in \
  'readonly property bool singleColumn: root.width < 224' \
  'readonly property int actionRows: root.singleColumn ? 5 : 3' \
  'readonly property int actionHeight: 40' \
  'implicitHeight: 2 * RaohaneTheme.spacing + root.headerHeight' \
  '+ root.actionRows * root.actionHeight' \
  'columns: root.singleColumn ? 1 : 2' \
  'Layout.columnSpan: root.singleColumn ? 1 : 2' \
  'required property int actionHeight' \
  'Layout.preferredHeight: action.actionHeight' \
  'showInnerRim: true' \
  'hoverBorderColor: RaohaneTheme.borderStrong' \
  'font.pixelSize: 9'; do
  rg -Fq "$contract" "$control_actions" \
    || fail "Control Center action dock lost adaptive layout/material: $contract"
done
[[ "$(rg -Fc 'Layout.minimumWidth: 0' "$control_actions")" == 5 ]] \
  || fail 'Control Center action dock can overflow its compact columns'
[[ "$(rg -Fc 'actionHeight: root.actionHeight' "$control_actions")" == 5 ]] \
  || fail 'Action tiles lost their explicit shared height binding'
python3 - "$control_actions" <<'PY'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text()
assert source.count("ActionButton {") == 5, "action ownership has changed"
for spacing in (4, 7, 10, 16):
    for rows in (3, 5):
        height = 2 * 10 + 24 + spacing + rows * 40 + (rows - 1) * spacing
        required = 2 * 10 + 24 + spacing + rows * 40 + (rows - 1) * spacing
        assert height >= required and height > 154
PY

# Responsive status chips should not squeeze four unreadable cells into a
# narrow column; network/audio/Bluetooth actions remain coordinator-owned.
rg -Fq 'readonly property bool compact: root.width < 480' "$control_status" \
  || fail 'Control Center status strip lost compact breakpoint'
rg -Fq 'implicitHeight: root.compact ? 122 : 60' "$control_status" \
  || fail 'Control Center status strip lost two-row height'
rg -Fq 'columns: root.compact ? 2 : 4' "$control_status" \
  || fail 'Control Center status strip lost responsive columns'
rg -Fq 'rowSpacing: root.compact ? RaohaneTheme.spacingSmall : 0' "$control_status" \
  || fail 'Control Center status strip lost compact row spacing'
[[ "$(rg -Fc 'Layout.minimumWidth: 0' "$control_status")" == 4 ]] \
  || fail 'Control Center status cards can exceed allocated grid columns'
rg -Fq 'font.pixelSize: 9' "$control_status" \
  || fail 'Control Center status labels became unreadably small'
rg -Fq 'font.pixelSize: 10' "$control_status" \
  || fail 'Control Center status values became unreadably small'
for contract in \
  'onTriggered: root.networkRequested()' \
  'onTriggered: root.bluetoothRequested()' \
  'onTriggered: root.audioRequested()'; do
  rg -Fq "$contract" "$control_status" \
    || fail "Control Center status action lost: $contract"
done

# Extracted frame/status/action/media surfaces are presentation-only. System
# services and state transitions remain in the Control Center coordinator.
for presentation in "$control_header" "$control_footer" "$control_status" "$control_actions" "$control_media"; do
  if rg -n '^import qs\.modules\.raohane\.(services|config)' "$presentation"; then
    fail "$presentation imported services/config instead of staying presentation-only"
  fi
  if rg -n 'Raohane(Network|Bluetooth|Audio|Privacy|Performance|State|Session|Media|Notifications)\.' "$presentation"; then
    fail "$presentation bypasses Control Center coordinator ownership"
  fi
done
for contract in \
  'required property string networkIcon' \
  'required property string networkValue' \
  'required property string bluetoothIcon' \
  'required property string bluetoothValue' \
  'required property string audioIcon' \
  'required property string audioValue' \
  'required property string privacyValue' \
  'signal networkRequested\(\)' \
  'signal bluetoothRequested\(\)' \
  'signal audioRequested\(\)' \
  'property bool clickable: false' \
  'onClicked: status\.triggered\(\)'; do
  rg -q "$contract" "$control_status" \
    || fail "Control Center status strip lost presentation contract: ${contract}"
done

for contract in \
  'property bool mediaAvailable: false' \
  'property bool playing: false' \
  'property real progress: 0' \
  'signal openRequested\(\)' \
  'signal previousRequested\(\)' \
  'signal togglePlayingRequested\(\)' \
  'signal nextRequested\(\)' \
  'idleColor: RaohaneTheme\.surfaceSubtle' \
  'showStateRail: false'; do
  rg -q "$contract" "$control_media" \
    || fail "Control Center media card lost presentation contract: ${contract}"
done
for contract in \
  'mediaAvailable: RaohaneMedia\.available' \
  'playing: RaohaneMedia\.isPlaying' \
  'progress: RaohaneMedia\.progress' \
  'onOpenRequested: RaohaneState\.toggleSurface\("mediaOverlay"\)' \
  'onPreviousRequested: RaohaneMedia\.previous\(\)' \
  'onTogglePlayingRequested: RaohaneMedia\.togglePlaying\(\)' \
  'onNextRequested: RaohaneMedia\.next\(\)'; do
  rg -q "$contract" "$control" \
    || fail "Control Center lost coordinator-owned media binding/action: ${contract}"
done

# The media tile follows the same material/typography contract and does
# not decode artwork or expose an active click target when media is absent.
for contract in \
  'surfaceRadius: RaohaneTheme.radiusHero' \
  'idleBorderColor: RaohaneTheme.borderFaint' \
  'hoverBorderColor: RaohaneTheme.borderStrong' \
  'interactive: root.mediaAvailable' \
  'source: root.mediaAvailable && root.visible ? root.artUrl : ""' \
  'Layout.maximumWidth: root.width * 0.36' \
  'Layout.preferredHeight: visible ? 5 : 0' \
  'emphasized: root.canTogglePlaying' \
  'enabled: root.mediaAvailable'; do
  rg -Fq "$contract" "$control_media" \
    || fail "Control Center media card lost the Raohane Flow contract: $contract"
done
[[ "$(rg -Fc 'font.pixelSize: 9' "$control_media")" == 4 ]] \
  || fail 'Control Center media metadata lost readable 9px labels'
rg -Fq 'font.pixelSize: 10' "$control_media" \
  || fail 'Control Center media subtitle became unreadable'
rg -Fq 'font.pixelSize: 13' "$control_media" \
  || fail 'Control Center media title became unreadable'


# Notifications remain readable at rest, and entry fades honor the shared
# low-motion and Gaming Mode policy, including hidden Control Center panels.
for contract in \
  'surfaceRadius: RaohaneTheme.radiusHero' \
  'idleBorderColor: RaohaneTheme.borderFaint' \
  'font.pixelSize: 11' \
  'font.pixelSize: 9' \
  'opacity: entered || !RaohaneMotion.panelMotionEnabled || !root.visible ? 1 : 0' \
  'enabled: RaohaneMotion.panelMotionEnabled && root.visible' \
  'showSheen: true'; do
  rg -Fq "$contract" "$notifications" \
    || fail "Notification Center lost legible low-motion glass: $contract"
done


# The Notification Center keeps notification-service ownership while sharing
# the same quiet glass material and compact list presentation.
for contract in \
  'idleColor: RaohaneTheme\.surfaceSubtle' \
  'showInnerRim: true' \
  'stateRailWidth: 2' \
  'delegate: Item[[:space:]]*\{' \
  'RaohaneNotificationCard[[:space:]]*\{' \
  'compact: true' \
  'RaohaneNotifications\.discardAllNotifications\(\)' \
  'RaohaneNotifications\.markAllRead\(\)'; do
  rg -q "$contract" "$notifications" \
    || fail "Notification Center lost content-pair contract: ${contract}"
done

# Quick Controls: system toggles are confirmed async transactions, brightness
# has a non-clickable icon, while speaker/microphone icons keep real mute actions.
rg -q 'property bool iconEnabled:[[:space:]]*false' "$quick" \
  || fail 'Quick Controls lost explicit slider-icon interactivity'
rg -q 'title:[[:space:]]*qsTr\("Volume"\)' "$quick" \
  || fail 'Quick Controls lost volume row'
rg -q 'contextText:[[:space:]]*RaohaneAudio\.sinkName' "$quick" \
  || fail 'Volume row lost current output context'
rg -q 'contextText:[[:space:]]*RaohaneAudio\.sourceName' "$quick" \
  || fail 'Microphone row lost current input context'
rg -q 'readonly property bool tileBusy:' "$quick_tile" \
  || fail 'Quick Control tiles lost asynchronous busy state'
for busy_binding in \
  'RaohaneNetwork\.wifiBusy' \
  'RaohanePerformance\.busy' \
  'RaohaneBluetooth\.busy' \
  'RaohaneEasyEffects\.busy'; do
  rg -q "$busy_binding" "$quick_tile" \
    || fail "Quick Control busy state lost binding: ${busy_binding}"
done
rg -q 'readonly property bool tileError:' "$quick_tile" \
  || fail 'Quick Control tiles lost actionable error state'
for error_binding in \
  'RaohaneNetwork\.wifiToggleError' \
  'RaohanePerformance\.lastError' \
  'RaohaneBluetooth\.lastError' \
  'RaohaneEasyEffects\.lastError'; do
  rg -q "$error_binding" "$quick_tile" \
    || fail "Quick Control error state lost binding: ${error_binding}"
done
rg -q 'RaohanePerformance\.toggleGameMode\(\)' "$quick_tile" \
  || fail 'Game Mode tile no longer invokes the performance service'
rg -q 'RaohaneNetwork\.toggleWifi\(\)' "$quick_tile" \
  || fail 'Wi-Fi tile no longer invokes the transactional radio toggle'
rg -q 'root\.pickerRequested\("bluetooth"\)' "$quick_tile" \
  || fail 'Bluetooth tile no longer opens the inline device picker'
rg -q 'readonly property bool bluetoothMode:[[:space:]]*mode === "bluetooth"' "$device_picker" \
  || fail 'Device picker lost Bluetooth mode'
rg -q 'RaohaneBluetooth\.devices\.slice' "$device_picker" \
  || fail 'Bluetooth picker no longer renders native device state'
rg -q 'function toggleDevice\(device\): void' "$bluetooth" \
  || fail 'Bluetooth service lost device connect/disconnect action'

# Hyprland 0.55+ performance IPC is the primary path. The legacy keyword path is
# retained only as a compatibility fallback and must not be used for probing.
rg -q '"hyprctl",[[:space:]]*"eval",[[:space:]]*root\.modernGameModeExpression' "$performance" \
  || fail 'Performance service lost Hyprland 0.55+ eval path'
rg -q 'getoption animations\.enabled' "$performance" \
  || fail 'Performance service lost modern animations.enabled probe'
rg -q 'signal gameModeApplied\(bool enabled\)' "$performance" \
  || fail 'Performance service lost confirmed apply signal'
rg -q 'root\.gameModeActive[[:space:]]*===[[:space:]]*root\.requestedGameMode' "$performance" \
  || fail 'Performance service no longer verifies applied state'

# Context Island owns compact transient feedback. Privacy always wins and stale
# volume/network events are coalesced rather than replayed after capture ends.
rg -q 'if \(root\.recording \|\| root\.camera \|\| root\.microphone\)' "$context" \
  || fail 'Context service lost privacy priority guard'
rg -q 'id:[[:space:]]*audioEventTimer' "$context" \
  || fail 'Context service lost coalesced audio events'
rg -q 'id:[[:space:]]*networkEventTimer' "$context" \
  || fail 'Context service lost coalesced network events'
rg -q 'onGameModeApplied\(enabled: bool\)' "$context" \
  || fail 'Context service no longer follows confirmed performance changes'
rg -q 'readonly property bool progressMode:' "$context_island" \
  || fail 'Context Island lost transient progress mode'
rg -q 'RaohaneContext\.eventProgress' "$context_island" \
  || fail 'Context Island lost live event progress'
rg -q 'RaohaneMedia\.progress' "$context_island" \
  || fail 'Context Island lost live media progress'

# Compact Bar surfaces use the same soft Raohane Flow material and leave
# no text smaller than 9px. TextMetrics must match their visible text.
rg -Fq 'surfaceRadius: Math.min(RaohaneTheme.radiusHero, height / 2)' "$context_island" \
  || fail 'Context Island lost the shared rounded material'
rg -Fq 'showSheen: true' "$context_island" \
  || fail 'Context Island lost its glass catch-light'
[[ "$(rg -Fc 'font.pixelSize: 11' "$context_island")" == 2 ]] \
  || fail 'Context Island title font and metrics differ'
[[ "$(rg -Fc 'font.pixelSize: 9' "$context_island")" == 2 ]] \
  || fail 'Context Island detail font and metrics differ'
rg -Fq 'scale: root.morphMotionAllowed && recorderMouse.containsMouse' "$context_island" \
  || fail 'Context Island recorder icon animates during gaming/low-motion'
rg -Fq 'showInnerRim: true' "$systray" \
  || fail 'System tray lost shared soft hover rim'
rg -Fq 'hoverColor: RaohaneTheme.surfaceSubtle' "$systray" \
  || fail 'System tray hover lost shared glass wash'
python3 - "$context_island" <<'PY'
from pathlib import Path
import re
import sys
source = Path(sys.argv[1]).read_text()
lines = source.splitlines()
for n, line in enumerate(lines):
    if not re.search(r"Behavior on [\w.]+\s*\{", line):
        continue
    remainder = line.split("{", 1)[1]
    guarded = "enabled: root.morphMotionAllowed" in remainder
    if not guarded and n + 1 < len(lines):
        guarded = lines[n + 1].strip() == "enabled: root.morphMotionAllowed"
    if not guarded:
        raise SystemExit(f"Context Island animation is not motion-gated at line {n + 1}")
PY


# Shared visuals and fallbacks should not create noisy generic icon requests.
rg -q 'RaohaneAdaptiveIcon[[:space:]]*\{' "$systray" \
  || fail 'System tray lost adaptive icon rendering'
rg -q 'source\.indexOf\("\?"\)' "$adaptive_icon" \
  || fail 'Adaptive icon no longer strips provider fallback queries'
for generic in applications-system preferences-system preferences-desktop-theme multimedia-volume-control hwloc; do
  rg -q "name === \"${generic}\"" "$icon_resolver" \
    || fail "Icon resolver lost generic fallback: ${generic}"
done

# Keep the rest of the major visible surfaces on shared motion/components.
rg -q 'RaohaneMotion\.' "$sidebar" || fail 'Sidebar lost shared motion'
rg -q 'RaohaneMotion\.' "$workspaces" || fail 'Workspaces lost shared motion'
rg -q 'RaohaneMotion\.standard' "$notifications" || fail 'Notification Center lost shared motion'
rg -q 'id:[[:space:]]*cardTranslate' "$osd" || fail 'OSD lost runtime-safe translate target'
rg -q 'RaohaneMotion\.' "$osd" || fail 'OSD lost shared motion'

# Reusable system surfaces must stay on shared theme/motion tokens and avoid
# stale active-property collisions or one-off legacy colors.
if rg -n '#24ffffff|shortDuration|mediumDuration' \
  "$control" "$control_header" "$control_footer" "$control_status" "$control_actions" "$control_media" \
  "$quick" "$quick_tile" "$notifications"; then
  fail 'current system surfaces reintroduced stale colors or motion aliases'
fi
if rg -n 'property bool active:[[:space:]]*false' \
  "$control_header" "$control_footer" "$control_status" "$control_actions" "$control_media" \
  "$quick" "$quick_tile" "$notifications"; then
  fail 'reusable system surfaces reintroduced an active-property collision'
fi

printf 'ui-polish-audit: animated glass Settings, dashboard Control Center, confirmed system transactions, priority-aware Context Island, shared controls and icon fallbacks are valid\n'
