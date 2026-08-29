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
rg -q 'command -v pw-dump.*pw-dump' "$privacy" \
  || fail 'privacy state refresh no longer uses the native PipeWire dump backend'

if rg -n 'interval:[[:space:]]*(1200|1000|1500)[[:space:]]*$' "$privacy"; then
  fail 'fast permanent privacy polling returned; use pw-mon events instead'
fi

rg -q '^pipewire$' "$manifest" \
  || fail 'required Arch manifest no longer provides pw-mon/pw-dump through pipewire'

printf 'privacy-performance-audit: PipeWire privacy state is event-driven with a slow health fallback\n'
