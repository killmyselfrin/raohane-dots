#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

SERVICE="modules/raohane/services/RaohaneEasyEffects.qml"
CONTROL="modules/raohane/RaohaneControlCenter.qml"

fail() {
  printf 'easyeffects-performance-audit: %s\n' "$*" >&2
  exit 1
}

[[ -f "$SERVICE" ]] || fail "missing $SERVICE"
[[ -f "$CONTROL" ]] || fail "missing $CONTROL"

# Control Center may ask for state on every open, but the singleton must cache
# recent results so rapid surface toggles do not spawn pgrep/flatpak repeatedly.
rg -q 'function refresh\(force\): void' "$SERVICE" \
  || fail 'EasyEffects service lost throttled refresh contract'
rg -q 'readonly property int minimumRefreshInterval:[[:space:]]*6000' "$SERVICE" \
  || fail 'EasyEffects state refresh cooldown is missing or too aggressive'
rg -q 'readonly property int availabilityRefreshInterval:[[:space:]]*300000' "$SERVICE" \
  || fail 'EasyEffects availability probe is not cached long enough'
rg -q 'lastRefreshMs' "$SERVICE" \
  || fail 'EasyEffects state snapshots are not cached between surface opens'
rg -q 'lastAvailabilityRefreshMs' "$SERVICE" \
  || fail 'EasyEffects availability result is not cached'

rg -q 'function requestActive\(value: bool\): void' "$SERVICE" \
  || fail 'EasyEffects service lost transactional action entry point'
rg -q 'id:[[:space:]]*actionProcess' "$SERVICE" \
  || fail 'EasyEffects service lost owned action process'
rg -q 'id:[[:space:]]*verifyTimer' "$SERVICE" \
  || fail 'EasyEffects service lost post-action verification debounce'
rg -q 'interval:[[:space:]]*850' "$SERVICE" \
  || fail 'EasyEffects verification debounce changed unexpectedly'
rg -q 'onTriggered:[[:space:]]*root\.fetchActiveState\(\)' "$SERVICE" \
  || fail 'EasyEffects verification no longer reads the actual process state'
rg -q 'function finishVerification\(\): void' "$SERVICE" \
  || fail 'EasyEffects service lost post-action state verification'
rg -q 'signal activeApplied\(bool enabled\)' "$SERVICE" \
  || fail 'EasyEffects service lost confirmed-state signal'
rg -q 'root\.finishVerification\(\)' "$SERVICE" \
  || fail 'EasyEffects state probe no longer completes pending actions'

if rg -n 'repeat:[[:space:]]*true' "$SERVICE"; then
  fail 'EasyEffects service must not run a repeating state poll'
fi

rg -q 'RaohaneEasyEffects\.refresh\(\)' "$CONTROL" \
  || fail 'Control Center must request cached EasyEffects state when opened'
rg -q 'onControlCenterOpenChanged' "$CONTROL" \
  || fail 'Control Center lost open-state refresh hook'

printf 'easyeffects-performance-audit: cached state refresh and one-shot verified actions are valid\n'
