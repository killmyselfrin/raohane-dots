#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'pipewire-probe-performance-audit: %s\n' "$*" >&2
  exit 1
}

audio='modules/raohane/services/RaohaneAudio.qml'
privacy='modules/raohane/RaohanePrivacy.qml'

for path in "$audio" "$privacy"; do
  [[ -f "$path" ]] || fail "missing PipeWire surface/service: $path"
  if rg -n '"bash",[[:space:]]*"-lc"' "$path"; then
    fail "$path invokes a login shell for a PipeWire probe/action"
  fi
  rg -q 'ignoreGraphEventsUntilMs' "$path" \
    || fail "$path lost self-generated PipeWire event suppression"
  rg -q 'minimumRefreshInterval' "$path" \
    || fail "$path lost probe throttling"
done

rg -q 'volumeProbe\.exec\(' "$audio" \
  || fail 'audio snapshot no longer uses the dedicated probe process'
rg -q '"bash",[[:space:]]*"-c"' "$audio" \
  || fail 'audio snapshot/action shell is no longer explicitly non-login'
rg -q 'selfEventGuardInterval:[[:space:]]*1100' "$audio" \
  || fail 'audio self-event guard interval changed unexpectedly'
rg -q 'minimumRefreshInterval:[[:space:]]*800' "$audio" \
  || fail 'audio refresh throttling changed unexpectedly'
rg -q 'Date\.now\(\)[[:space:]]*>=[[:space:]]*root\.ignoreGraphEventsUntilMs' "$audio" \
  || fail 'audio monitor no longer ignores its own probe events'

rg -q 'graphProbe\.exec\(\["pw-dump"\]\)' "$privacy" \
  || fail 'privacy snapshot no longer runs pw-dump directly'
rg -q 'Date\.now\(\)[[:space:]]*>=[[:space:]]*root\.ignoreGraphEventsUntilMs' "$privacy" \
  || fail 'privacy monitor no longer ignores its own pw-dump events'

printf 'pipewire-probe-performance-audit: audio/privacy probes are throttled, self-loop guarded and login-shell free\n'
