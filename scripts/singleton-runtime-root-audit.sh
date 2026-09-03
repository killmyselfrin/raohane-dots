#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'singleton-runtime-root-audit: %s\n' "$*" >&2
  exit 1
}

SERVICES=modules/raohane/services
PERFORMANCE="$SERVICES/RaohanePerformance.qml"

[[ -f "$PERFORMANCE" ]] || fail 'RaohanePerformance.qml is missing'
rg -q '^pragma Singleton$' "$PERFORMANCE" \
  || fail 'RaohanePerformance lost pragma Singleton'
rg -q '^Singleton[[:space:]]*\{' "$PERFORMANCE" \
  || fail 'RaohanePerformance must use Quickshell Singleton as its runtime root'
if rg -q '^QtObject[[:space:]]*\{' "$PERFORMANCE"; then
  fail 'RaohanePerformance regressed to QtObject; Process/Timer children require a runtime root with a default child property'
fi

while IFS= read -r file; do
  rg -q '^pragma Singleton$' "$file" || continue
  if rg -q '^QtObject[[:space:]]*\{' "$file" \
      && rg -q '^[[:space:]]*(Process|Timer|Connections)[[:space:]]*\{' "$file"; then
    fail "$file declares runtime child objects under QtObject"
  fi
done < <(find "$SERVICES" -maxdepth 1 -type f -name '*.qml' -print | sort)

printf 'singleton-runtime-root-audit: singleton service runtime roots are valid\n'
