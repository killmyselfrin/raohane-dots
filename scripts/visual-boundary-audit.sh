#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'visual-boundary-audit: %s\n' "$*" >&2
  exit 1
}

theme='modules/raohane/RaohaneTheme.qml'
catalog='modules/raohane/RaohaneThemeCatalog.qml'
config='modules/raohane/config/RaohaneConfig.qml'
defaults='defaults/native.json'
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
quick='modules/raohane/RaohaneQuickControls.qml'

for file in \
  "$theme" "$catalog" "$config" "$defaults" "$launcher" "$media" "$control" "$settings" \
  "$settings_home" "$bar" "$vertical" "$dock" "$context" "$surface" "$quick"; do
  [[ -f "$file" ]] || fail "missing visual surface: $file"
done

# Stable visual API: presets may change mood, but components consume one shared
# token vocabulary rather than embedding theme-specific palettes.
for token in \
  background backgroundElevated surface surfaceRaised surfaceDeep surfaceSubtle \
  surfaceHover surfacePressed border borderStrong borderFaint highlight \
  text textMuted textFaint accent accentSecondary accentBlue accentSoft \
  accentHover accentPressed accentGlow accentBorder success warning critical info \
  radiusTiny radiusSmall radius radiusLarge radiusHero animationFast animationDuration animationSlow; do
  rg -q "property .* ${token}:" "$theme" || fail "theme lost design token: $token"
done

rg -q 'RaohaneConfig\.themePreset' "$theme" \
  || fail 'theme engine is not driven by persisted RaohaneConfig selection'
rg -q 'readonly property var presets:' "$theme" \
  || fail 'theme engine lost its preset catalog'
for preset in zen-mist paper sakura matcha slate sand sumi midnight; do
  rg -q "id:[[:space:]]*\"${preset}\"" "$theme" || fail "theme preset missing: $preset"
done
rg -q 'property string themePreset:[[:space:]]*"zen-mist"' "$config" \
  || fail 'native config does not default to Zen Mist'
rg -q '"themePreset"[[:space:]]*:[[:space:]]*"zen-mist"' "$defaults" \
  || fail 'native defaults do not select Zen Mist'
rg -q 'RaohaneTheme\.presets' "$catalog" \
  || fail 'Theme Library does not consume the shared preset source'
rg -q 'RaohaneConfig\.themePreset[[:space:]]*=' "$catalog" \
  || fail 'Theme Library cannot apply a preset live'

# QtQuick.Layouts ColumnLayout does not expose topPadding/bottomPadding. This
# exact mistake parses in our lightweight static path but fails when Quickshell
# instantiates the type, making the entire settings family unavailable.
if rg -n '^[[:space:]]*(topPadding|bottomPadding):' "$catalog"; then
  fail 'Theme Library uses padding properties unsupported by QtQuick.Layouts ColumnLayout'
fi

# Shared surface primitive owns the light/dark frosted-glass hierarchy.
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

# Signature identity surfaces may use an accent, but it must come from the
# central theme engine. The default mood is restrained charcoal/stone rather
# than a hard-coded neon spectrum.
for file in "$context" "$dock" "$control" "$settings" "$launcher" "$media"; do
  rg -q 'RaohaneTheme\.(accent|accentSecondary|accentGlow|accentBorder)' "$file" \
    || fail "$file lost the centralized Raohane accent system"
done

# Quick Controls must be compatible with both light and dark presets. Old
# cyber-noir literals would make the default Zen Mist page visibly inconsistent.
if rg -n '#76171420|#8b2b203b|#841c1826|#1fc56cff' "$quick" "$control" "$settings"; then
  fail 'minimal primary controls contain retired cyber-noir hard-coded colors'
fi
rg -q 'RaohaneTheme\.surfaceSubtle' "$quick" \
  || fail 'Quick Controls do not consume minimalist surface tokens'
rg -q 'RaohaneTheme\.borderStrong' "$quick" \
  || fail 'Quick Controls do not consume shared minimal borders'

# Keep the current UI structure: floating three-pod horizontal bar, Context
# Island and matching vertical mode. The visual direction changes, not layout.
rg -q 'implicitHeight:[[:space:]]*64' "$bar" \
  || fail 'horizontal bar lost the floating-pod compositor height contract'
rg -q 'height:[[:space:]]*RaohaneTheme\.barHeight' "$bar" \
  || fail 'horizontal bar pods no longer follow the shared bar-height token'
rg -q 'RaohaneContextIsland[[:space:]]*\{' "$bar" \
  || fail 'horizontal bar lost the centered Context Island'
rg -q 'RaohaneTheme\.islandHeight' "$context" \
  || fail 'Context Island no longer follows the shared height token'

# Settings Home remains wallpaper-backed and still previews the real context
# island, while the new Theme Library owns complete color-preset selection.
rg -q 'source:[[:space:]]*RaohaneConfig\.wallpaperPath' "$settings_home" \
  || fail 'Settings home lost its live wallpaper hero'
rg -q 'RaohaneContextIsland[[:space:]]*\{' "$settings_home" \
  || fail 'Settings home lost the Context Island live preview'

if rg -n 'RAOHANE / LAUNCHER|LIVE CONFIG|id:[[:space:]]*hero' \
  "$launcher" "$media" "$control" "$settings"; then
  fail 'a primary surface regressed to legacy one-off chrome'
fi

for file in "$launcher" "$media" "$control" "$settings" "$bar" "$vertical" "$dock"; do
  rg -q 'RaohaneTheme\.(textMuted|textFaint)' "$file" \
    || fail "$file lost restrained secondary text hierarchy'
done

printf 'visual-boundary-audit: minimalist theme catalog, shared frosted-glass tokens, floating bars/dock and stable primary-surface hierarchy are valid\n'
