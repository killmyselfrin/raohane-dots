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
# Always publish typed Qt lists to PwObjectTracker. A converted JavaScript
# variant can become undefined when coerced into QList<QObject*>.
rg -Fq 'property bool initialized: false' "$privacy" \
  || fail 'privacy singleton lacks a startup guard'
rg -Fq 'Component.onCompleted: initialized = true' "$privacy" \
  || fail 'privacy singleton initializes bindings prematurely'
rg -Fq 'objects: root.initialized && Pipewire.nodes' "$privacy" \
  || fail 'node tracker does not receive the native typed Qt list'
rg -Fq 'objects: root.initialized && Pipewire.linkGroups' "$privacy" \
  || fail 'link tracker does not receive the native typed Qt list'
rg -Fq 'root.buildCaptureState(root.refreshRevision,' "$privacy" \
  || fail 'privacy lost native capture state classification'
rg -Fq 'console.warn("[Raohane] Unable to read PipeWire capture graph:"' "$privacy" \
  || fail 'privacy snapshot has no failure-safe fallback'
for marker in 'microphoneActive: false' 'cameraActive: false' 'recordingActive: false' \
              'unclassifiedVideoCaptureActive: false' 'microphoneApp: ""' \
              'cameraApp: ""' 'recordingApp: ""'; do
  rg -Fq "$marker" "$privacy" || fail "privacy startup default missing $marker"
done
if rg -Fq 'readonly property var trackedObjects' "$privacy" \
  || rg -Fq 'function trackableObjects(' "$privacy"; then
  fail 'privacy reintroduced intermediate JavaScript QObject list'
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
