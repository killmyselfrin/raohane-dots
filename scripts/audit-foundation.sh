#!/usr/bin/env bash
set -euo pipefail

SCRIPT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
GIT_ROOT="$(git -C "$SCRIPT_ROOT" rev-parse --show-toplevel 2>/dev/null || true)"
ROOT="${GIT_ROOT:-$SCRIPT_ROOT}"
cd "$ROOT"

fail=0
pass() { printf 'PASS  %s\n' "$1"; }
warn() { printf 'WARN  %s\n' "$1"; }
bad() { printf 'FAIL  %s\n' "$1" >&2; fail=1; }

required=(
  shell.qml
  GlobalStates.qml
  LICENSE
  modules/common
  modules/ii
  modules/ii/bar
  modules/ii/background
  modules/ii/settings
  modules/ii/mediaControls
  modules/ii/notificationPopup
  modules/ii/onScreenDisplay
  modules/ii/overview
  modules/ii/polkit
  modules/ii/regionSelector
  panelFamilies
  services
  scripts
  translations
)

for path in "${required[@]}"; do
  [[ -e "$path" ]] && pass "foundation path: $path" || bad "missing foundation path: $path"
done

if [[ -f LICENSE ]] && grep -q 'GNU GENERAL PUBLIC LICENSE' LICENSE; then
  pass 'GPL license present'
else
  bad 'GPL license missing or unexpected'
fi

if [[ -f NOTICE-UPSTREAM.md ]] && grep -q 'pctrade/end4-pC' NOTICE-UPSTREAM.md && grep -q 'end-4/dots-hyprland' NOTICE-UPSTREAM.md; then
  pass 'upstream attribution'
else
  bad 'upstream attribution incomplete'
fi

PIN='369554b62de8d659875de828c779b83b28ae9ada'
if [[ -f UPSTREAM-BASE.md ]] && grep -q "$PIN" UPSTREAM-BASE.md; then
  pass 'pinned upstream commit recorded'
else
  bad 'pinned upstream commit not recorded'
fi

font_count="$(find . -type f \( -iname '*.ttf' -o -iname '*.otf' -o -iname '*.woff' -o -iname '*.woff2' -o -iname '*.eot' \) -not -path './.git/*' | wc -l)"
if [[ "$font_count" -eq 0 ]]; then
  pass 'no bundled font binaries'
else
  bad "bundled font binaries detected: $font_count"
fi

while IFS= read -r -d '' file; do
  bash -n "$file" || bad "shell syntax: $file"
done < <(find scripts -type f -name '*.sh' -print0 2>/dev/null)
for file in scripts/raohane scripts/raohane-deps; do
  [[ -f "$file" ]] && bash -n "$file" || true
done
(( fail == 0 )) && pass 'shell script syntax'

qml_count="$(find modules -type f -name '*.qml' 2>/dev/null | wc -l)"
[[ "$qml_count" -gt 50 ]] && pass "QML foundation size: $qml_count files" || warn "unexpectedly small QML foundation: $qml_count files"

if [[ -d migration/legacy-raohane ]]; then
  pass 'pre-reset Raohane migration snapshot present'
elif [[ -n "$GIT_ROOT" ]]; then
  warn 'legacy migration snapshot is absent from development checkout'
else
  pass 'runtime audit mode (migration snapshot intentionally not installed)'
fi

printf '\nFoundation audit summary: '
if (( fail )); then
  printf 'FAIL\n'
  exit 1
else
  printf 'PASS\n'
fi
