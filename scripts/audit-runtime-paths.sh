#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[[ -n "$ROOT" ]] || ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# The foundation may retain upstream module names during migration, but active
# user data, theme generators and executable helpers must not write into the old
# illogical-impulse/ii namespace or shared Quickshell state locations.
patterns='\.config/illogical-impulse|/illogical-impulse/config\.json|Directories\.config[^\n]*illogical-impulse|QUICKSHELL_CONFIG_NAME="ii"|CACHE_DIR="\$XDG_CACHE_HOME/quickshell"|STATE_DIR="\$XDG_STATE_HOME/quickshell"|/quickshell/(user/generated|states\.json)|property string fileDir: Directories\.state'
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
  echo 'FAIL  active runtime still references a legacy/shared pre-Raohane path:' >&2
  printf '%s' "$matches" >&2
  exit 1
fi

echo 'PASS  active runtime paths are Raohane-owned'
