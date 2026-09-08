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
PATHS=modules/raohane/config/RaohanePaths.qml
SEARCH=modules/raohane/services/RaohaneSearch.qml
CONTEXT=modules/raohane/RaohaneContext.qml
RUNTIME=modules/raohane/RaohaneRuntimeProbe.qml

for path in "$SCENES" "$SERVICES" "$PATHS" "$SEARCH" "$CONTEXT" "$RUNTIME"; do
  [[ -f "$path" ]] || fail "missing scene integration path: $path"
done

rg -q '^singleton RaohaneScenes 1\.0 RaohaneScenes\.qml$' "$SERVICES" \
  || fail 'RaohaneScenes is not registered in the native services module'
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

rg -q 'target: RaohaneScenes' "$CONTEXT" \
  || fail 'Context Island no longer consumes scene activation events'
rg -q 'scene: RaohaneScenes\.activeSceneId' "$CONTEXT" \
  || fail 'Context diagnostics no longer expose active scene'
rg -q 'active: RaohaneScenes\.activeSceneId' "$RUNTIME" \
  || fail 'Runtime probe no longer exposes active scene'
rg -q 'policy: RaohaneScenes\.activePolicy' "$RUNTIME" \
  || fail 'Runtime probe no longer exposes effective scene policy'

printf 'scenes-boundary-audit: native scene state, reversible policies, event-driven app rules, manual override, Launcher actions and Context/diagnostic integration are valid\n'
