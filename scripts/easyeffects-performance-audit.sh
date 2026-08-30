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
rg -q 'id:[[:space:]]*refreshTimer' "$SERVICE" \
  || fail 'EasyEffects service lost post-action debounce refresh'
rg -q 'repeat:[[:space:]]*false' "$SERVICE" \
  || fail 'EasyEffects post-action refresh must remain one-shot'

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

printf 'easyeffects-performance-audit: EasyEffects state is refreshed on demand without background polling\n'
