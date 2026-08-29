#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'visual-boundary-audit: %s\n' "$*" >&2
  exit 1
}

theme='modules/raohane/RaohaneTheme.qml'
launcher='modules/raohane/RaohaneLauncher.qml'
media='modules/raohane/RaohaneMediaOverlay.qml'
control='modules/raohane/RaohaneControlCenter.qml'
settings='modules/raohane/RaohaneSettings.qml'
bar='modules/raohane/RaohaneBar.qml'

for file in "$theme" "$launcher" "$media" "$control" "$settings" "$bar"; do
  [[ -f "$file" ]] || fail "missing visual surface: $file"
done

for token in background surface surfaceRaised surfaceHover surfacePressed borderStrong textFaint accentHover radiusSmall radiusLarge animationDuration; do
  rg -q "property .* ${token}:" "$theme" || fail "theme lost design token: $token"
done

for file in "$launcher" "$media" "$control" "$settings"; do
  rg -q 'RaohaneTheme\.surfaceRaised' "$file" || fail "$file no longer uses the shared raised surface token"
done

rg -q 'RaohaneTheme\.surface' "$bar" || fail 'bar no longer uses the shared surface token'
rg -q 'implicitHeight:[[:space:]]*56' "$bar" || fail 'bar regressed to oversized chrome'

if rg -n 'RAOHANE / LAUNCHER|width:[[:space:]]*4.*accent|LIVE CONFIG|RAOHANE / MEDIA|id:[[:space:]]*hero' \
  "$launcher" "$media" "$control" "$settings"; then
  fail 'a redesigned primary surface regressed to heavy legacy chrome'
fi

for file in "$launcher" "$media" "$control" "$settings" "$bar"; do
  rg -q 'RaohaneTheme\.(textMuted|textFaint)' "$file" || fail "$file lost restrained secondary text hierarchy"
done

printf 'visual-boundary-audit: minimal palette, spacing and primary-surface hierarchy are valid\n'
