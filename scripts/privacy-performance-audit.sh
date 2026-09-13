#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'privacy-performance-audit: %s\n' "$*" >&2
  exit 1
}

privacy='modules/raohane/RaohanePrivacy.qml'
legacy='modules/raohane/services/RaohanePipeWire.qml'
manifest='install/arch/required.txt'

[[ -f "$privacy" ]] || fail "missing $privacy"
[[ -f "$manifest" ]] || fail "missing $manifest"
[[ ! -e "$legacy" ]] || fail 'retired shared pw-mon service returned'

rg -q '^import Quickshell\.Services\.Pipewire$' "$privacy" \
  || fail 'privacy does not use the native Quickshell PipeWire API'
rg -q 'Pipewire\.nodes\.values' "$privacy" \
  || fail 'privacy does not observe native PipeWire nodes'
rg -q 'Pipewire\.linkGroups\.values' "$privacy" \
  || fail 'privacy does not observe native PipeWire link groups'
rg -q 'PwObjectTracker[[:space:]]*\{' "$privacy" \
  || fail 'privacy does not bind node properties and link states'
rg -q 'PwLinkState\.Active' "$privacy" \
  || fail 'privacy no longer limits capture indicators to active graph links'
for property in 'media\.class' 'media\.category' 'media\.role' 'application\.name'; do
  rg -q "$property" "$privacy" || fail "privacy lost capture metadata contract: $property"
done

if rg -n '\b(pw-mon|pw-dump|wpctl)\b|RaohanePipeWire\.|Quickshell\.Io|Process[[:space:]]*\{|Timer[[:space:]]*\{' "$privacy"; then
  fail 'privacy regressed to helper-process or polling based graph inspection'
fi

rg -q '^pipewire$' "$manifest" \
  || fail 'native PipeWire integration still requires the PipeWire runtime'

printf 'privacy-performance-audit: privacy derives active capture state directly from Quickshell PipeWire nodes and links\n'
