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
control='modules/raohane/RaohaneControlCenter.qml'
control_status='modules/raohane/RaohaneControlCenterStatusStrip.qml'
control_actions='modules/raohane/RaohaneControlCenterActionDock.qml'
control_media='modules/raohane/RaohaneControlCenterMediaCard.qml'
quick='modules/raohane/RaohaneQuickControls.qml'
quick_tile='modules/raohane/RaohaneQuickControlTile.qml'
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
  "$settings_section" "$settings_control" "$settings_search" \
  "$control" "$control_status" "$control_actions" "$control_media" "$quick" "$quick_tile" "$context" "$context_island" \
  "$performance" "$notifications" "$osd" "$systray" "$adaptive_icon" \
  "$icon_resolver" "$workspaces" "$sidebar"; do
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

# Control Center remains one compact system hub: a read-only System Glance,
# registry-backed Quick Controls with one device-picker path, a balanced
# media/notifications content pair, and an action-only dock.
rg -q 'readonly property int panelHeight:' "$control" \
  || fail 'Control Center lost bounded floating height'
rg -q 'property bool heldVisible:[[:space:]]*false' "$control" \
  || fail 'Control Center lost animated close hold'
rg -q 'quickControls\.pickerMode[[:space:]]*=[[:space:]]*""' "$control" \
  || fail 'Control Center no longer closes device picker during dismissal'
rg -q 'event\.key[[:space:]]*!==[[:space:]]*Qt\.Key_Escape' "$control" \
  || fail 'Control Center lost Escape handling'
rg -q 'RaohaneQuickControls[[:space:]]*\{' "$control" \
  || fail 'Control Center lost Quick Controls composition'
rg -q 'tileColumns:[[:space:]]*3' "$control" \
  || fail 'Control Center lost compact three-column Quick Controls'
rg -q 'RaohaneNotificationCenter[[:space:]]*\{' "$control" \
  || fail 'Control Center lost notification composition'
rg -q 'RaohaneControlCenterStatusStrip[[:space:]]*\{' "$control" \
  || fail 'Control Center lost read-only System Glance composition'
rg -q 'RaohaneControlCenterActionDock[[:space:]]*\{' "$control" \
  || fail 'Control Center lost action dock composition'
rg -q 'RaohaneControlCenterMediaCard[[:space:]]*\{' "$control" \
  || fail 'Control Center lost extracted media-card composition'
if rg -n 'component MediaCard:[[:space:]]*RaohaneSurface' "$control"; then
  fail 'Control Center regained inline media-card presentation'
fi

for signal in screenshotRequested translatorRequested oskRequested wallpaperRequested powerRequested; do
  rg -q "signal ${signal}\\(\\)" "$control_actions" \
    || fail "Control Center action dock lost signal: ${signal}"
done
for action in Screenshot Translator OSK Wallpaper Power; do
  rg -q "label:[[:space:]]*qsTr\\(\\\"${action}\\\"\\)" "$control_actions" \
    || fail "Control Center action dock lost ${action}"
done
if rg -q 'label:[[:space:]]*qsTr\("Performance"\)|label:[[:space:]]*qsTr\("DND"\)' "$control_actions"; then
  fail 'Control Center reintroduced duplicate system toggles in the action dock'
fi

# Status, action dock and media card are presentation-only. Network/audio/media
# service ownership and transitions remain in the Control Center coordinator.
for presentation in "$control_status" "$control_actions" "$control_media"; do
  if rg -n '^import qs\.modules\.raohane\.(services|config)' "$presentation"; then
    fail "$presentation imported services/config instead of staying presentation-only"
  fi
  if rg -n 'Raohane(Network|Bluetooth|Audio|Privacy|Performance|State|Session|Media)\.' "$presentation"; then
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
  'showStateRail: root\.privacyActive'; do
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
  'showStateRail: root\.playing'; do
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

# The paired Notification Center keeps notification-service ownership but shares
# the same matte Nocturne content material and compact list presentation.
for contract in \
  'idleColor: RaohaneTheme\.surfaceSubtle' \
  'showInnerRim: false' \
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
  "$control" "$control_status" "$control_actions" "$control_media" "$quick" "$quick_tile" "$notifications"; then
  fail 'current system surfaces reintroduced stale colors or motion aliases'
fi
if rg -n 'property bool active:[[:space:]]*false' \
  "$control_status" "$control_actions" "$control_media" "$quick" "$quick_tile" "$notifications"; then
  fail 'reusable system surfaces reintroduced an active-property collision'
fi

printf 'ui-polish-audit: animated Settings, balanced Nocturne Control Center content, confirmed system transactions, priority-aware Context Island, shared controls and icon fallbacks are valid\n'
