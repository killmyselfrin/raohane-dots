#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[[ -n "$ROOT" ]] || ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

patterns='\.config/illogical-impulse|/illogical-impulse/config\.json|Directories\.config[^\n]*illogical-impulse'
roots=(modules services scripts panelFamilies defaults shell.qml GlobalStates.qml ReloadPopup.qml killDialog.qml)
matches=''

for root in "${roots[@]}"; do
  [[ -e "$root" ]] || continue
  if [[ -d "$root" ]]; then
    found="$(grep -RInE \
      --exclude='*.md' \
      --exclude='audit-runtime-paths.sh' \
      --exclude='migrate-runtime-identity.py' \
      --exclude='import-end4-foundation.sh' \
      "$patterns" "$root" 2>/dev/null || true)"
  else
    found="$(grep -nE "$patterns" "$root" 2>/dev/null || true)"
  fi
  if [[ -n "$found" ]]; then
    matches+="$found"$'\n'
  fi
done

if [[ -n "$matches" ]]; then
  echo 'FAIL  active runtime still references the legacy illogical-impulse config path:' >&2
  printf '%s' "$matches" >&2
  exit 1
fi

echo 'PASS  active runtime paths are Raohane-owned'
