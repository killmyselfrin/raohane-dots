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

rg -q 'function refresh\(\): void' "$SERVICE" \
  || fail 'EasyEffects service lost explicit refresh contract'
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
rg -q 'repeat:[[:space:]]*false' "$SERVICE" \
  || fail 'EasyEffects post-action verification must remain one-shot'

if rg -n 'interval:[[:space:]]*(5000|[1-4][0-9]{3})' "$SERVICE"; then
  fail 'EasyEffects service reintroduced frequent background polling'
fi
if rg -n 'repeat:[[:space:]]*true' "$SERVICE"; then
  fail 'EasyEffects service must not run a repeating state poll'
fi

rg -q 'RaohaneEasyEffects\.refresh\(\)' "$CONTROL" \
  || fail 'Control Center must refresh EasyEffects state when opened'
rg -q 'onControlCenterOpenChanged' "$CONTROL" \
  || fail 'Control Center lost open-state refresh hook'

printf 'easyeffects-performance-audit: EasyEffects actions use one-shot verified state transitions without background polling\n'
