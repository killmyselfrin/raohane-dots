#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'privacy-performance-audit: %s\n' "$*" >&2
  exit 1
}

privacy='modules/raohane/RaohanePrivacy.qml'
manifest='install/arch/required.txt'

[[ -f "$privacy" ]] || fail "missing $privacy"
[[ -f "$manifest" ]] || fail "missing $manifest"

rg -q 'command:[[:space:]]*\["pw-mon",[[:space:]]*"--color=never"\]' "$privacy" \
  || fail 'privacy service is not monitoring PipeWire graph events with pw-mon'
rg -q 'id:[[:space:]]*graphChangeDebounce' "$privacy" \
  || fail 'PipeWire graph changes are not debounced'
rg -q 'id:[[:space:]]*monitorRestart' "$privacy" \
  || fail 'pw-mon does not have a restart path'
rg -q 'interval:[[:space:]]*15000' "$privacy" \
  || fail 'privacy health fallback is missing or no longer slow'
rg -q 'graphProbe\.exec\(\["pw-dump"\]\)' "$privacy" \
  || fail 'privacy state refresh no longer invokes pw-dump directly'
rg -q 'ignoreGraphEventsUntilMs' "$privacy" \
  || fail 'privacy service lost its self-generated PipeWire event guard'
rg -q 'selfEventGuardInterval:[[:space:]]*1500' "$privacy" \
  || fail 'privacy self-event guard interval changed unexpectedly'
rg -q 'minimumRefreshInterval:[[:space:]]*1200' "$privacy" \
  || fail 'privacy refresh throttling was removed or changed unexpectedly'

if rg -n '"bash",[[:space:]]*"-lc"|command -v pw-dump' "$privacy"; then
  fail 'privacy probe regressed to a login shell; invoke pw-dump directly'
fi
if rg -n 'interval:[[:space:]]*(1000|1200|1500)[[:space:]]*$' "$privacy"; then
  fail 'fast permanent privacy polling returned; use pw-mon events instead'
fi

rg -q '^pipewire$' "$manifest" \
  || fail 'required Arch manifest no longer provides pw-mon/pw-dump through pipewire'

printf 'privacy-performance-audit: PipeWire privacy state is guarded, event-driven and login-shell free\n'
