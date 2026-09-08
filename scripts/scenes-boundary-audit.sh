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
DOCK=modules/raohane/RaohaneDock.qml
MOTION=modules/raohane/RaohaneMotion.qml

for path in "$SCENES" "$SERVICES" "$UI_QMLDIR" "$PATHS" "$SEARCH" "$AUDIO" "$RECORDER" "$RECORD_SCRIPT" "$CONTEXT" "$CONTEXT_ISLAND" "$RUNTIME" "$QUICK_CONTROLS" "$SWITCHER" "$SETTINGS" "$SETTINGS_REGISTRY" "$DOCK" "$MOTION"; do
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
  'matchModes: \["exact", "prefix", "contains"\]' \
  'activeAppId: String\(ToplevelManager\.activeToplevel\?\.appId' \
  'activeRule: root\.autoSceneActive' \
  'function policyFor\(sceneId\): var' \
  'function defaultRules\(\): var' \
  'pattern: "steam_app_", match: "prefix", scene: "gaming"' \
  'pattern: "gamescope", match: "contains", scene: "gaming"' \
  'function matchingRuleFor\(appId\): var' \
  'function matchingSceneFor\(appId\): string' \
  'function evaluateAutoScene\(\): void' \
  'function setRule\(patternValue, matchType, sceneId\): bool' \
  'function removeRule\(patternValue, matchType\): bool' \
  'function setAppRule\(appId, sceneId\): bool' \
  'function removeAppRule\(appId\): bool' \
  'function setPatternRule\(pattern: string, matchType: string, sceneId: string\): string' \
  'function removePatternRule\(pattern: string, matchType: string\): string' \
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

for contract in \
  'function sceneManagementResults\(needle: string\): var' \
  'RaohaneScenes\.setAutoSwitch\(!RaohaneScenes\.autoSwitchEnabled\)' \
  'RaohaneScenes\.clearManualOverride\(\)' \
  'for \(const sceneId of RaohaneScenes\.sceneIds\)' \
  'RaohaneScenes\.setRule\(appId, "exact", sceneId\)' \
  'RaohaneScenes\.matchingRuleFor\(appId\)' \
  'RaohaneScenes\.removeRule\(activeRule\.pattern, activeRule\.match\)' \
  'const contextualManagement = root\.sceneManagementResults\(needle\)' \
  'return contextualManagement\.concat\(builtIns\)'; do
  rg -q "$contract" "$SEARCH" || fail "Launcher 2.0 scene management lost native contract: $contract"
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
  'property string ruleMatch: "exact"' \
  'id: "prefix"' \
  'id: "contains"' \
  'RaohaneScenes\.activate\(sceneCard\.modelData\.id, "settings"\)' \
  'RaohaneScenes\.setAutoSwitch\(checked\)' \
  'RaohaneScenes\.setRule\(pattern, root\.ruleMatch, root\.ruleScene\)' \
  'RaohaneScenes\.removeRule\(ruleCard\.modelData\.pattern, ruleCard\.modelData\.match\)' \
  'RaohaneScenes\.matchingRuleFor\(RaohaneScenes\.activeAppId\)' \
  'RaohaneScenes\.defaultRules\(\)'; do
  rg -q "$contract" "$SETTINGS" || fail "Scenes Settings lost explicit rule-mode contract: $contract"
done
if rg -n 'FileView|scenes\.json|RaohanePaths\.sceneStateFile' "$SETTINGS"; then
  fail 'Scenes Settings must use RaohaneScenes instead of reading or writing scene persistence directly'
fi

for contract in \
  'sceneHidePolicy: String\(RaohaneScenes\.activePolicy\?\.dockPolicy' \
  'if \(dockWindow\.fullscreenActive \|\| root\.sceneHidePolicy\)' \
  '&& !root\.sceneHidePolicy' \
  'visible: dockWindow\.fullscreenActive \|\| root\.sceneHidePolicy'; do
  rg -q "$contract" "$DOCK" || fail "Dock lost temporary Scene visibility overlay: $contract"
done
if rg -n 'sceneHidePolicy.*RaohaneConfig\.|RaohaneConfig\.(dockAutoHide|dockPinned|dockEnabled)[[:space:]]*=.*scene' "$DOCK"; then
  fail 'Dock Scene overlay must not rewrite persisted dock configuration'
fi

for contract in \
  '^import qs\.modules\.raohane\.services$' \
  'motionScale: RaohaneTheme\.motionScale' \
  'sceneMotionHint: String\(RaohaneScenes\.activePolicy\?\.motionHint' \
  'sceneDurationFactor: sceneMotionHint === "fast" \? 0\.72' \
  ': sceneMotionHint === "quiet" \? 0\.82' \
  'animationFast \* sceneDurationFactor' \
  'animationDuration \* sceneDurationFactor' \
  'animationSlow \* sceneDurationFactor' \
  'transformMotionEnabled: motionScale > 0\.05'; do
  rg -q "$contract" "$MOTION" || fail "Motion lost temporary Scene cadence contract: $contract"
done
if rg -n 'RaohaneConfig\.[A-Za-z0-9_]+[[:space:]]*=' "$MOTION"; then
  fail 'Scene motion cadence must not rewrite persisted Style Studio settings'
fi

for contract in \
  'target: RaohaneScenes' \
  'target: RaohaneRecorder' \
  'gameplayRecording: RaohaneRecorder\.recording' \
  'sceneAutomatic: RaohaneScenes\.autoSceneActive' \
  'sceneRule: RaohaneScenes\.activeRule' \
  ': sceneActive \? "scene"' \
  'function sceneActivityDetail\(\): string'; do
  rg -q "$contract" "$CONTEXT" || fail "Context model lost scene activity contract: $contract"
done

for contract in \
  'sceneId: RaohaneScenes\.activeSceneId' \
  'sceneAutomatic: RaohaneContext\.sceneAutomatic' \
  'RaohaneContext\.mode === "scene"' \
  'sceneMarkerVisible:' \
  'gameplayRecording: RaohaneContext\.gameplayRecording' \
  'indicatorIcon: root\.gameplayRecording \? "stop_circle"' \
  'onClicked: RaohaneRecorder\.stop\(\)'; do
  rg -q "$contract" "$CONTEXT_ISLAND" || fail "Context Island 2.0 lost activity contract: $contract"
done

for contract in \
  'active: RaohaneScenes\.activeSceneId' \
  'activeRule: RaohaneScenes\.activeRule' \
  'policy: RaohaneScenes\.activePolicy' \
  'sceneRulePattern: RaohaneContext\.sceneRulePattern' \
  'sceneRuleMatch: RaohaneContext\.sceneRuleMatch'; do
  rg -q "$contract" "$RUNTIME" || fail "Runtime scene diagnostics lost contract: $contract"
done
for contract in \
  'recorder: \{' \
  'recording: RaohaneRecorder\.recording' \
  'owned: RaohaneRecorder\.ownedRecording' \
  'elapsed: RaohaneRecorder\.elapsedSeconds' \
  'error: RaohaneRecorder\.lastError'; do
  rg -q "$contract" "$RUNTIME" || fail "Runtime recorder diagnostics lost contract: $contract"
done

printf 'scenes-boundary-audit: native scene state, reversible policies, explicit exact/prefix/contains rules, Settings management, temporary dock/motion overlays, native gaming actions, Launcher 2.0 scene management, persistent scene-aware Context Island activity and runtime diagnostics are valid\n'
