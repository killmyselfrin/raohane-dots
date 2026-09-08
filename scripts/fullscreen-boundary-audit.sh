#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'fullscreen-boundary-audit: %s\n' "$*" >&2
  exit 1
}

background='modules/raohane/RaohaneBackground.qml'
bar='modules/raohane/RaohaneBar.qml'
vertical='modules/raohane/RaohaneVerticalBar.qml'
dock='modules/raohane/RaohaneDock.qml'
corners='modules/raohane/RaohaneScreenCorners.qml'
frame='modules/raohane/RaohaneScreenFrame.qml'
media='modules/raohane/RaohaneMediaOverlay.qml'

for file in "$background" "$bar" "$vertical" "$dock" "$corners" "$frame" "$media"; do
  [[ -f "$file" ]] || fail "missing fullscreen/game surface: $file"
done

# Wallpaper rendering can be hidden for fullscreen clients. Video wallpapers
# must destroy their MediaPlayer loader while hidden instead of decoding frames
# behind a game.
rg -q 'readonly property bool hiddenForFullscreen:' "$background" \
  || fail 'background lost fullscreen visibility state'
rg -q 'wallpaperHideWhenFullscreen' "$background" \
  || fail 'background lost wallpaper fullscreen preference'
rg -q 'active: backgroundWindow\.currentPath\.length > 0' "$background" \
  || fail 'video wallpaper loader contract changed unexpectedly'
rg -q '&& !backgroundWindow\.hiddenForFullscreen' "$background" \
  || fail 'video wallpaper continues decoding while fullscreen hides it'

# Both bar orientations keep their layer-shell surfaces resident across game
# fullscreen transitions. They must release compositor reservation and pointer
# input, hide their visual content and suspend hosted module work instead of
# destroying/recreating the Wayland surface.
for file in "$bar" "$vertical"; do
  rg -q 'readonly property bool fullscreenSuppressed:[[:space:]]*effectiveFullscreen && !superShow' "$file" \
    || fail "$file lost fullscreen suppression state"
  rg -q 'visible: RaohaneState\.barOpen && !RaohaneState\.screenLocked' "$file" \
    || fail "$file lost resident layer-surface visibility contract"
  rg -q 'readonly property bool contentShown:[[:space:]]*!fullscreenSuppressed && mustShow' "$file" \
    || fail "$file content can remain presented during fullscreen"
  rg -q 'mask:[[:space:]]*Region' "$file" \
    || fail "$file lost fullscreen input mask"
  rg -q 'width: barWindow\.fullscreenSuppressed \? 0 : barWindow\.width' "$file" \
    || fail "$file input mask does not release fullscreen pointer input"
  rg -q 'height: barWindow\.fullscreenSuppressed \? 0 : barWindow\.height' "$file" \
    || fail "$file input mask does not collapse during fullscreen"
  rg -q 'exclusiveZone: fullscreenSuppressed' "$file" \
    || fail "$file can keep reserving compositor space during fullscreen"
  rg -q 'hostActive: barWindow\.visible && !barWindow\.fullscreenSuppressed' "$file" \
    || fail "$file modules can keep active work running while fullscreen-suppressed"
done

# Dock keeps only a tiny reveal edge while fullscreen is active. The same
# reversible reveal behavior may be requested by a Scene, but fullscreen must
# still suppress the dock independently and never reserve workspace space.
rg -q 'readonly property bool fullscreenActive:' "$dock" \
  || fail 'dock lost per-monitor fullscreen detection'
rg -q 'if \(dockWindow\.fullscreenActive \|\| root\.sceneHidePolicy\)' "$dock" \
  || fail 'dock reveal policy no longer preserves fullscreen suppression alongside Scene policy'
rg -q 'return dockWindow\.hoverLatched \|\| root\.forcedOpen' "$dock" \
  || fail 'dock fullscreen/Scene reveal edge no longer honors hover or forced-open'
rg -q '&& !dockWindow\.fullscreenActive' "$dock" \
  || fail 'dock can reserve exclusive space during fullscreen'
rg -q 'readonly property int hiddenHoverHeight:[[:space:]]*5' "$dock" \
  || fail 'dock fullscreen reveal edge is no longer minimal'

# Hot-corner input must be disabled over games; visual rounding may follow its
# own configured mode but cannot leave an interactive mouse-stealing region.
rg -q 'readonly property bool interactionActive:' "$corners" \
  || fail 'screen corners lost interaction state'
rg -q '&& !effectiveFullscreen' "$corners" \
  || fail 'hot corners can remain interactive over fullscreen clients'
rg -q 'item: cornerWindow\.interactionActive \? interactionArea : null' "$corners" \
  || fail 'screen corner input mask is not gated by interactionActive'

# Decorative screen frame must disappear and release its reservation in games.
rg -q 'visible: root\.frameVisibleFor\(side\) && !effectiveFullscreen' "$frame" \
  || fail 'screen frame remains visible over fullscreen clients'
rg -q 'exclusiveZone: visible \? RaohaneConfig\.frameThickness : 0' "$frame" \
  || fail 'screen frame can reserve space while hidden for fullscreen'

# The media overlay is intentionally game-capable: it must stay on the overlay
# layer, follow the focused monitor, and never request keyboard focus.
rg -q 'screen:[[:space:]]*root\.focusedScreen' "$media" \
  || fail 'media overlay is not pinned to the focused game monitor'
rg -q 'WlrLayershell\.layer:[[:space:]]*WlrLayer\.Overlay' "$media" \
  || fail 'media overlay can no longer render over fullscreen clients'
rg -q 'WlrLayershell\.keyboardFocus:[[:space:]]*WlrKeyboardFocus\.None' "$media" \
  || fail 'media overlay may steal keyboard focus from games'

printf 'fullscreen-boundary-audit: resident bars, scene-aware dock suppression, fullscreen input/reveal boundaries and game-capable media overlay are valid\n'
