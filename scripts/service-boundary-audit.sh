#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'raohane-service-audit: %s\n' "$*" >&2
  exit 1
}

MODULE=modules/raohane/services
QMLDIR="$MODULE/qmldir"
CONFIG_MODULE=modules/raohane/config
FAMILY=panelFamilies/RaohaneFamily.qml
SEARCH="$MODULE/RaohaneSearch.qml"
SESSION="$MODULE/RaohaneSession.qml"
PROCESSES="$MODULE/RaohaneProcesses.qml"
TASK_MANAGER=modules/raohane/RaohaneTaskManager.qml
AUDIO="$MODULE/RaohaneAudio.qml"
PIPEWIRE="$MODULE/RaohanePipeWire.qml"
EASY_EFFECTS="$MODULE/RaohaneEasyEffects.qml"
CONTROL_CENTER=modules/raohane/RaohaneControlCenter.qml
QUICK_CONTROLS=modules/raohane/RaohaneQuickControls.qml
AUTOSTART_SCRIPT=scripts/autostart.sh
RECORDER=scripts/videos/record.sh
CLI=scripts/raohane
FEATURES=install/arch/features.txt
REQUIRED=install/arch/required.txt

for path in \
  "$QMLDIR" "$CONFIG_MODULE/qmldir" "$CONFIG_MODULE/RaohaneConfig.qml" \
  "$SEARCH" "$SESSION" "$PROCESSES" "$TASK_MANAGER" "$AUDIO" "$PIPEWIRE" "$EASY_EFFECTS" \
  "$CONTROL_CENTER" "$QUICK_CONTROLS" "$AUTOSTART_SCRIPT" "$RECORDER" "$CLI" \
  "$FEATURES" "$REQUIRED"; do
  [[ -f "$path" ]] || fail "missing native service/runtime path: $path"
done

rg -q '^singleton RaohaneConfig .*RaohaneConfig.qml$' "$CONFIG_MODULE/qmldir" \
  || fail 'RaohaneConfig is not registered in the native config module'
if rg -n '^import qs$|modules\.common|JsonAdapter|\bConfig\.' "$CONFIG_MODULE/RaohaneConfig.qml"; then
  fail 'RaohaneConfig depends on inherited config/common framework'
fi

require_service() {
  local name="$1"
  local backend_pattern="$2"
  local file="$MODULE/$name.qml"
  [[ -f "$file" ]] || fail "$file is missing"
  rg -q "^singleton ${name} .*${name}\.qml$" "$QMLDIR" \
    || fail "$name is not registered in native services"
  rg -q "$backend_pattern" "$file" \
    || fail "$name lost direct system/Quickshell backend: $backend_pattern"
}

require_service RaohaneMedia 'Quickshell\.Services\.Mpris'
require_service RaohaneBluetooth '\bbluetoothctl\b'
require_service RaohaneAudio '\bwpctl\b'
require_service RaohaneNetwork '\bnmcli\b'
require_service RaohanePipeWire '\bpw-mon\b'
require_service RaohaneDisplay 'brightnessctl|ddcutil|hyprsunset'
require_service RaohaneNotifications 'Quickshell\.Services\.Notifications'
require_service RaohaneWallpapers 'Qt\.labs\.folderlistmodel'
require_service RaohaneSession 'hyprctl.*dispatch.*exit'
require_service RaohaneSessionWarnings 'pacman|/var/lib/pacman/db\.lck'
require_service RaohaneSystemInfo '/etc/os-release'
require_service RaohaneSearch 'DesktopEntries'
require_service RaohaneProcesses '/proc/meminfo|ps -u'
require_service RaohaneIdle 'IdleInhibitor'
require_service RaohaneEasyEffects 'easyeffects'
require_service RaohaneYdotool 'ydotool'
require_service RaohaneDropShelf 'wl-copy --type text/uri-list'
require_service RaohaneAutostart 'scripts/autostart\.sh'

for package in bluez-utils brightnessctl ddcutil hyprsunset easyeffects ydotool libqalculate; do
  rg -q "^${package}$" "$FEATURES" \
    || fail "native service/backend package missing from feature manifest: $package"
done
rg -q '^procps-ng$' "$REQUIRED" \
  || fail 'native Task Manager requires procps-ng in the required manifest'
if rg -q '^btop$' "$FEATURES"; then
  fail 'retired external Task Manager dependency btop is still required by the feature manifest'
fi

# Native Task Manager: process collection is on-demand, UI refreshes only while
# visible, Session opens the native surface by default, and destructive actions
# require an explicit second press in the UI.
rg -q '^singleton RaohaneProcesses .*RaohaneProcesses.qml$' "$QMLDIR" \
  || fail 'RaohaneProcesses is not registered in native services'
for contract in \
  '/proc/meminfo' \
  'ps -u' \
  'property var processes:' \
  'function refresh\(\): void' \
  'function terminate\(pids\): void' \
  'function forceKill\(pids\): void' \
  '\$8 != \\"quickshell\\"' \
  '\$8 != \\"qs\\"'; do
  rg -q "$contract" "$PROCESSES" || fail "native process service lost contract: $contract"
done
if rg -n 'Timer[[:space:]]*\{[^}]*repeat:[[:space:]]*true' "$PROCESSES"; then
  fail 'process service contains permanent background polling'
fi

for contract in \
  'RaohaneProcesses\.' \
  'running:[[:space:]]*RaohaneState\.taskManagerOpen' \
  'interval:[[:space:]]*1500' \
  'target:[[:space:]]*"taskManager"' \
  'pendingAction' \
  'requestSignal\(' \
  'RaohaneState\.(setPrimaryOpen|togglePrimary)\("taskManager"'; do
  rg -q "$contract" "$TASK_MANAGER" || fail "native Task Manager lost UI/safety contract: $contract"
done
rg -q '^RaohaneTaskManager .*RaohaneTaskManager.qml$' modules/raohane/qmldir \
  || fail 'RaohaneTaskManager is not registered in native UI module'
rg -q 'component:[[:space:]]*RaohaneTaskManager[[:space:]]*\{' "$FAMILY" \
  || fail 'RaohaneFamily does not load native Task Manager'
rg -q 'taskManagerCommand' "$SESSION" \
  || fail 'custom Task Manager command override was lost'
rg -q 'ipc", "call", "taskManager", "open"' "$SESSION" \
  || fail 'Session does not route default Task Manager action to native IPC'
if rg -n 'command -v (btop|htop)|exec (btop|htop|top)' "$SESSION"; then
  fail 'Session still contains the retired terminal Task Manager fallback'
fi

# Audio and privacy share one PipeWire registry watcher. This prevents two
# permanent pw-mon clients and prevents their snapshot probes from waking one
# another during graph churn.
rg -Fq 'command: ["pw-mon", "--color=never"]' "$PIPEWIRE" \
  || fail 'shared PipeWire service lost its registry event monitor'
rg -q 'id:[[:space:]]*graphDebounce' "$PIPEWIRE" \
  || fail 'shared PipeWire service lost graph-change debounce'
rg -q 'id:[[:space:]]*monitorRestart' "$PIPEWIRE" \
  || fail 'shared PipeWire service lost monitor restart handling'
rg -q 'target:[[:space:]]*RaohanePipeWire' "$AUDIO" \
  || fail 'audio service no longer consumes shared PipeWire events'
rg -q 'RaohanePipeWire\.suppressEventsFor' "$AUDIO" \
  || fail 'audio service no longer suppresses self-generated graph churn'
rg -q 'interval:[[:space:]]*30000' "$AUDIO" \
  || fail 'audio service lost its slow health fallback'
if rg -n '"pw-mon"|interval:[[:space:]]*750' "$AUDIO"; then
  fail 'audio service regressed to a duplicate watcher or subsecond wpctl polling'
fi
rg -q '^pipewire$' "$REQUIRED" \
  || fail 'audio event monitor requires pipewire in the required manifest'

# EasyEffects state is only needed when its controls are surfaced.
if rg -n 'interval:[[:space:]]*5000|running:[[:space:]]*root\.available' "$EASY_EFFECTS"; then
  fail 'EasyEffects service regressed to permanent background state polling'
fi
rg -q 'RaohaneEasyEffects\.refresh\(\)' "$CONTROL_CENTER" \
  || fail 'Control Center no longer refreshes EasyEffects state on demand'
rg -q 'refreshTimer\.restart\(\)' "$EASY_EFFECTS" \
  || fail 'EasyEffects actions lost their one-shot post-action state refresh'

# Game Mode is compositor state, so refresh only when Control Center is surfaced.
rg -q 'function refreshGameMode\(\): void' "$QUICK_CONTROLS" \
  || fail 'Quick Controls lost on-demand Game Mode refresh'
rg -q 'if \(!gameModeProbe\.running\)' "$QUICK_CONTROLS" \
  || fail 'Game Mode refresh no longer guards duplicate hyprctl probes'
rg -q 'quickControls\.refreshGameMode\(\)' "$CONTROL_CENTER" \
  || fail 'Control Center no longer refreshes Game Mode when opened'
rg -q 'onSecondary:[[:space:]]*root\.setGameMode\(false\)' "$QUICK_CONTROLS" \
  || fail 'Game Mode reset bypasses local state synchronization'
if rg -n '^[[:space:]]*running:[[:space:]]*true[[:space:]]*$' "$QUICK_CONTROLS"; then
  fail 'Quick Controls contains an unconditional background Process/Timer'
fi

for pair in \
  'modules/raohane/RaohaneContext.qml:RaohaneMedia\.' \
  'modules/raohane/RaohaneMediaOverlay.qml:RaohaneMedia\.' \
  'modules/raohane/RaohaneQuickControls.qml:RaohaneBluetooth\.' \
  'modules/raohane/RaohaneQuickControls.qml:RaohaneAudio\.' \
  'modules/raohane/RaohaneQuickControls.qml:RaohaneNetwork\.' \
  'modules/raohane/RaohaneQuickControls.qml:RaohaneDisplay\.' \
  'modules/raohane/RaohaneQuickControls.qml:RaohaneIdle\.' \
  'modules/raohane/RaohaneQuickControls.qml:RaohaneEasyEffects\.' \
  'modules/raohane/RaohaneOsd.qml:RaohaneAudio\.' \
  'modules/raohane/RaohaneOsd.qml:RaohaneDisplay\.' \
  'modules/raohane/RaohaneLauncher.qml:RaohaneSearch\.' \
  'modules/raohane/RaohaneTaskManager.qml:RaohaneProcesses\.' \
  'modules/raohane/RaohaneWallpaperSelector.qml:RaohaneWallpapers\.'; do
  file="${pair%%:*}"
  pattern="${pair#*:}"
  rg -q "$pattern" "$file" || fail "$file lost native service dependency: $pattern"
done

for surface in RaohaneNotificationCenter.qml RaohaneNotificationPopup.qml RaohaneNotificationCard.qml; do
  rg -q 'RaohaneNotifications\.' "modules/raohane/$surface" \
    || fail "$surface does not consume RaohaneNotifications"
done

if rg -n \
  '\bMprisController\b|\bBluetoothStatus\.|(^|[^A-Za-z])Audio\.|(^|[^A-Za-z])Network\.|(^|[^A-Za-z])Brightness\.|(^|[^A-Za-z])Hyprsunset\.|(^|[^A-Za-z])Idle\.|(^|[^A-Za-z])EasyEffects\.' \
  modules/raohane/RaohaneContext.qml \
  modules/raohane/RaohaneMediaOverlay.qml \
  modules/raohane/RaohaneQuickControls.qml \
  modules/raohane/RaohaneOsd.qml; then
  fail 'active Raohane surfaces reference inherited service APIs'
fi

if rg -n 'LauncherSearch|LauncherSearchResult|AppSearch|qs\.modules\.common\.models' modules/raohane/RaohaneLauncher.qml; then
  fail 'RaohaneLauncher regressed to inherited search model'
fi
if rg -n '^import qs$|^import qs\.services|modules\.common|LauncherSearch|AppSearch|StringUtils|Fuzzy\.' "$SEARCH"; then
  fail 'RaohaneSearch depends on inherited search/common services'
fi

# Launcher modes advertised by the UI must have real native backends.
rg -q 'calculator\.command = \["qalc", "-t", expression\]' "$SEARCH" \
  || fail 'launcher calculator no longer uses qalc backend'
rg -q '"libqalculate"|^libqalculate$' "$FEATURES" \
  || fail 'launcher calculator backend package is missing'
rg -q '\["qs", "-c", "raohane", "ipc", "call", "lock", "activate"\]' "$SEARCH" \
  || fail 'launcher lock action does not route to native Raohane lock IPC'
if rg -n 'loginctl[" ,]+lock-session' "$SEARCH"; then
  fail 'launcher lock action regressed to logind instead of native WlSessionLock'
fi
for contract in '\bcliphist list\b' '\bcliphist decode\b' '\bwl-copy\b'; do
  rg -q "$contract" "$SEARCH" || fail "launcher clipboard mode lost backend contract: $contract"
done

# Doctor must report the same native feature backends that the product invokes.
for probe in \
  'check_cmd pw-mon pipewire' \
  'check_cmd bluetoothctl bluez-utils optional' \
  'check_cmd blueman-manager blueman optional' \
  'check_cmd nm-connection-editor network-manager-applet optional' \
  'check_cmd brightnessctl brightnessctl optional' \
  'check_cmd ddcutil ddcutil optional' \
  'check_cmd hyprsunset hyprsunset optional' \
  'check_cmd grim grim optional' \
  'check_cmd slurp slurp optional' \
  'check_cmd wf-recorder wf-recorder optional' \
  'check_cmd wl-copy wl-clipboard optional' \
  'check_cmd cliphist cliphist optional' \
  'check_cmd ffmpeg ffmpeg optional' \
  'check_cmd magick imagemagick optional' \
  'check_cmd notify-send libnotify optional' \
  'check_cmd tesseract tesseract optional' \
  'check_cmd trans translate-shell optional' \
  'check_cmd ydotool ydotool optional' \
  'check_cmd ydotoold ydotool optional' \
  'check_cmd qalc libqalculate optional' \
  'check_cmd easyeffects easyeffects optional' \
  'check_cmd fprintd-list fprintd optional'; do
  rg -Fq "$probe" "$CLI" || fail "doctor deps lost native backend probe: $probe"
done
if rg -n 'check_cmd (cava|ffplay|btop)\b' "$CLI"; then
  fail 'doctor deps still advertises retired/non-runtime cava, ffplay or btop probes'
fi

for service in RaohaneSession.qml RaohaneDisplay.qml RaohaneWallpapers.qml; do
  rg -q 'qs\.modules\.raohane\.config' "$MODULE/$service" \
    || fail "$service does not consume native config"
  if rg -n '\bConfig\.' "$MODULE/$service"; then
    fail "$service still consumes inherited Config"
  fi
done

for contract in \
  'HYPRLAND_INSTANCE_SIGNATURE' \
  'raohane-autostart-' \
  'setsid bash -lc' \
  'run|rerun|reset|status|config'; do
  rg -q "$contract" "$AUTOSTART_SCRIPT" \
    || fail "native autostart backend lost session contract: $contract"
done
rg -q 'RaohaneAutostart\.runOnce\(\)' "$FAMILY" \
  || fail 'RaohaneFamily no longer starts the native autostart service'
rg -q '^import qs\.modules\.raohane\.services$' "$FAMILY" \
  || fail 'RaohaneFamily does not import native services for autostart'
bash -n "$AUTOSTART_SCRIPT"

if rg -n 'illogical-impulse|raohane/config\.json|CONFIG_FILE=.*/config\.json' "$RECORDER"; then
  fail 'native recorder still reads a retired compatibility config'
fi
for contract in \
  'RAOHANE_RECORDING_DIR' \
  'xdg-user-dir VIDEOS' \
  '\bwf-recorder\b' \
  '\bslurp\b' \
  '\bhyprctl\b' \
  '\bpactl\b'; do
  rg -q "$contract" "$RECORDER" \
    || fail "native recorder lost runtime contract: $contract"
done
for package in wf-recorder slurp libpulse; do
  rg -q "^${package}$" "$FEATURES" \
    || fail "recorder backend package missing from feature manifest: $package"
done
rg -q '^xdg-user-dirs$' "$REQUIRED" \
  || fail 'recorder XDG Videos fallback requires xdg-user-dirs'
bash -n "$RECORDER"

if [[ -e modules/raohane/RaohaneLegacyBridge.qml ]]; then
  fail 'retired compatibility bridge returned to the native runtime tree'
fi
if rg -n '\bRaohaneLegacyBridge\b' "$FAMILY" modules/raohane/qmldir; then
  fail 'active runtime references the retired compatibility bridge'
fi

printf 'raohane-service-audit: native services, on-demand Task Manager, shared event-driven PipeWire monitoring, on-demand EasyEffects/Game Mode, launcher modes, doctor probes, recorder and autostart contracts are valid\n'