#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'privacy-performance-audit: %s\n' "$*" >&2
  exit 1
}

privacy='modules/raohane/RaohanePrivacy.qml'
pipewire='modules/raohane/services/RaohanePipeWire.qml'
manifest='install/arch/required.txt'

[[ -f "$privacy" ]] || fail "missing $privacy"
[[ -f "$pipewire" ]] || fail "missing $pipewire"
[[ -f "$manifest" ]] || fail "missing $manifest"

if rg -n '"pw-mon"' "$privacy"; then
  fail 'privacy service owns its own pw-mon process instead of the shared PipeWire watcher'
fi
rg -q 'target:[[:space:]]*RaohanePipeWire' "$privacy" \
  || fail 'privacy service is not driven by the shared PipeWire graph watcher'
rg -q 'RaohanePipeWire\.suppressEventsFor' "$privacy" \
  || fail 'privacy service lost suppression for its own pw-dump graph churn'
rg -q 'graphProbe\.exec\(\["pw-dump"\]\)' "$privacy" \
  || fail 'privacy state refresh no longer invokes pw-dump directly'
rg -q 'minimumRefreshInterval:[[:space:]]*1600' "$privacy" \
  || fail 'privacy refresh throttling was removed or changed unexpectedly'
rg -q 'interval:[[:space:]]*30000' "$privacy" \
  || fail 'privacy health fallback is missing or no longer slow'

rg -q 'command:[[:space:]]*\["pw-mon",[[:space:]]*"--color=never"\]' "$pipewire" \
  || fail 'shared PipeWire watcher no longer owns pw-mon'
rg -q 'id:[[:space:]]*graphDebounce' "$pipewire" \
  || fail 'shared PipeWire graph changes are not debounced'
rg -q 'id:[[:space:]]*monitorRestart' "$pipewire" \
  || fail 'shared pw-mon watcher does not have a restart path'

if rg -n '"bash",[[:space:]]*"-lc"|command -v pw-dump' "$privacy"; then
  fail 'privacy probe regressed to a login shell; invoke pw-dump directly'
fi
if rg -n 'interval:[[:space:]]*(1000|1200|1500)[[:space:]]*$' "$privacy"; then
  fail 'fast permanent privacy polling returned; use shared PipeWire events instead'
fi

rg -q '^pipewire$' "$manifest" \
  || fail 'required Arch manifest no longer provides pw-mon/pw-dump through pipewire'

printf 'privacy-performance-audit: privacy uses the shared PipeWire watcher, throttled pw-dump snapshots and a slow health fallback\n'
