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
notification='modules/raohane/RaohaneNotificationCard.qml'
surface='modules/raohane/RaohaneSurface.qml'
quick='modules/raohane/RaohaneQuickControls.qml'
sidebar='modules/raohane/RaohaneSidebarLeft.qml'
session='modules/raohane/RaohaneSessionScreen.qml'
lock_surface='modules/raohane/RaohaneLockSurface.qml'
polkit='modules/raohane/RaohanePolkit.qml'
dropshelf='modules/raohane/RaohaneDropShelfPanel.qml'
translator='modules/raohane/RaohaneScreenTranslator.qml'
osk='modules/raohane/RaohaneOnScreenKeyboard.qml'
osk_key='modules/raohane/RaohaneOskKey.qml'

for file in \
  "$theme" "$catalog" "$config" "$defaults" "$launcher" "$media" "$control" "$settings" \
  "$settings_home" "$bar" "$vertical" "$dock" "$context" "$notification" "$surface" "$quick" \
  "$sidebar" "$session" "$lock_surface" "$polkit" "$dropshelf" "$translator" "$osk" "$osk_key"; do
  [[ -f "$file" ]] || fail "missing visual surface: $file"
done

for token in \
  background backgroundElevated surface surfaceRaised surfaceDeep surfaceSubtle \
  surfaceHover surfacePressed border borderStrong borderFaint highlight \
  text textMuted textFaint accent accentSecondary accentBlue accentSoft \
  accentHover accentPressed accentGlow accentBorder success warning critical info \
  radiusTiny radiusSmall radius radiusLarge radiusHero animationFast animationDuration animationSlow; do
  rg -q "property .* ${token}:" "$theme" || fail "theme lost design token: $token"
done

rg -q 'RaohaneConfig\.themePreset' "$theme" || fail 'theme engine is not driven by persisted RaohaneConfig selection'
rg -q 'readonly property var presets:' "$theme" || fail 'theme engine lost its preset catalog'
for preset in zen-mist paper sakura matcha slate sand sumi midnight; do
  rg -q "id:[[:space:]]*\"${preset}\"" "$theme" || fail "theme preset missing: $preset"
done
rg -q 'property string themePreset:[[:space:]]*"zen-mist"' "$config" || fail 'native config does not default to Zen Mist'
rg -q '"themePreset"[[:space:]]*:[[:space:]]*"zen-mist"' "$defaults" || fail 'native defaults do not select Zen Mist'
rg -q 'RaohaneTheme\.presets' "$catalog" || fail 'Theme Library does not consume the shared preset source'
rg -q 'RaohaneConfig\.themePreset[[:space:]]*=' "$catalog" || fail 'Theme Library cannot apply a preset live'

if rg -n '^[[:space:]]*(topPadding|bottomPadding):' "$catalog"; then
  fail 'Theme Library uses padding properties unsupported by QtQuick.Layouts ColumnLayout'
fi

for key in \
  glassOpacity borderStrength radiusScale densityScale motionScale accentStrength accentMode customAccent sheenEnabled \
  barScale dockHoverScale contextIslandScale contextIslandDetail contextIslandIndicators \
  notificationScale notificationCompact notificationBodyLines; do
  rg -q "${key}" "$config" || fail "native style schema missing: $key"
  rg -q "\"${key}\"" "$defaults" || fail "native style defaults missing: $key"
done
for key in barScale dockHoverScale contextIslandScale contextIslandDetail contextIslandIndicators notificationScale notificationCompact notificationBodyLines; do
  rg -q "${key}" "$catalog" || fail "Advanced Surfaces UI missing: $key"
done
rg -q 'dockHoverScale' "$dock" || fail 'Dock does not consume advanced hover scale'
rg -q 'contextIslandScale' "$context" || fail 'Context Island does not consume advanced scale'
rg -q 'contextIslandDetail' "$context" || fail 'Context Island does not consume detail visibility'
rg -q 'contextIslandIndicators' "$context" || fail 'Context Island does not consume indicator visibility'
rg -q 'notificationScale' "$notification" || fail 'Notification card does not consume advanced scale'
rg -q 'notificationCompact' "$notification" || fail 'Notification card does not consume compact mode'
rg -q 'notificationBodyLines' "$notification" || fail 'Notification card does not consume body-line limit'

rg -q 'property bool raised:[[:space:]]*false' "$surface" || fail 'RaohaneSurface lost its raised-state contract'
rg -q 'property bool active:[[:space:]]*false' "$surface" || fail 'RaohaneSurface lost its active-state contract'
rg -q 'property bool hovered:[[:space:]]*false' "$surface" || fail 'RaohaneSurface lost its hovered-state contract'
rg -q 'RaohaneTheme\.surfaceRaised' "$surface" || fail 'RaohaneSurface no longer owns the raised surface token'
rg -q 'RaohaneTheme\.accentBorder' "$surface" || fail 'RaohaneSurface no longer owns the active accent-border token'
rg -q 'showSheen' "$surface" || fail 'RaohaneSurface lost the shared glass highlight contract'

shared_surfaces=(
  "$launcher" "$media" "$control" "$settings" "$settings_home" "$bar" "$vertical" "$dock"
  "$sidebar" "$session" "$lock_surface" "$polkit" "$dropshelf" "$translator" "$osk"
)
for file in "${shared_surfaces[@]}"; do
  rg -q 'RaohaneSurface[[:space:]]*\{' "$file" || fail "$file no longer uses the shared RaohaneSurface primitive"
done

raised_surfaces=(
  "$launcher" "$media" "$control" "$settings" "$bar" "$vertical" "$dock"
  "$sidebar" "$session" "$lock_surface" "$polkit" "$dropshelf" "$translator" "$osk"
)
for file in "${raised_surfaces[@]}"; do
  rg -q 'raised:[[:space:]]*true' "$file" || fail "$file no longer requests a raised primary glass surface"
done

# Shell/system chrome is deliberately matte. Media is the single content-heavy
# focal-surface exception: its artwork/lyrics presentation may keep the shared
# optional sheen without changing the rest of the shell language.
matte_surfaces=(
  "$launcher" "$control" "$settings" "$bar" "$vertical" "$dock"
  "$sidebar" "$session" "$lock_surface" "$polkit" "$dropshelf" "$translator" "$osk"
)
for file in "${matte_surfaces[@]}"; do
  rg -q 'showSheen:[[:space:]]*false' "$file" || fail "$file no longer suppresses decorative sheen on minimal shell chrome"
done

for file in "$context" "$dock" "$control" "$settings" "$launcher" "$media" "$sidebar" "$session" "$lock_surface" "$polkit" "$dropshelf" "$translator" "$osk"; do
  rg -q 'RaohaneTheme\.(accent|accentSecondary|accentGlow|accentBorder)' "$file" || fail "$file lost the centralized Raohane accent system"
done

if rg -n '#76171420|#8b2b203b|#841c1826|#1fc56cff' "$quick" "$control" "$settings"; then
  fail 'minimal primary controls contain retired cyber-noir hard-coded colors'
fi
rg -q 'RaohaneTheme\.surfaceSubtle' "$quick" || fail 'Quick Controls do not consume minimalist surface tokens'
rg -q 'RaohaneTheme\.borderStrong' "$quick" || fail 'Quick Controls do not consume shared minimal borders'

edge_surfaces=("$sidebar" "$session" "$lock_surface" "$polkit" "$dropshelf" "$translator" "$osk" "$osk_key")
if rg -n '#18ffffff|#20ffffff|#24ffffff|#10ffffff|#12ffffff|#14ffffff|#2affffff|#35ffffff|#63171320|#3814111c|#74120f19|#1fc56cff|#2cff668c|#32ff668c' "${edge_surfaces[@]}"; then
  fail 'a system/edge surface reintroduced retired one-off glass/neon colors'
fi

for file in "$sidebar" "$session" "$lock_surface" "$polkit" "$dropshelf" "$translator" "$osk"; do
  rg -q 'RaohaneIcon[[:space:]]*\{' "$file" || fail "$file no longer uses the shared Material-symbol icon wrapper"
done

if rg -n 'RAOHANE / SIDE|RAOHANE / SESSION|RAOHANE / LOCK|RAOHANE / POLKIT|text:[[:space:]]*"[⌕◎▧文⚙⏻⏮⏭]"' \
  "$sidebar" "$session" "$lock_surface" "$polkit" "$dropshelf" "$translator"; then
  fail 'a system surface regressed to decorative legacy labels or arbitrary glyph controls'
fi

rg -q 'implicitHeight:[[:space:]]*64' "$bar" || fail 'horizontal bar lost the floating-pod compositor height contract'
rg -q 'podHeight:[[:space:]]*Math\.max\(38,[[:space:]]*Math\.min\(48,' "$bar" || fail 'horizontal bar lost safe advanced pod-height bounds'
rg -q 'barScale' "$bar" || fail 'horizontal bar does not consume persisted advanced scale'
rg -q 'RaohaneContextIsland[[:space:]]*\{' "$bar" || fail 'horizontal bar lost the centered Context Island'
rg -q 'RaohaneTheme\.islandHeight' "$context" || fail 'Context Island no longer derives from the shared height token'

rg -q 'source:[[:space:]]*RaohaneConfig\.wallpaperPath' "$settings_home" || fail 'Settings home lost its live wallpaper hero'
rg -q 'RaohaneContextIsland[[:space:]]*\{' "$settings_home" || fail 'Settings home lost the Context Island live preview'

if rg -n 'RAOHANE / LAUNCHER|LIVE CONFIG|id:[[:space:]]*hero' "$launcher" "$media" "$control" "$settings"; then
  fail 'a primary surface regressed to legacy one-off chrome'
fi

for file in "$launcher" "$media" "$control" "$settings" "$bar" "$vertical" "$dock" "$sidebar" "$session" "$lock_surface" "$polkit" "$dropshelf" "$translator"; do
  rg -q 'RaohaneTheme\.(textMuted|textFaint)' "$file" || fail "$file lost restrained secondary text hierarchy"
done

printf 'visual-boundary-audit: minimalist themes, persisted Style Studio/Advanced Surfaces, matte shell/system chrome, shared focal media material and stable geometry are valid\n'
