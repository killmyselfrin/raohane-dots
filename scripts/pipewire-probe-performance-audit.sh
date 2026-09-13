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
legacy='modules/raohane/services/RaohanePipeWire.qml'
qmldir='modules/raohane/services/qmldir'

for path in "$audio" "$privacy" "$qmldir"; do
  [[ -f "$path" ]] || fail "missing native PipeWire contract: $path"
done
[[ ! -e "$legacy" ]] || fail 'retired RaohanePipeWire subprocess watcher returned'
if rg -n '^singleton RaohanePipeWire ' "$qmldir"; then
  fail 'retired RaohanePipeWire singleton is still registered'
fi

for path in "$audio" "$privacy"; do
  rg -q '^import Quickshell\.Services\.Pipewire$' "$path" \
    || fail "$path does not use Quickshell native PipeWire API"
  rg -q 'PwObjectTracker[[:space:]]*\{' "$path" \
    || fail "$path does not bind the native PipeWire objects it reads"
  if rg -n '\b(pw-mon|pw-dump|wpctl)\b|RaohanePipeWire\.|Quickshell\.Io|Process[[:space:]]*\{|Timer[[:space:]]*\{' "$path"; then
    fail "$path regressed to subprocess or polling based PipeWire state"
  fi
  if rg -n 'function[[:space:]]+[A-Za-z0-9_]+\([^)]*:[[:space:]]*[A-Za-z0-9_]+[[:space:]]*=' "$path"; then
    fail "$path uses a typed function parameter with a default value; deployed Quickshell rejects this syntax"
  fi
done

for contract in \
  'Pipewire\.defaultAudioSink' \
  'Pipewire\.defaultAudioSource' \
  'Pipewire\.nodes\.values' \
  'Pipewire\.preferredDefaultAudioSink[[:space:]]*=' \
  'Pipewire\.preferredDefaultAudioSource[[:space:]]*=' \
  'root\.sinkNode\.audio\.volume[[:space:]]*=' \
  'root\.sourceNode\.audio\.volume[[:space:]]*=' \
  'root\.sinkNode\.audio\.muted[[:space:]]*=' \
  'root\.sourceNode\.audio\.muted[[:space:]]*='; do
  rg -q "$contract" "$audio" || fail "audio lost native PipeWire contract: $contract"
done

for contract in \
  'Pipewire\.nodes\.values' \
  'Pipewire\.linkGroups\.values' \
  'PwLinkState\.Active' \
  'media\.class' \
  'media\.category' \
  'media\.role'; do
  rg -q "$contract" "$privacy" || fail "privacy lost native PipeWire graph contract: $contract"
done

printf 'pipewire-probe-performance-audit: audio and privacy use the native Quickshell PipeWire graph with no helper processes or polling\n'
