#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'bar-boundary-audit: %s\n' "$*" >&2
  exit 1
}

bar='modules/raohane/RaohaneBar.qml'
workspaces='modules/raohane/RaohaneWorkspaces.qml'
tray='modules/raohane/RaohaneSysTray.qml'
status='modules/raohane/RaohaneSystemIcons.qml'
clock='modules/raohane/RaohaneClock.qml'
qmldir='modules/raohane/qmldir'

for path in "$bar" "$workspaces" "$tray" "$status" "$clock" "$qmldir"; do
  [[ -f "$path" ]] || fail "missing native bar path: $path"
done

for registration in \
  'RaohaneWorkspaces .*RaohaneWorkspaces.qml' \
  'RaohaneSysTray .*RaohaneSysTray.qml' \
  'RaohaneSystemIcons .*RaohaneSystemIcons.qml' \
  'RaohaneClock .*RaohaneClock.qml'; do
  rg -q "^${registration}$" "$qmldir" || fail "missing qmldir registration: $registration"
done

for component in RaohaneWorkspaces RaohaneSysTray RaohaneSystemIcons RaohaneClock; do
  rg -q "${component}[[:space:]]*\\{" "$bar" || fail "RaohaneBar does not consume $component"
done

for symbol in 'RaohaneConfig\.' 'RaohaneState\.'; do
  rg -q "$symbol" "$bar" || fail "RaohaneBar lost native framework dependency: $symbol"
done

if rg -n '^import qs$|^import qs\.services$|^import qs\.modules\.common|^import qs\.modules\.ii|\bConfig\.|\bGlobalStates\.' "$bar"; then
  fail 'RaohaneBar regressed to inherited config/state/common/ii framework'
fi

if rg -n '^[[:space:]]*(Workspaces|SysTray|SystemIcons)[[:space:]]*\{|\bDateTime\.|\bHyprlandData\.' "$bar"; then
  fail 'RaohaneBar regressed to inherited workspace/tray/status/time backends'
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

rg -q '\bTimer[[:space:]]*\{' "$clock" || fail 'RaohaneClock lost its native timer'
if rg -n '\bDateTime\.|^import qs\.' "$clock"; then
  fail 'RaohaneClock regressed to inherited DateTime plumbing'
fi

# services/Fonts.qml remains a narrow compatibility singleton while old pages
# still exist. Singleton is a Quickshell QML type, so this import is mandatory.
if rg -q '^[[:space:]]*Singleton[[:space:]]*\{' services/Fonts.qml; then
  rg -q '^import Quickshell([[:space:]]|$)' services/Fonts.qml \
    || fail 'services/Fonts.qml uses Singleton without importing Quickshell'
fi

printf 'bar-boundary-audit: native bar framework, workspaces, tray, status and clock boundaries are valid\n'
