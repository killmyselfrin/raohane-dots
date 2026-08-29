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
surface='modules/raohane/RaohaneSurface.qml'

for file in "$theme" "$launcher" "$media" "$control" "$settings" "$bar" "$surface"; do
  [[ -f "$file" ]] || fail "missing visual surface: $file"
done

for token in background surface surfaceRaised surfaceHover surfacePressed borderStrong textFaint accentHover radiusSmall radiusLarge animationDuration; do
  rg -q "property .* ${token}:" "$theme" || fail "theme lost design token: $token"
done

# Launcher consumes the common Raohane surface primitive. The primitive owns
# the direct raised-token binding so individual surfaces do not duplicate it.
rg -q 'RaohaneSurface[[:space:]]*\{' "$launcher" || fail 'launcher no longer uses the shared RaohaneSurface primitive'
rg -q 'raised:[[:space:]]*true' "$launcher" || fail 'launcher no longer requests a raised primary surface'
rg -q 'property bool raised:[[:space:]]*false' "$surface" || fail 'RaohaneSurface lost its raised-state contract'
rg -q 'RaohaneTheme\.surfaceRaised' "$surface" || fail 'RaohaneSurface no longer owns the raised surface token'

for file in "$media" "$control" "$settings"; do
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

printf 'visual-boundary-audit: minimal palette, shared surface primitive, spacing and primary-surface hierarchy are valid\n'
