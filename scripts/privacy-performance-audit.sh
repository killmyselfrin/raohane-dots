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
rg -q 'Pipewire\.nodes\??\.values' "$privacy" \
  || fail 'privacy does not observe native PipeWire nodes'
rg -q 'Pipewire\.linkGroups\??\.values' "$privacy" \
  || fail 'privacy does not observe native PipeWire link groups'
rg -q 'PwObjectTracker[[:space:]]*\{' "$privacy" \
  || fail 'privacy does not bind node properties and link states'
rg -q 'PwLinkState\.Active' "$privacy" \
  || fail 'privacy no longer limits capture indicators to active graph links'
# PipeWire ObjectModel.values is a typed QML list. At startup the lists can
# be temporarily unavailable and some Qt versions reject JS iterable syntax.
# Guard the graph and output fields, keeping PwObjectTracker.objects defined.
rg -Fq 'function trackableObjects(nodes, linkGroups): var' "$privacy" \
  || fail 'privacy no longer normalizes Qt object lists'
rg -Fq 'readonly property var trackedObjects: root.trackableObjects(' "$privacy" \
  || fail 'privacy tracker can receive an uninitialized object list'
rg -Fq 'Pipewire.nodes?.values ?? []' "$privacy" \
  || fail 'privacy nodes lack startup-safe list fallback'
rg -Fq 'Pipewire.linkGroups?.values ?? []' "$privacy" \
  || fail 'privacy link groups lack startup-safe list fallback'
rg -Fq 'root.captureState?.microphoneActive ?? false' "$privacy" \
  || fail 'privacy active indicators no longer guard pending capture state'
rg -Fq 'root.captureState?.recordingApp ?? ""' "$privacy" \
  || fail 'privacy capture app labels no longer guard pending state'
if rg -Fq '[...root.graphNodes' "$privacy" || rg -Fq 'for (const group of linkGroups' "$privacy" \
  || rg -Fq 'for (const node of nodes' "$privacy"; then
  fail 'privacy uses JS iteration syntax that can fail on Qt object lists'
fi
for property in 'media\.class' 'media\.category' 'media\.role' 'application\.name'; do
  rg -q "$property" "$privacy" || fail "privacy lost capture metadata contract: $property"
done

if rg -n '\b(pw-mon|pw-dump|wpctl)\b|RaohanePipeWire\.|Quickshell\.Io|Process[[:space:]]*\{|Timer[[:space:]]*\{' "$privacy"; then
  fail 'privacy regressed to helper-process or polling based graph inspection'
fi

rg -q '^pipewire$' "$manifest" \
  || fail 'native PipeWire integration still requires the PipeWire runtime'

printf 'privacy-performance-audit: privacy derives active capture state directly from Quickshell PipeWire nodes and links\n'
