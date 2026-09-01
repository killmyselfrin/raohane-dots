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
pipewire='modules/raohane/services/RaohanePipeWire.qml'

for path in "$audio" "$privacy" "$pipewire"; do
  [[ -f "$path" ]] || fail "missing PipeWire surface/service: $path"
  if rg -n 'function[[:space:]]+[A-Za-z0-9_]+\([^)]*:[[:space:]]*[A-Za-z0-9_]+[[:space:]]*=' "$path"; then
    fail "$path uses a typed function parameter with a default value; deployed Quickshell rejects this syntax"
  fi
done

for path in "$audio" "$privacy"; do
  if rg -n '"pw-mon"' "$path"; then
    fail "$path owns a duplicate pw-mon process instead of using RaohanePipeWire"
  fi
  rg -q 'function[[:space:]]+refresh\(force\)' "$path" \
    || fail "$path lost the runtime-compatible optional force signature"
  rg -q 'const forced = force === true' "$path" \
    || fail "$path lost explicit optional-force normalization"
  rg -q 'RaohanePipeWire\.suppressEventsFor' "$path" \
    || fail "$path no longer suppresses its own PipeWire client churn"
  rg -q 'target:[[:space:]]*RaohanePipeWire' "$path" \
    || fail "$path no longer consumes the shared PipeWire graph signal"
  rg -q 'minimumRefreshInterval' "$path" \
    || fail "$path lost probe throttling"
done

rg -q 'command:[[:space:]]*\["pw-mon",[[:space:]]*"--color=never"\]' "$pipewire" \
  || fail 'shared PipeWire service no longer owns the single registry monitor'
rg -q 'signal[[:space:]]+graphChanged' "$pipewire" \
  || fail 'shared PipeWire service lost its graphChanged signal'
rg -q 'id:[[:space:]]*graphDebounce' "$pipewire" \
  || fail 'shared PipeWire monitor lost event debouncing'

rg -q 'volumeProbe\.exec\(' "$audio" \
  || fail 'audio snapshot no longer uses the dedicated probe process'
rg -q '"bash",[[:space:]]*"-c"' "$audio" \
  || fail 'audio snapshot/action shell is no longer explicitly non-login'
rg -q 'minimumRefreshInterval:[[:space:]]*1000' "$audio" \
  || fail 'audio refresh throttling changed unexpectedly'

rg -q 'graphProbe\.exec\(\["pw-dump"\]\)' "$privacy" \
  || fail 'privacy snapshot no longer runs pw-dump directly'
rg -q 'minimumRefreshInterval:[[:space:]]*1600' "$privacy" \
  || fail 'privacy refresh throttling changed unexpectedly'

printf 'pipewire-probe-performance-audit: one shared graph monitor, throttled audio/privacy probes and self-event suppression are active\n'
