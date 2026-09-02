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
workspaces='modules/raohane/RaohaneWorkspaces.qml'
tray='modules/raohane/RaohaneSysTray.qml'
status='modules/raohane/RaohaneSystemIcons.qml'
clock='modules/raohane/RaohaneClock.qml'
qmldir='modules/raohane/qmldir'

for path in "$bar" "$vertical" "$module_host" "$module_registry" "$workspaces" "$tray" "$status" "$clock" "$qmldir"; do
  [[ -f "$path" ]] || fail "missing native bar path: $path"
done

for registration in \
  'RaohaneVerticalBar .*RaohaneVerticalBar.qml' \
  'singleton RaohaneBarModuleRegistry .*RaohaneBarModuleRegistry.qml' \
  'RaohaneBarModule .*RaohaneBarModule.qml' \
  'RaohaneWorkspaces .*RaohaneWorkspaces.qml' \
  'RaohaneSysTray .*RaohaneSysTray.qml' \
  'RaohaneSystemIcons .*RaohaneSystemIcons.qml' \
  'RaohaneClock .*RaohaneClock.qml'; do
  rg -q "^${registration}$" "$qmldir" || fail "missing qmldir registration: $registration"
done

for module_id in launcher workspaces context tray system clock control separator; do
  rg -q "\"${module_id}\"[[:space:]]*:" "$module_registry" \
    || fail "bar module registry lost module id: $module_id"
done
for zone in left center right; do
  rg -q "${zone}:[[:space:]]*\[" "$module_registry" \
    || fail "bar module registry lost default zone: $zone"
done
for contract in defaultLayout sanitizeZone sanitizeLayout supports; do
  rg -q "$contract" "$module_registry" || fail "bar module registry lost contract: $contract"
done

rg -q 'RaohaneBarModuleRegistry\.defaultLayout' "$bar" \
  || fail 'horizontal bar does not consume the native module registry'
rg -q 'RaohaneBarModule[[:space:]]*\{' "$bar" \
  || fail 'horizontal bar does not compose registered module hosts'
for component in RaohaneWorkspaces RaohaneSysTray RaohaneSystemIcons RaohaneClock RaohaneContextIsland; do
  rg -q "${component}[[:space:]]*\\{" "$module_host" \
    || fail "RaohaneBarModule does not render $component"
done

for symbol in 'RaohaneConfig\.' 'RaohaneState\.'; do
  rg -q "$symbol" "$bar" || fail "RaohaneBar lost native framework dependency: $symbol"
done

if rg -n '^import qs$|^import qs\.services$|^import qs\.modules\.common|^import qs\.modules\.ii|\bConfig\.|\bGlobalStates\.' "$bar" "$module_host" "$module_registry"; then
  fail 'Raohane bar runtime regressed to inherited config/state/common/ii framework'
fi

if rg -n '^[[:space:]]*(Workspaces|SysTray|SystemIcons)[[:space:]]*\{|\bDateTime\.|\bHyprlandData\.' "$bar" "$module_host"; then
  fail 'Raohane bar runtime regressed to inherited workspace/tray/status/time backends'
fi

for symbol in 'Hyprland\.workspaces' 'Hyprland\.monitorFor' 'workspace\.activate\(\)' 'Hyprland\.usingLua'; do
  rg -q "$symbol" "$workspaces" || fail "native workspaces lost required Hyprland contract: $symbol"
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
  || fail 'horizontal bar module host does not suspend RaohaneClock while fullscreen/hidden'
rg -q 'hostActive:[[:space:]]*barWindow\.visible' "$bar" \
  || fail 'horizontal bar does not forward visibility to module timers'
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
  'running:[[:space:]]*RaohaneConfig\.barVertical && RaohaneState\.barOpen && !RaohaneState\.screenLocked' \
  'Behavior on x' \
  'RaohaneNetwork\.' \
  'RaohaneBluetooth\.' \
  'RaohaneNotifications\.' \
  'RaohanePrivacy\.' \
  'RaohaneAudio\.' \
  'RaohaneContext\.'; do
  rg -q "$symbol" "$vertical" || fail "native vertical bar lost parity contract: $symbol"
done
if rg -n '^import qs$|^import qs\.services$|^import qs\.modules\.common|^import qs\.modules\.ii|\bConfig\.|\bGlobalStates\.|Minimal native vertical|richer parity can evolve' "$vertical"; then
  fail 'RaohaneVerticalBar regressed to inherited plumbing or migration-only presentation'
fi

printf 'bar-boundary-audit: native bars preserve fullscreen behavior and the horizontal bar composes through the Raohane module registry\n'
