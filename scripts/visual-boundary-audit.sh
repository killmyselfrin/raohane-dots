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
settings_content='modules/raohane/RaohaneSettingsContentV3.qml'
settings_navigation='modules/raohane/RaohaneSettingsNavigation.qml'
settings_header='modules/raohane/RaohaneSettingsPageHeader.qml'
settings_section='modules/raohane/RaohaneSettingsSectionPage.qml'
settings_control='modules/raohane/RaohaneSettingsControlRow.qml'
settings_home='modules/raohane/RaohaneSettingsHome.qml'
bar='modules/raohane/RaohaneBar.qml'
bar_module='modules/raohane/RaohaneBarModule.qml'
vertical='modules/raohane/RaohaneVerticalBar.qml'
dock='modules/raohane/RaohaneDock.qml'
context='modules/raohane/RaohaneContextIsland.qml'
notification='modules/raohane/RaohaneNotificationCard.qml'
surface='modules/raohane/RaohaneSurface.qml'
icon_button='modules/raohane/RaohaneIconButton.qml'
motion='modules/raohane/RaohaneMotion.qml'
slider='modules/raohane/RaohaneSlider.qml'
switch='modules/raohane/RaohaneSwitch.qml'
clock='modules/raohane/RaohaneClock.qml'
quick='modules/raohane/RaohaneQuickControls.qml'
quick_tile='modules/raohane/RaohaneQuickControlTile.qml'
sidebar='modules/raohane/RaohaneSidebarLeft.qml'
session='modules/raohane/RaohaneSessionScreen.qml'
task_manager='modules/raohane/RaohaneTaskManager.qml'
overlay='modules/raohane/RaohaneOverlay.qml'
lock_surface='modules/raohane/RaohaneLockSurface.qml'
polkit='modules/raohane/RaohanePolkit.qml'
dropshelf='modules/raohane/RaohaneDropShelfPanel.qml'
translator='modules/raohane/RaohaneScreenTranslator.qml'
osk='modules/raohane/RaohaneOnScreenKeyboard.qml'
osk_key='modules/raohane/RaohaneOskKey.qml'

for file in \
  "$theme" "$catalog" "$config" "$defaults" "$launcher" "$media" "$control" "$settings" "$settings_content" \
  "$settings_navigation" "$settings_header" "$settings_section" "$settings_control" "$settings_home" "$bar" "$bar_module" "$vertical" "$dock" \
  "$context" "$notification" "$surface" "$icon_button" "$motion" "$slider" "$switch" "$clock" "$quick" "$quick_tile" "$sidebar" \
  "$session" "$task_manager" "$overlay" "$lock_surface" "$polkit" "$dropshelf" "$translator" "$osk" "$osk_key"; do
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

rg -q 'motionScale' "$motion" || fail 'shared motion system no longer consumes persisted motion scale'
rg -q 'RaohaneMotion\.' "$surface" || fail 'shared surface no longer consumes the motion system'
rg -q 'RaohaneIcon[[:space:]]*\{' "$icon_button" || fail 'shared icon button no longer renders through RaohaneIcon'
rg -q 'RaohaneMotion\.' "$icon_button" || fail 'shared icon button lost tactile motion'
rg -q 'RaohaneMotion\.' "$slider" || fail 'shared slider lost tactile motion'
rg -q 'RaohaneMotion\.' "$switch" || fail 'shared switch lost tactile motion'
rg -q 'RaohaneSlider[[:space:]]*\{' "$quick" || fail 'Quick Controls regressed from the shared slider'
rg -q 'RaohaneSlider[[:space:]]*\{' "$media" || fail 'Media Player regressed from the shared slider'
rg -q 'RaohaneSlider[[:space:]]*\{' "$catalog" || fail 'Style Studio regressed from the shared slider'
rg -q 'RaohaneSwitch[[:space:]]*\{' "$catalog" || fail 'Style Studio regressed from the shared switch'
rg -q 'RaohaneSwitch[[:space:]]*\{' "$settings_control" || fail 'Settings control rows regressed from the shared switch'
rg -q 'RaohaneIconButton[[:space:]]*\{' "$settings_control" || fail 'Settings numeric controls regressed from shared icon buttons'
rg -q 'RaohaneIconButton[[:space:]]*\{' "$media" || fail 'Media Player regressed from shared tactile icon buttons'
rg -q 'RaohaneIconButton[[:space:]]*\{' "$control" || fail 'Control Center regressed from shared tactile icon buttons'
rg -q 'RaohaneIconButton[[:space:]]*\{' "$osk" || fail 'OSK shell regressed from shared tactile icon buttons'
rg -q 'RaohaneSettingsControlRow[[:space:]]*\{' "$settings_section" || fail 'Settings section no longer composes reusable control rows'

# The coordinator is intentionally presentation-light. Shared surfaces for
# Settings live in the extracted navigation/header/section implementations.
shared_surfaces=(
  "$launcher" "$media" "$control" "$settings" "$settings_navigation" "$settings_header" "$settings_section" "$settings_home" \
  "$bar" "$vertical" "$dock" "$sidebar" "$session" "$task_manager" "$overlay" "$lock_surface" "$polkit" "$dropshelf" "$translator" "$osk"
)
for file in "${shared_surfaces[@]}"; do
  rg -q 'RaohaneSurface[[:space:]]*\{' "$file" || fail "$file no longer uses the shared RaohaneSurface primitive"
done

raised_surfaces=(
  "$launcher" "$media" "$control" "$settings" "$bar" "$vertical" "$dock"
  "$sidebar" "$session" "$task_manager" "$overlay" "$lock_surface" "$polkit" "$dropshelf" "$translator" "$osk"
)
for file in "${raised_surfaces[@]}"; do
  rg -q 'raised:[[:space:]]*true' "$file" || fail "$file no longer requests a raised primary glass surface"
done

matte_surfaces=(
  "$launcher" "$control" "$settings" "$bar" "$vertical" "$dock"
  "$sidebar" "$session" "$task_manager" "$overlay" "$lock_surface" "$polkit" "$dropshelf" "$translator" "$osk"
)
for file in "${matte_surfaces[@]}"; do
  rg -q 'showSheen:[[:space:]]*false' "$file" || fail "$file no longer suppresses decorative sheen on minimal shell chrome"
done

for file in "$context" "$dock" "$control" "$settings" "$launcher" "$media" "$sidebar" "$session" "$task_manager" "$overlay" "$lock_surface" "$polkit" "$dropshelf" "$translator" "$osk"; do
  rg -q 'RaohaneTheme\.(accent|accentSecondary|accentGlow|accentBorder)' "$file" || fail "$file lost the centralized Raohane accent system"
done

if rg -n '#76171420|#8b2b203b|#841c1826|#1fc56cff' "$quick" "$quick_tile" "$control" "$settings" "$settings_content" "$settings_navigation" "$settings_header" "$settings_section" "$settings_control"; then
  fail 'minimal primary controls contain retired cyber-noir hard-coded colors'
fi
rg -q 'RaohaneTheme\.surfaceSubtle' "$quick_tile" || fail 'Quick Control tiles do not consume minimalist surface tokens'
rg -q 'RaohaneTheme\.borderStrong' "$quick_tile" || fail 'Quick Control tiles do not consume shared minimal borders'
rg -q 'RaohaneTheme\.surfaceSubtle' "$settings_navigation" || fail 'Settings navigation lost the quiet sidebar plane'
rg -q 'RaohaneSettingsNavigation[[:space:]]*\{' "$settings_content" || fail 'Settings coordinator no longer composes extracted navigation'
rg -q 'RaohaneSettingsPageHeader[[:space:]]*\{' "$settings_content" || fail 'Settings coordinator no longer composes extracted page header'

edge_surfaces=("$sidebar" "$session" "$task_manager" "$overlay" "$lock_surface" "$polkit" "$dropshelf" "$translator" "$osk" "$osk_key")
if rg -n '#18ffffff|#20ffffff|#24ffffff|#10ffffff|#12ffffff|#14ffffff|#2affffff|#35ffffff|#63171320|#3814111c|#74120f19|#1fc56cff|#2cff668c|#32ff668c' "${edge_surfaces[@]}"; then
  fail 'a system/edge surface reintroduced retired one-off glass/neon colors'
fi

for file in "$sidebar" "$session" "$task_manager" "$overlay" "$lock_surface" "$polkit" "$dropshelf" "$translator" "$osk"; do
  rg -q 'RaohaneIcon(Button)?[[:space:]]*\{' "$file" || fail "$file no longer uses the shared Material-symbol icon system"
done

if rg -n 'RAOHANE / SIDE|RAOHANE / SESSION|RAOHANE / LOCK|RAOHANE / POLKIT|RAOHANE / OVERLAY|text:[[:space:]]*"[⌕◎▧文⚙⏻⏮⏭♪⌨ラ⌫↵]"' \
  "$sidebar" "$session" "$task_manager" "$overlay" "$lock_surface" "$polkit" "$dropshelf" "$translator" "$osk" "$osk_key" "$launcher" "$bar" "$vertical"; then
  fail 'an active surface regressed to decorative legacy labels or arbitrary glyph controls'
fi

rg -q 'implicitHeight:[[:space:]]*64' "$bar" || fail 'horizontal bar lost the floating-pod compositor height contract'
rg -q 'podHeight:[[:space:]]*Math\.max\(38,[[:space:]]*Math\.min\(48,' "$bar" || fail 'horizontal bar lost safe advanced pod-height bounds'
rg -q 'barScale' "$bar" || fail 'horizontal bar does not consume persisted advanced scale'
rg -q 'RaohaneBarModule[[:space:]]*\{' "$bar" || fail 'horizontal bar no longer composes through the native module host'
rg -q 'RaohaneBarModule[[:space:]]*\{' "$vertical" || fail 'vertical bar no longer composes through the native module host'
rg -q 'orientation:[[:space:]]*"vertical"' "$vertical" || fail 'vertical bar does not request vertical module presentation'
rg -q 'RaohaneContextIsland[[:space:]]*\{' "$bar_module" || fail 'horizontal bar module host lost the centered Context Island'
rg -q 'RaohaneIconButton[[:space:]]*\{' "$bar_module" || fail 'shared bar module host no longer uses tactile icon buttons'
rg -q 'RaohaneClock[[:space:]]*\{' "$bar_module" || fail 'horizontal bar module host lost the shared clock hierarchy'
rg -q 'RaohaneTheme\.(textMuted|textFaint)' "$bar_module" || fail 'shared bar module host lost restrained vertical text hierarchy'
rg -q 'RaohaneTheme\.(textMuted|textFaint)' "$icon_button" || fail 'shared icon button lost restrained secondary icon hierarchy'
rg -q 'RaohaneTheme\.(textMuted|textFaint)' "$clock" || fail 'shared clock lost restrained secondary text hierarchy'
rg -q 'RaohaneTheme\.islandHeight' "$context" || fail 'Context Island no longer derives from the shared height token'

rg -q 'source:[[:space:]]*RaohaneConfig\.wallpaperPath' "$settings_home" || fail 'Settings home lost its live wallpaper hero'
rg -q 'RaohaneContextIsland[[:space:]]*\{' "$settings_home" || fail 'Settings home lost the Context Island live preview'

if rg -n 'RAOHANE / LAUNCHER|LIVE CONFIG|id:[[:space:]]*hero' "$launcher" "$media" "$control" "$settings"; then
  fail 'a primary surface regressed to legacy one-off chrome'
fi

for file in "$launcher" "$media" "$control" "$dock" "$sidebar" "$session" "$task_manager" "$overlay" "$lock_surface" "$polkit" "$dropshelf" "$translator"; do
  rg -q 'RaohaneTheme\.(textMuted|textFaint)' "$file" || fail "$file lost restrained secondary text hierarchy"
done
rg -q 'RaohaneTheme\.(textMuted|textFaint)' "$settings_navigation" || fail 'Settings navigation lost restrained secondary text hierarchy'
rg -q 'RaohaneTheme\.(textMuted|textFaint)' "$settings_header" || fail 'Settings page header lost restrained secondary text hierarchy'
rg -q 'RaohaneTheme\.(textMuted|textFaint)' "$settings_section" || fail 'Settings section renderer lost restrained secondary text hierarchy'
rg -q 'RaohaneTheme\.(textMuted|textFaint)' "$settings_control" || fail 'Settings control row lost restrained secondary text hierarchy'

printf 'visual-boundary-audit: minimalist themes, coordinator-based Settings V3 with extracted navigation/header and reusable control rows, shared motion/slider/switch/icon controls, composable horizontal/vertical bars, registry-backed Quick Controls, Task Manager/Command Deck, persisted Style Studio/Advanced Surfaces, matte shell/system chrome and stable geometry are valid\n'
