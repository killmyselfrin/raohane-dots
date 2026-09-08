#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'scenes-boundary-audit: %s\n' "$*" >&2
  exit 1
}

SCENES=modules/raohane/services/RaohaneScenes.qml
SERVICES=modules/raohane/services/qmldir
UI_QMLDIR=modules/raohane/qmldir
PATHS=modules/raohane/config/RaohanePaths.qml
SEARCH=modules/raohane/services/RaohaneSearch.qml
AUDIO=modules/raohane/services/RaohaneAudio.qml
RECORDER=modules/raohane/services/RaohaneRecorder.qml
RECORD_SCRIPT=scripts/videos/record.sh
CONTEXT=modules/raohane/RaohaneContext.qml
CONTEXT_ISLAND=modules/raohane/RaohaneContextIsland.qml
RUNTIME=modules/raohane/RaohaneRuntimeProbe.qml
QUICK_CONTROLS=modules/raohane/RaohaneQuickControls.qml
SWITCHER=modules/raohane/RaohaneSceneSwitcher.qml
SETTINGS=modules/raohane/RaohaneSettingsScenes.qml
SETTINGS_REGISTRY=modules/raohane/RaohaneSettingsPageRegistry.qml

for path in "$SCENES" "$SERVICES" "$UI_QMLDIR" "$PATHS" "$SEARCH" "$AUDIO" "$RECORDER" "$RECORD_SCRIPT" "$CONTEXT" "$CONTEXT_ISLAND" "$RUNTIME" "$QUICK_CONTROLS" "$SWITCHER" "$SETTINGS" "$SETTINGS_REGISTRY"; do
  [[ -f "$path" ]] || fail "missing scene integration path: $path"
done

rg -q '^singleton RaohaneScenes 1\.0 RaohaneScenes\.qml$' "$SERVICES" \
  || fail 'RaohaneScenes is not registered in the native services module'
rg -q '^singleton RaohaneRecorder 1\.0 RaohaneRecorder\.qml$' "$SERVICES" \
  || fail 'RaohaneRecorder is not registered in the native services module'
rg -q '^RaohaneSceneSwitcher 1\.0 RaohaneSceneSwitcher\.qml$' "$UI_QMLDIR" \
  || fail 'RaohaneSceneSwitcher is not registered in the native UI module'
rg -q '^RaohaneSettingsScenes 1\.0 RaohaneSettingsScenes\.qml$' "$UI_QMLDIR" \
  || fail 'RaohaneSettingsScenes is not registered in the native UI module'
rg -q 'sceneStateFile: root\.join\(root\.stateDirectory, "scenes\.json"\)' "$PATHS" \
  || fail 'scene runtime state is not stored in the Raohane state directory'

for contract in \
  '^import Quickshell\.Wayland$' \
  'property string selectedSceneId: "balanced"' \
  'property string activeSceneId: "balanced"' \
  'property bool autoSwitchEnabled: true' \
  'sceneIds: \["balanced", "gaming", "focus", "work"\]' \
  'activeAppId: String\(ToplevelManager\.activeToplevel\?\.appId' \
  'function policyFor\(sceneId\): var' \
  'function defaultRules\(\): var' \
  'pattern: "steam_app_", match: "prefix", scene: "gaming"' \
  'pattern: "gamescope", match: "contains", scene: "gaming"' \
  'function matchingSceneFor\(appId\): string' \
  'function evaluateAutoScene\(\): void' \
  'function setAppRule\(appId, sceneId\): bool' \
  'function removeAppRule\(appId\): bool' \
  'property bool manualOverride:' \
  'property string manualOverrideAppId:' \
  'property bool baselineCaptured:' \
  'RaohaneNotifications\.silent' \
  'RaohaneIdle\.setInhibit' \
  'RaohanePerformance\.setGameMode' \
  'selectedScene: root\.selectedSceneId' \
  'autoSwitch: root\.autoSwitchEnabled' \
  'rules: root\.sanitizeRules\(root\.appRules\)' \
  'target: "scenes"'; do
  rg -q "$contract" "$SCENES" || fail "scene service lost contract: $contract"
done

if rg -n 'RaohaneConfig\.[A-Za-z0-9_]+[[:space:]]*=' "$SCENES"; then
  fail 'Scenes must overlay runtime policy instead of mutating persistent base config'
fi
if rg -n 'Timer[[:space:]]*\{[^}]*repeat:[[:space:]]*true' "$SCENES"; then
  fail 'Scenes regressed to permanent polling instead of active-window events/debounce'
fi

for scene in balanced gaming focus work; do
  rg -q "RaohaneScenes\.activate\(\"${scene}\", \"launcher\"\)" "$SEARCH" \
    || fail "Launcher action missing for scene: $scene"
done
rg -q 'active: RaohaneScenes\.activeSceneId === "gaming"' "$SEARCH" \
  || fail 'Launcher no longer exposes active scene state'

for contract in \
  'function gamingActionResults\(\): var' \
  'RaohaneAudio\.toggleMicrophoneMute\(\)' \
  'RaohaneAudio\.cycleDefaultSink\(\)' \
  'RaohaneRecorder\.toggleFullscreen\(true\)' \
  'RaohanePerformance\.toggleGameMode\(\)' \
  'RaohaneNotifications\.silent = !RaohaneNotifications\.silent' \
  'RaohaneMedia\.togglePlaying\(\)' \
  'if \(needle\.length === 0\)' \
  'const contextual = root\.gamingActionResults\(\)'; do
  rg -q "$contract" "$SEARCH" || fail "Gaming Launcher actions lost native service contract: $contract"
done
if rg -n 'Quickshell\.execDetached\([^\n]*(hyprctl|wpctl|nmcli|wf-recorder|pkill)|command:[^\n]*(hyprctl|wpctl|nmcli|wf-recorder|pkill)|record\.sh' "$SEARCH"; then
  fail 'contextual Launcher actions bypass native Raohane services'
fi

for contract in \
  'function nextOutputDevice\(\): var' \
  'function nextOutputName\(\): string' \
  'function cycleDefaultSink\(\): bool' \
  'root\.setDefaultSink\(next\)'; do
  rg -q "$contract" "$AUDIO" || fail "Audio output cycling lost contract: $contract"
done

for contract in \
  'recorderScript: Quickshell\.shellPath\("scripts/videos/record\.sh"\)' \
  'readonly property bool ownedRecording: recordProcess\.running' \
  'readonly property bool recording: root\.ownedRecording \|\| root\.externalRecording' \
  'function startFullscreen\(sound\): bool' \
  'function startRegion\(sound\): bool' \
  'function stop\(\): bool' \
  'function toggleFullscreen\(sound\): bool' \
  'running: root\.externalRecording && !root\.ownedRecording' \
  'target: "recorder"'; do
  rg -q "$contract" "$RECORDER" || fail "Recorder service lost contract: $contract"
done
rg -q 'exec wf-recorder' "$RECORD_SCRIPT" \
  || fail 'native recorder no longer delegates to the validated recording script'

rg -q 'RaohaneSceneSwitcher[[:space:]]*\{' "$QUICK_CONTROLS" \
  || fail 'runtime Quick Controls no longer exposes the scene switcher'
for contract in \
  'RaohaneScenes\.activate\(sceneButton\.modelData\.id, "control-center"\)' \
  'RaohaneScenes\.setAutoSwitch\(!RaohaneScenes\.autoSwitchEnabled\)' \
  'RaohaneScenes\.autoSceneActive' \
  'RaohaneScenes\.activeSceneId'; do
  rg -q "$contract" "$SWITCHER" || fail "Scene switcher lost contract: $contract"
done

rg -q 'key: "scenes".*source: "RaohaneSettingsScenes\.qml"' "$SETTINGS_REGISTRY" \
  || fail 'Settings registry no longer routes the Scenes page'
for contract in \
  'RaohaneScenes\.activate\(sceneCard\.modelData\.id, "settings"\)' \
  'RaohaneScenes\.setAutoSwitch\(checked\)' \
  'RaohaneScenes\.setAppRule\(pattern, root\.ruleScene\)' \
  'RaohaneScenes\.removeAppRule\(ruleCard\.modelData\.pattern\)' \
  'RaohaneScenes\.activeAppId' \
  'RaohaneScenes\.defaultRules\(\)'; do
  rg -q "$contract" "$SETTINGS" || fail "Scenes Settings lost native service contract: $contract"
done
if rg -n 'FileView|scenes\.json|RaohanePaths\.sceneStateFile' "$SETTINGS"; then
  fail 'Scenes Settings must use RaohaneScenes instead of reading or writing scene persistence directly'
fi

rg -q 'target: RaohaneScenes' "$CONTEXT" \
  || fail 'Context model no longer consumes scene activation events'
rg -q 'target: RaohaneRecorder' "$CONTEXT" \
  || fail 'Context model no longer consumes recorder activity'
rg -q 'gameplayRecording: RaohaneRecorder\.recording' "$CONTEXT" \
  || fail 'Context model no longer exposes persistent gameplay recording state'
rg -q 'scene: RaohaneScenes\.activeSceneId' "$CONTEXT" \
  || fail 'Context diagnostics no longer expose active scene'

for contract in \
  'sceneId: RaohaneScenes\.activeSceneId' \
  'sceneMarkerVisible:' \
  'gameplayRecording: RaohaneContext\.gameplayRecording' \
  'indicatorIcon: root\.gameplayRecording \? "stop_circle"' \
  'onClicked: RaohaneRecorder\.stop\(\)'; do
  rg -q "$contract" "$CONTEXT_ISLAND" || fail "Context Island 2.0 lost activity contract: $contract"
done

rg -q 'active: RaohaneScenes\.activeSceneId' "$RUNTIME" \
  || fail 'Runtime probe no longer exposes active scene'
rg -q 'policy: RaohaneScenes\.activePolicy' "$RUNTIME" \
  || fail 'Runtime probe no longer exposes effective scene policy'
for contract in \
  'recorder: \{' \
  'recording: RaohaneRecorder\.recording' \
  'owned: RaohaneRecorder\.ownedRecording' \
  'elapsed: RaohaneRecorder\.elapsedSeconds' \
  'error: RaohaneRecorder\.lastError'; do
  rg -q "$contract" "$RUNTIME" || fail "Runtime recorder diagnostics lost contract: $contract"
done

printf 'scenes-boundary-audit: native scene state, reversible policies, event-driven app rules, Settings management, native gaming actions, scene-aware Context Island activity and runtime diagnostics are valid\n'
