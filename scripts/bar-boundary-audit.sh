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
bar_appearance='modules/raohane/RaohaneBarAppearanceSettings.qml'
bar_layout_editor='modules/raohane/RaohaneBarLayoutEditor.qml'
context='modules/raohane/RaohaneContext.qml'
config='modules/raohane/config/RaohaneConfig.qml'
defaults='defaults/native.json'
workspaces='modules/raohane/RaohaneWorkspaces.qml'
tray='modules/raohane/RaohaneSysTray.qml'
status='modules/raohane/RaohaneSystemIcons.qml'
clock='modules/raohane/RaohaneClock.qml'
qmldir='modules/raohane/qmldir'

for path in "$bar" "$vertical" "$module_host" "$module_registry" "$bar_studio" "$bar_appearance" "$bar_layout_editor" "$context" "$config" "$defaults" "$workspaces" "$tray" "$status" "$clock" "$qmldir"; do
  [[ -f "$path" ]] || fail "missing native bar path: $path"
done

for registration in \
  'RaohaneVerticalBar .*RaohaneVerticalBar.qml' \
  'singleton RaohaneBarModuleRegistry .*RaohaneBarModuleRegistry.qml' \
  'RaohaneBarModule .*RaohaneBarModule.qml' \
  'RaohaneBarStudio .*RaohaneBarStudio.qml' \
  'RaohaneBarLayoutEditor .*RaohaneBarLayoutEditor.qml' \
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

# Cinematic is opt-in; module identity, configuration and existing layouts
# must continue to use the shared native bar rather than a second panel.
rg -Fq 'id: "cinematic", label: qsTr("Cinematic")' "$bar_appearance" \
  || fail 'Cinematic preset missing from Bar Studio'
rg -Fq 'RaohaneConfig.barStylePreset === "cinematic"' "$bar" \
  || fail 'Cinematic visual treatment is not active in native bar'
rg -Fq '"cinematic", "islands"' "$config" \
  || fail 'Cinematic preset cannot be loaded from saved settings'
rg -Fq 'RaohaneTheme.accentBorder' "$bar" \
  || fail 'Cinematic center island lost accent treatment'

# Halo stays an opt-in, single-surface variant of the existing horizontal Bar.
# It must not fork module rendering, change the vertical Bar, or erase the
# original Floating/Cinematic presets.
rg -Fq 'id: "halo", label: qsTr("Halo")' "$bar_appearance" \
  || fail 'Halo capsule is missing from Bar Studio'
rg -Fq 'RaohaneConfig.barStylePreset === "halo"' "$bar" \
  || fail 'Halo is not selectable on the real horizontal bar'
rg -Fq '"cinematic", "halo", "islands"' "$config" \
  || fail 'Halo preset is not restorable from native preferences'
rg -Fq 'surface: "float", group: "transparent", height: 44, radius: 22' "$bar_appearance" \
  || fail 'Halo lost its slender transparent capsule dimensions'
rg -Fq 'RaohaneConfig.barModuleLayout = {' "$bar_appearance" \
  || fail 'Halo does not configure the existing native three-zone modules'
rg -Fq 'center: ["clock", "context"]' "$bar_appearance" \
  || fail 'Halo does not center the existing clock and context modules'
rg -Fq 'right: ["tray", "system", "control"]' "$bar_appearance" \
  || fail 'Halo lost existing system/tray/control interactions'
rg -Fq '(barWindow.surfaceStyle === "panel" || barWindow.haloPreset)' "$bar" \
  || fail 'Halo glass backing was lost'
rg -Fq '&& !haloPreset' "$bar" \
  || fail 'Halo overlays separate opaque island backgrounds'
rg -Fq 'barWindow.haloPreset || !barWindow.zoneBackgroundVisible' "$bar" \
  || fail 'Halo did not flatten all three native zone surfaces'
rg -Fq 'readonly property bool haloStyle:' "$workspaces" \
  || fail 'Halo workspace dots are not bound to actual compositor desktops'
rg -Fq 'RaohaneConfig.barStylePreset === "halo"' "$workspaces" \
  || fail 'Halo workspace styling is not scoped to its preset'
rg -Fq 'raised: !root.haloStyle || root.priorityMode' modules/raohane/RaohaneContextIsland.qml \
  || fail 'Halo context styling does not preserve privacy/recording emphasis'
rg -Fq 'readonly property bool mediaMode:' modules/raohane/RaohaneContextIsland.qml \
  || fail 'Halo context styling removed media interaction'
rg -Fq 'border.color: barWindow.haloPreset' "$bar" \
  || fail 'Halo border no longer follows the wallpaper-tinted shared theme'
rg -Fq 'barWindow.haloPreset && barContent.width >= 1100' "$bar" \
  || fail 'Halo zone dividers are not responsive'
# Existing saved layouts and service calls remain authoritative: no fresh
# timers/Hyprland probes or separate Wayland layer are added for this preset.
if rg -Fq 'Timer {' modules/raohane/RaohaneBarAppearanceSettings.qml; then
  fail 'Halo Bar Studio gained an unnecessary background timer'
fi


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
for service in RaohaneNetwork RaohaneBluetooth RaohaneNotifications RaohaneAudio RaohaneContext; do
  rg -q "${service}\." "$module_host" || fail "bar module renderer lost native service: $service"
done
# Privacy ownership belongs to the shared context service, not to horizontal or
# vertical bar renderers. Both orientations consume the same icon/mode contract.
rg -q 'RaohanePrivacy\.' "$context" \
  || fail 'Context service lost native privacy ownership'
rg -q 'icon:[[:space:]]*RaohaneContext\.icon' "$module_host" \
  || fail 'vertical context renderer no longer consumes the shared context icon'
rg -q 'function activateContextPrimary\(\): void' "$module_host" \
  || fail 'bar module renderer lost context-aware primary routing'
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
  'RaohaneBarAppearanceSettings' \
  'RaohaneBarLayoutEditor'; do
  rg -q "$contract" "$bar_studio" || fail "Bar Studio lost composition shell contract: $contract"
done

for contract in \
  'property string orientation:' \
  'RaohaneConfig\.barModuleLayout' \
  'RaohaneConfig\.barVerticalModuleLayout' \
  'RaohaneBarModuleRegistry\.supports\(id, root\.orientation\)' \
  'RaohaneBarModuleRegistry\.defaultLayoutFor\(root\.orientation\)' \
  'function commit\(next\): void' \
  'function addModule\(id: string, zone: string, index: int\): void' \
  'function removeAt\(zone: string, index: int\): void' \
  'function moveModule\(sourceZone: string, sourceIndex: int, id: string, targetZone: string, targetIndex: int\): void' \
  'function commitDrop\(targetZone: string\): void' \
  'DropArea' \
  'Drag\.active' \
  'RaohaneBarModuleRegistry\.preferredZone'; do
  rg -q "$contract" "$bar_layout_editor" || fail "Bar layout editor lost dual-orientation drag/drop contract: $contract"
done
for label in Horizontal Vertical; do
  rg -q "qsTr\(\"${label}\"\)" "$bar_studio" || fail "Bar Studio lost orientation UX label: $label"
done
for label in Top Middle Bottom Left Center Right; do
  rg -q "qsTr\(\"${label}\"\)" "$bar_layout_editor" || fail "Bar layout editor lost zone UX label: $label"
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
  rg -q 'hostActive:[[:space:]]*barWindow\.visible[[:space:]]*&&[[:space:]]*!barWindow\.fullscreenSuppressed' "$host" \
    || fail "$host does not suspend module timers while fullscreen-suppressed"
done
if rg -n '\bDateTime\.|^import qs\.' "$clock"; then
  fail 'RaohaneClock regressed to inherited DateTime plumbing'
fi

# Every preset shares a collision-free three-zone geometry and never
# hides clock/system under a long media title. Width budgets depend only on
# the physical viewport, not a circular width->implicitWidth dependency.
for contract in \
  'readonly property real contentWidthLimit:' \
  'haloPreset ? 1240' \
  'cinematicPreset ? 1360' \
  'readonly property real centerWidthLimit:' \
  'readonly property bool compactWidth:' \
  'readonly property bool narrowWidth:' \
  'readonly property bool ultraNarrow:' \
  'readonly property real sideIslandLimit:' \
  '(width - centerIsland.width) / 2' \
  '- sideInset - zoneGap' \
  'Math.min(barContent.sideIslandLimit, Math.max(0, leftRow.implicitWidth' \
  'Math.min(barContent.sideIslandLimit, Math.max(0, rightRow.implicitWidth' \
  'Math.min(barWindow.centerWidthLimit, Math.max(0, centerRow.implicitWidth' \
  'width: Math.min(parent.width, barWindow.contentWidthLimit)' \
  'anchors.horizontalCenter: parent.horizontalCenter' \
  'densityMode: barWindow.moduleDensity' \
  'compactClock: barWindow.clockCompact' \
  'compactWorkspaces: barWindow.compactWidth' \
  'minimalWorkspaces: barWindow.ultraNarrow'; do
  rg -Fq "$contract" "$bar" || fail "horizontal Bar lost responsive geometry: $contract"
done
for file in "$bar" modules/raohane/RaohaneClock.qml modules/raohane/RaohaneContextIsland.qml \
            modules/raohane/RaohaneBarModule.qml modules/raohane/RaohaneWorkspaces.qml; do
  [[ -f "$file" ]] || fail "required responsive module missing: $file"
done
rg -Fq 'readonly property bool effectiveShowDate: showDate && !compactMode' modules/raohane/RaohaneClock.qml \
  || fail 'compact Bar no longer hides secondary date'
rg -Fq 'property string densityMode: "full"' modules/raohane/RaohaneContextIsland.qml \
  || fail 'Bar context cannot switch density'
rg -Fq 'if (root.iconOnly)' modules/raohane/RaohaneContextIsland.qml \
  || fail 'Bar context has no minimal fallback'
rg -Fq 'if (root.minimalMode)' "$workspaces" \
  || fail 'ultra-narrow bar does not reserve a visible active workspace'
rg -Fq 'if (!root.compactMode && !root.minimalMode)' "$workspaces" \
  || rg -Fq '(!root.compactMode && !root.minimalMode)' "$workspaces" \
  || fail 'normal Bar lost full workspace switcher'
python3 - "$bar" <<'PY'
import re
import sys
from pathlib import Path

source = Path(sys.argv[1]).read_text()
for island in ("leftIsland", "centerIsland", "rightIsland"):
    match = re.search(r'id:\s*' + island + r'\b([\s\S]*?)\n\s*RowLayout\s*\{', source)
    if not match or not re.search(r'\bclip:\s*true\b', match.group(1)):
        raise SystemExit(f"{island} no longer clips oversized custom modules")

# Geometry proof for real width limits, center percentages and margins.
# Side islands are capped before the center; a margin + gap is reserved on
# *each* side. Check a range of logical-output sizes and preset profiles.
for screen_width in (320, 480, 590, 680, 770, 960, 1024, 1280, 1540, 1920, 2560, 3840):
    for maximum in (1200, 1240, 1320, 1360, 1400, screen_width):
        width = min(screen_width, maximum)
        ratio = .36 if width < 590 else .38 if width < 770 else .39
        for center_implicit in (0, 80, 240, 420, 750):
            center = min(max(48, min(width * ratio, 460)), center_implicit)
            for edge in (0, 16, 24, 48):
                for halo in (False, True):
                    gap = 3 if width < 590 else 5 if width < 770 else 12 if halo else 10
                    inset = edge + (10 if halo else 0)
                    side_limit = max(0, (width - center) / 2 - inset - gap)
                    left = min(side_limit, 300)
                    right = min(side_limit, 380)
                    left_end = inset + left
                    center_left = (width - center) / 2
                    center_right = (width + center) / 2
                    right_start = width - inset - right
                    # Very narrow windows may have no room for side modules.
                    # In that case the side collapses to zero, never overlaps.
                    assert left_end <= center_left - gap + 1e-7 or left == 0
                    assert right_start >= center_right + gap - 1e-7 or right == 0
PY

# Both bar orientations keep their layer-shell surface resident during fullscreen.
# Content and timers are suspended, exclusion drops to zero, and a zero-sized
# Region makes the transparent surface fully click-through instead of destroying
# and recreating the Wayland surface across game fullscreen transitions.
for file in "$bar" "$vertical"; do
  for symbol in \
    'Hyprland\.monitorFor' \
    'monitorHasFullscreen' \
    'monitorHasSpecialOpen' \
    'effectiveFullscreen' \
    'fullscreenSuppressed' \
    'visible:[[:space:]]*RaohaneState\.barOpen[[:space:]]*&&[[:space:]]*!RaohaneState\.screenLocked' \
    'mask:[[:space:]]*Region' \
    'barWindow\.fullscreenSuppressed[[:space:]]*\?[[:space:]]*0' \
    'monitorHasSpecialOpen \|\| superShow' \
    'WlrLayer\.Overlay' \
    'target:[[:space:]]*"bar"' \
    'function toggle\(\): void' \
    'function open\(\): void' \
    'function close\(\): void' \
    'function mode\(\): string' \
    'name:[[:space:]]*"barToggle"'; do
    rg -q "$symbol" "$file" || fail "$file lost shared resident bar/runtime contract: $symbol"
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

# Workspace app badges reuse Hyprland's live model; avoid polling.
for contract in 'representativeWindow' 'wayland?.appId' 'RaohaneAdaptiveIcon' 'Accessible.name' 'workspaceButton.workspaceId'; do
  rg -Fq "$contract" "$workspaces" || fail "native workspaces lost app identity/accessibility contract: $contract"
done
# Commented guidance may mention hyprctl: reject executable paths, not prose.
if rg -v '^[[:space:]]*//' "$workspaces" | rg -n 'hyprctl|Process[[:space:]]*\{|Timer[[:space:]]*\{'; then
  fail 'workspace app identity regressed to subprocess polling'
fi

printf 'bar-boundary-audit: horizontal and vertical bars share registry-backed modules, resident fullscreen surfaces, context-owned privacy and independent persisted layouts\n'
