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
CONTEXT=modules/raohane/RaohaneContext.qml
RUNTIME=modules/raohane/RaohaneRuntimeProbe.qml
QUICK_CONTROLS=modules/raohane/RaohaneQuickControls.qml
SWITCHER=modules/raohane/RaohaneSceneSwitcher.qml
SETTINGS=modules/raohane/RaohaneSettingsScenes.qml
SETTINGS_REGISTRY=modules/raohane/RaohaneSettingsPageRegistry.qml

for path in "$SCENES" "$SERVICES" "$UI_QMLDIR" "$PATHS" "$SEARCH" "$CONTEXT" "$RUNTIME" "$QUICK_CONTROLS" "$SWITCHER" "$SETTINGS" "$SETTINGS_REGISTRY"; do
  [[ -f "$path" ]] || fail "missing scene integration path: $path"
done

rg -q '^singleton RaohaneScenes 1\.0 RaohaneScenes\.qml$' "$SERVICES" \
  || fail 'RaohaneScenes is not registered in the native services module'
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
  'RaohaneAudio\.toggleMute\(\)' \
  'RaohanePerformance\.toggleGameMode\(\)' \
  'RaohaneNotifications\.silent = !RaohaneNotifications\.silent' \
  'RaohaneIdle\.toggleInhibit\(\)' \
  'RaohaneMedia\.togglePlaying\(\)' \
  'if \(needle\.length === 0\)' \
  'const contextual = root\.gamingActionResults\(\)'; do
  rg -q "$contract" "$SEARCH" || fail "Gaming Launcher actions lost native service contract: $contract"
done
if rg -n '\bhyprctl\b|\bwpctl\b|\bnmcli\b' "$SEARCH"; then
  fail 'contextual Launcher actions bypass native Raohane services'
fi

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
  || fail 'Context Island no longer consumes scene activation events'
rg -q 'scene: RaohaneScenes\.activeSceneId' "$CONTEXT" \
  || fail 'Context diagnostics no longer expose active scene'
rg -q 'active: RaohaneScenes\.activeSceneId' "$RUNTIME" \
  || fail 'Runtime probe no longer exposes active scene'
rg -q 'policy: RaohaneScenes\.activePolicy' "$RUNTIME" \
  || fail 'Runtime probe no longer exposes effective scene policy'

printf 'scenes-boundary-audit: native scene state, reversible policies, event-driven app rules, manual override, Control Center rail, Settings management, contextual Launcher actions and Context/diagnostic integration are valid\n'
