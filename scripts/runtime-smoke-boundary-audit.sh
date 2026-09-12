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
cli='scripts/raohane'

for file in "$smoke" "$payload" "$pruner" "$phase4_audit" "$cli"; do
  [[ -f "$file" ]] || fail "missing runtime-smoke boundary file: $file"
done

bash -n "$smoke"
bash -n "$cli"

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
  grep -Eq -- "$contract" "$smoke" || fail "runtime smoke validator lost contract: $contract"
done

if grep -Eq '_COMM=qs|journalctl.*qs[^a-zA-Z]' "$smoke"; then
  fail 'runtime smoke validator scans generic qs journals and may mix unrelated Quickshell configs'
fi

grep -Eq 'scripts/runtime-smoke-check\.sh' "$payload" \
  || fail 'runtime payload does not require runtime-smoke-check.sh'
grep -Eq 'runtime-smoke-check\.sh has invalid shell syntax' "$payload" \
  || fail 'runtime payload does not syntax-check runtime-smoke-check.sh'
grep -Eq 'runtime-smoke-check\.sh' "$pruner" \
  || fail 'runtime pruner does not protect runtime-smoke-check.sh'
grep -Eq 'runtime_smoke=' "$phase4_audit" \
  || fail 'Phase 4 boundary does not track runtime smoke validator'

for contract in \
  'validate smoke \[--since WHEN\] \[--log-file FILE\] \[--strict-logs\]' \
  'find_runtime_smoke_validator' \
  'run_runtime_smoke_validator' \
  '^[[:space:]]*smoke\)' \
  'run_runtime_smoke_validator "\$@"' \
  '^[[:space:]]*phase4\)' \
  'run_phase4_validator "\$@"' \
  'run_runtime_smoke_validator'; do
  grep -Eq "$contract" "$cli" || fail "Raohane CLI lost runtime-smoke route: $contract"
done

printf 'runtime-smoke-boundary-audit: live IPC, current-service log isolation, high-signal QML signatures, CLI routing and runtime payload retention are valid\n'
