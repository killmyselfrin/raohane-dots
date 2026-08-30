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
settings_home='modules/raohane/RaohaneSettingsHome.qml'
bar='modules/raohane/RaohaneBar.qml'
vertical='modules/raohane/RaohaneVerticalBar.qml'
dock='modules/raohane/RaohaneDock.qml'
context='modules/raohane/RaohaneContextIsland.qml'
surface='modules/raohane/RaohaneSurface.qml'

for file in \
  "$theme" "$launcher" "$media" "$control" "$settings" "$settings_home" \
  "$bar" "$vertical" "$dock" "$context" "$surface"; do
  [[ -f "$file" ]] || fail "missing visual surface: $file"
done

# Raohane's current design system is intentionally richer than the old neutral
# palette, but it must stay centralized. Primary surfaces should consume these
# tokens instead of growing independent hard-coded visual systems.
for token in \
  background backgroundElevated surface surfaceRaised surfaceDeep surfaceSubtle \
  surfaceHover surfacePressed border borderStrong borderFaint highlight \
  text textMuted textFaint accent accentSecondary accentBlue accentSoft \
  accentHover accentPressed accentGlow accentBorder success warning critical info \
  radiusTiny radiusSmall radius radiusLarge radiusHero animationFast animationDuration animationSlow; do
  rg -q "property .* ${token}:" "$theme" || fail "theme lost design token: $token"
done

# The shared surface primitive owns raised/hover/active color selection and the
# common glass highlight. Consumers request state rather than binding the raw
# surfaceRaised token themselves.
rg -q 'property bool raised:[[:space:]]*false' "$surface" \
  || fail 'RaohaneSurface lost its raised-state contract'
rg -q 'property bool active:[[:space:]]*false' "$surface" \
  || fail 'RaohaneSurface lost its active-state contract'
rg -q 'property bool hovered:[[:space:]]*false' "$surface" \
  || fail 'RaohaneSurface lost its hovered-state contract'
rg -q 'RaohaneTheme\.surfaceRaised' "$surface" \
  || fail 'RaohaneSurface no longer owns the raised surface token'
rg -q 'RaohaneTheme\.accentBorder' "$surface" \
  || fail 'RaohaneSurface no longer owns the active accent-border token'
rg -q 'showSheen' "$surface" \
  || fail 'RaohaneSurface lost the shared glass highlight contract'

for file in "$launcher" "$media" "$control" "$settings" "$settings_home" "$bar" "$vertical" "$dock"; do
  rg -q 'RaohaneSurface[[:space:]]*\{' "$file" \
    || fail "$file no longer uses the shared RaohaneSurface primitive"
done

for file in "$launcher" "$media" "$control" "$settings" "$bar" "$vertical" "$dock"; do
  rg -q 'raised:[[:space:]]*true' "$file" \
    || fail "$file no longer requests a raised primary glass surface"
done

# Signature identity surfaces must visibly consume the neon spectrum but avoid
# independent shader-heavy glow implementations.
for file in "$context" "$dock" "$control" "$settings" "$launcher" "$media"; do
  rg -q 'RaohaneTheme\.(accent|accentSecondary|accentGlow|accentBorder)' "$file" \
    || fail "$file lost the centralized Raohane accent system"
done

# The redesigned horizontal bar deliberately uses a 64px compositor window so
# its 44px pods can float with breathing room. Keep it compact enough that the
# shell does not regress into a conventional full-width panel.
rg -q 'implicitHeight:[[:space:]]*64' "$bar" \
  || fail 'horizontal bar lost the floating-pod compositor height contract'
rg -q 'height:[[:space:]]*RaohaneTheme\.barHeight' "$bar" \
  || fail 'horizontal bar pods no longer follow the shared bar-height token'
rg -q 'RaohaneContextIsland[[:space:]]*\{' "$bar" \
  || fail 'horizontal bar lost the centered Context Island'
rg -q 'RaohaneTheme\.islandHeight' "$context" \
  || fail 'Context Island no longer follows the shared height token'

# Settings home is the visual control deck and must keep a live wallpaper-backed
# hero rather than degrading into a generic list of settings categories.
rg -q 'source:[[:space:]]*RaohaneConfig\.wallpaperPath' "$settings_home" \
  || fail 'Settings home lost its live wallpaper hero'
rg -q 'RaohaneContextIsland[[:space:]]*\{' "$settings_home" \
  || fail 'Settings home lost the Context Island live preview'

# Keep primary chrome free of legacy redesign labels and old one-off visual
# markers that represented pre-design-system experiments.
if rg -n 'RAOHANE / LAUNCHER|LIVE CONFIG|id:[[:space:]]*hero' \
  "$launcher" "$media" "$control" "$settings"; then
  fail 'a redesigned primary surface regressed to legacy one-off chrome'
fi

for file in "$launcher" "$media" "$control" "$settings" "$bar" "$vertical" "$dock"; do
  rg -q 'RaohaneTheme\.(textMuted|textFaint)' "$file" \
    || fail "$file lost restrained secondary text hierarchy"
done

printf 'visual-boundary-audit: cyber-noir tokens, shared neon glass surfaces, floating bars/dock and flagship primary-surface hierarchy are valid\n'
