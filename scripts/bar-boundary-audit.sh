#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'bar-boundary-audit: %s\n' "$*" >&2
  exit 1
}

bar='modules/raohane/RaohaneBar.qml'
vertical='modules/raohane/RaohaneVerticalBar.qml'
module_host='modules/raohane/RaohaneBarModule.qml'
module_registry='modules/raohane/RaohaneBarModuleRegistry.qml'
bar_studio='modules/raohane/RaohaneBarStudio.qml'
config='modules/raohane/config/RaohaneConfig.qml'
defaults='defaults/native.json'
workspaces='modules/raohane/RaohaneWorkspaces.qml'
tray='modules/raohane/RaohaneSysTray.qml'
status='modules/raohane/RaohaneSystemIcons.qml'
clock='modules/raohane/RaohaneClock.qml'
qmldir='modules/raohane/qmldir'

for path in "$bar" "$vertical" "$module_host" "$module_registry" "$bar_studio" "$config" "$defaults" "$workspaces" "$tray" "$status" "$clock" "$qmldir"; do
  [[ -f "$path" ]] || fail "missing native bar path: $path"
done

for registration in \
  'RaohaneVerticalBar .*RaohaneVerticalBar.qml' \
  'singleton RaohaneBarModuleRegistry .*RaohaneBarModuleRegistry.qml' \
  'RaohaneBarModule .*RaohaneBarModule.qml' \
  'RaohaneBarStudio .*RaohaneBarStudio.qml' \
  'RaohaneWorkspaces .*RaohaneWorkspaces.qml' \
  'RaohaneSysTray .*RaohaneSysTray.qml' \
  'RaohaneSystemIcons .*RaohaneSystemIcons.qml' \
  'RaohaneClock .*RaohaneClock.qml'; do
  rg -q "^${registration}$" "$qmldir" || fail "missing qmldir registration: $registration"
done

for module_id in launcher workspaces context tray system network bluetooth notifications clock audio control session separator; do
  rg -q "\"${module_id}\"[[:space:]]*:" "$module_registry" \
    || fail "bar module registry lost module id: $module_id"
done
for zone in left center right; do
  rg -q "${zone}:[[:space:]]*\[" "$module_registry" \
    || fail "bar module registry lost default zone: $zone"
done
for contract in moduleIds defaultLayout defaultVerticalLayout defaultLayoutFor sanitizeZone sanitizeLayout supports isRepeatable preferredZone label description; do
  rg -q "$contract" "$module_registry" || fail "bar module registry lost contract: $contract"
done

for contract in \
  'property var barModuleLayout:[[:space:]]*root\.defaultBarModuleLayout\(\)' \
  'function defaultBarModuleLayout\(\): var' \
  'function sanitizeBarModuleLayout\(value\): var' \
  'modules:[[:space:]]*root\.sanitizeBarModuleLayout\(root\.barModuleLayout\)' \
  'root\.barModuleLayout[[:space:]]*=[[:space:]]*root\.sanitizeBarModuleLayout\(value\)' \
  'onBarModuleLayoutChanged:[[:space:]]*scheduleSave\(\)'; do
  rg -q "$contract" "$config" || fail "native config lost persisted horizontal bar-module contract: $contract"
done
for contract in \
  'property var barVerticalModuleLayout:[[:space:]]*root\.defaultVerticalBarModuleLayout\(\)' \
  'function defaultVerticalBarModuleLayout\(\): var' \
  'function sanitizeVerticalBarModuleLayout\(value\): var' \
  'verticalModules:[[:space:]]*root\.sanitizeVerticalBarModuleLayout\(root\.barVerticalModuleLayout\)' \
  'root\.barVerticalModuleLayout[[:space:]]*=[[:space:]]*root\.sanitizeVerticalBarModuleLayout\(value\)' \
  'onBarVerticalModuleLayoutChanged:[[:space:]]*scheduleSave\(\)'; do
  rg -q "$contract" "$config" || fail "native config lost persisted vertical bar-module contract: $contract"
done
for module_id in launcher workspaces context tray system clock control separator; do
  rg -q "\"${module_id}\"" "$defaults" || fail "native defaults lost horizontal bar module id: $module_id"
done
for module_id in network bluetooth notifications audio session; do
  rg -q "\"${module_id}\"" "$defaults" || fail "native defaults lost vertical bar module id: $module_id"
done
rg -q '"modules"[[:space:]]*:' "$defaults" || fail 'native defaults do not persist horizontal bar modules'
rg -q '"verticalModules"[[:space:]]*:' "$defaults" || fail 'native defaults do not persist vertical bar modules'

rg -q 'RaohaneConfig\.barModuleLayout' "$bar" \
  || fail 'horizontal bar does not consume persisted module layout'
rg -q 'readonly property var activeLayout:[[:space:]]*RaohaneBarModuleRegistry\.sanitizeLayout' "$bar" \
  || fail 'horizontal bar does not validate persisted layout through the native registry'
rg -q 'RaohaneBarModule[[:space:]]*\{' "$bar" \
  || fail 'horizontal bar does not compose registered module hosts'
for zone in left center right; do
  rg -q "root\.activeLayout\.${zone}" "$bar" || fail "horizontal bar does not render persisted $zone zone"
done

rg -q 'RaohaneConfig\.barVerticalModuleLayout' "$vertical" \
  || fail 'vertical bar does not consume persisted vertical module layout'
rg -q 'readonly property var activeLayout:[[:space:]]*RaohaneBarModuleRegistry\.sanitizeLayout' "$vertical" \
  || fail 'vertical bar does not validate persisted composition through the native registry'
rg -q 'orientation:[[:space:]]*"vertical"' "$vertical" \
  || fail 'vertical bar does not request vertical module rendering'
for zone in left center right; do
  rg -q "root\.activeLayout\.${zone}" "$vertical" || fail "vertical bar does not render persisted $zone zone"
done

for component in RaohaneWorkspaces RaohaneSysTray RaohaneSystemIcons RaohaneClock RaohaneContextIsland; do
  rg -q "${component}[[:space:]]*\\{" "$module_host" \
    || fail "RaohaneBarModule does not render $component"
done
for service in RaohaneNetwork RaohaneBluetooth RaohaneNotifications RaohanePrivacy RaohaneAudio RaohaneContext; do
  rg -q "${service}\." "$module_host" || fail "vertical module renderer lost native service: $service"
done
for contract in \
  'property string orientation:[[:space:]]*"horizontal"' \
  'readonly property bool vertical:' \
  'verticalNetworkComponent' \
  'verticalBluetoothComponent' \
  'verticalNotificationsComponent' \
  'verticalClockComponent' \
  'verticalAudioComponent' \
  'verticalSessionComponent' \
  'verticalSeparatorComponent'; do
  rg -q "$contract" "$module_host" || fail "orientation-aware module renderer lost contract: $contract"
done

for contract in \
  'property string orientation:' \
  'RaohaneConfig\.barModuleLayout' \
  'RaohaneConfig\.barVerticalModuleLayout' \
  'RaohaneBarModuleRegistry\.supports\(id, root\.orientation\)' \
  'RaohaneBarModuleRegistry\.defaultLayoutFor\(root\.orientation\)' \
  'function commit\(layout\): void' \
  'function addModule\(id: string\): void' \
  'function removeAt\(zone: string, index: int\): void' \
  'function moveWithin\(zone: string, index: int, delta: int\): void' \
  'function moveAcross\(zone: string, index: int, delta: int\): void' \
  'function resetLayout\(\): void' \
  'RaohaneBarModuleRegistry\.preferredZone'; do
  rg -q "$contract" "$bar_studio" || fail "Bar Studio lost dual-orientation composition contract: $contract"
done
for label in Horizontal Vertical Top Middle Bottom; do
  rg -q "qsTr\(\"${label}\"\)" "$bar_studio" || fail "Bar Studio lost orientation UX label: $label"
done

for symbol in 'RaohaneConfig\.' 'RaohaneState\.'; do
  rg -q "$symbol" "$bar" || fail "RaohaneBar lost native framework dependency: $symbol"
  rg -q "$symbol" "$vertical" || fail "RaohaneVerticalBar lost native framework dependency: $symbol"
done

if rg -n '^import qs$|^import qs\.services$|^import qs\.modules\.common|^import qs\.modules\.ii|\bConfig\.|\bGlobalStates\.' "$bar" "$vertical" "$module_host" "$module_registry" "$bar_studio"; then
  fail 'Raohane bar runtime regressed to inherited config/state/common/ii framework'
fi

if rg -n '^[[:space:]]*(Workspaces|SysTray|SystemIcons)[[:space:]]*\{|\bDateTime\.|\bHyprlandData\.' "$bar" "$vertical" "$module_host"; then
  fail 'Raohane bar runtime regressed to inherited workspace/tray/status/time backends'
fi

for symbol in 'Hyprland\.workspaces' 'Hyprland\.monitorFor' 'workspace\.activate\(\)' 'Hyprland\.usingLua'; do
  rg -q "$symbol" "$workspaces" || fail "native workspaces lost required Hyprland contract: $symbol"
done
for contract in \
  'property string orientation:[[:space:]]*"horizontal"' \
  'orientation === "vertical"' \
  'verticalWorkspaces' \
  'horizontalWorkspaces'; do
  rg -q "$contract" "$workspaces" || fail "native workspaces lost orientation contract: $contract"
done
if rg -n '^import qs\.(services|modules\.ii|modules\.common)$|\bWorkspaceModel\b' "$workspaces"; then
  fail 'RaohaneWorkspaces regressed to inherited workspace plumbing'
fi

rg -q '^import Quickshell\.Services\.SystemTray$' "$tray" || fail 'native tray does not import Quickshell SystemTray'
for symbol in 'SystemTray\.items' '\.activate\(\)' '\.secondaryActivate\(\)' '\.display\(' '\.scroll\('; do
  rg -q "$symbol" "$tray" || fail "native tray lost required interaction: $symbol"
done
if rg -n '^import qs\.(services|modules\.ii|modules\.common)' "$tray"; then
  fail 'RaohaneSysTray regressed to inherited tray plumbing'
fi

for symbol in 'RaohaneAudio\.' 'RaohaneNetwork\.' 'RaohaneBluetooth\.' 'RaohaneNotifications\.'; do
  rg -q "$symbol" "$status" || fail "native system icons lost required service: $symbol"
done
if rg -n '^import qs\.(services|modules\.ii|modules\.common)' "$status"; then
  fail 'RaohaneSystemIcons regressed to inherited status plumbing'
fi

for symbol in \
  'property bool active:' \
  '\bTimer[[:space:]]*\{' \
  'running:[[:space:]]*root\.active'; do
  rg -q "$symbol" "$clock" || fail "RaohaneClock lost idle-safe timer contract: $symbol"
done
rg -q 'active:[[:space:]]*root\.hostActive' "$module_host" \
  || fail 'horizontal module renderer does not suspend RaohaneClock while hidden'
rg -q 'running:[[:space:]]*root\.hostActive' "$module_host" \
  || fail 'vertical module renderer does not suspend its clock while hidden'
for host in "$bar" "$vertical"; do
  rg -q 'hostActive:[[:space:]]*barWindow\.visible' "$host" \
    || fail "$host does not forward visibility to module timers"
done
if rg -n '\bDateTime\.|^import qs\.' "$clock"; then
  fail 'RaohaneClock regressed to inherited DateTime plumbing'
fi

for file in "$bar" "$vertical"; do
  for symbol in \
    'Hyprland\.monitorFor' \
    'monitorHasFullscreen' \
    'monitorHasSpecialOpen' \
    'effectiveFullscreen' \
    'fullscreenSuppressed' \
    '&& !fullscreenSuppressed' \
    'monitorHasSpecialOpen \|\| superShow' \
    'WlrLayer\.Overlay' \
    'target:[[:space:]]*"bar"' \
    'function toggle\(\): void' \
    'function open\(\): void' \
    'function close\(\): void' \
    'function mode\(\): string' \
    'name:[[:space:]]*"barToggle"'; do
    rg -q "$symbol" "$file" || fail "$file lost shared bar/runtime contract: $symbol"
  done
done
rg -q 'return[[:space:]]+"horizontal"' "$bar" \
  || fail 'horizontal bar does not identify its active runtime mode'
rg -q 'return[[:space:]]+"vertical"' "$vertical" \
  || fail 'vertical bar does not identify its active runtime mode'
rg -q '^import Quickshell\.Io$' "$vertical" \
  || fail 'vertical bar does not import Quickshell.Io for its IPC handler'

for symbol in \
  'RaohaneConfig\.barAutoHide' \
  'RaohaneConfig\.barAutoHidePushWindows' \
  'RaohaneConfig\.barShowOnSuper' \
  'RaohaneState\.superDown' \
  'Behavior on x' \
  'RaohaneConfig\.barVerticalModuleLayout' \
  'orientation:[[:space:]]*"vertical"'; do
  rg -q "$symbol" "$vertical" || fail "native vertical bar lost host/runtime contract: $symbol"
done
if rg -n '^import qs$|^import qs\.services$|^import qs\.modules\.common|^import qs\.modules\.ii|\bConfig\.|\bGlobalStates\.|Minimal native vertical|richer parity can evolve' "$vertical"; then
  fail 'RaohaneVerticalBar regressed to inherited plumbing or migration-only presentation'
fi

printf 'bar-boundary-audit: horizontal and vertical bars share registry-backed modules with independent persisted layouts and a dual-orientation Bar Studio\n'
