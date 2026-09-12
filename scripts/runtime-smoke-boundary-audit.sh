#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'runtime-smoke-boundary-audit: %s\n' "$*" >&2
  exit 1
}

smoke='scripts/runtime-smoke-check.sh'
payload='scripts/validate-runtime-payload.sh'
pruner='scripts/prune-runtime.sh'
phase4_audit='scripts/phase4-visible-runtime-audit.sh'

for file in "$smoke" "$payload" "$pruner" "$phase4_audit"; do
  [[ -f "$file" ]] || fail "missing runtime-smoke boundary file: $file"
done

bash -n "$smoke"

for contract in \
  'qs -c "\$QS_CONFIG" ipc call runtime phase4' \
  'ActiveEnterTimestamp' \
  'journalctl --user -u "\$SERVICE"' \
  '--log-file' \
  '--strict-logs' \
  'QQmlApplicationEngine failed to load' \
  'is not a type' \
  'ReferenceError:' \
  'TypeError:' \
  'Unable to assign' \
  'Cannot assign' \
  'Detected anchors on an item that is managed by a layout' \
  'Binding loop detected' \
  'Runtime smoke validation: PASS'; do
  rg -q -- "$contract" "$smoke" || fail "runtime smoke validator lost contract: $contract"
done

if rg -q '_COMM=qs|journalctl.*qs[^a-zA-Z]' "$smoke"; then
  fail 'runtime smoke validator scans generic qs journals and may mix unrelated Quickshell configs'
fi

rg -q 'scripts/runtime-smoke-check\.sh' "$payload" \
  || fail 'runtime payload does not require runtime-smoke-check.sh'
rg -q 'runtime-smoke-check\.sh has invalid shell syntax' "$payload" \
  || fail 'runtime payload does not syntax-check runtime-smoke-check.sh'
rg -q 'runtime-smoke-check\.sh' "$pruner" \
  || fail 'runtime pruner does not protect runtime-smoke-check.sh'
rg -q 'runtime_smoke=' "$phase4_audit" \
  || fail 'Phase 4 boundary does not track runtime smoke validator'

printf 'runtime-smoke-boundary-audit: live IPC, current-service log isolation, high-signal QML signatures and runtime payload retention are valid\n'
