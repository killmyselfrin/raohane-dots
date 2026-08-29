#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'keyboard-layout-boundary-audit: %s\n' "$*" >&2
  exit 1
}

installer='install-raohane.sh'
[[ -f "$installer" ]] || fail 'install-raohane.sh is missing'

# Hyprland <=0.54 / hyprlang path. Keep the keyboard setup inside the managed
# Raohane snippet so the rest of the user's input configuration is untouched.
rg -q '^input[[:space:]]*\{$' "$installer" \
  || fail 'legacy Hyprland integration has no managed input block'
rg -q '^[[:space:]]*kb_layout[[:space:]]*=[[:space:]]*us,ru[[:space:]]*$' "$installer" \
  || fail 'legacy Hyprland integration does not configure us,ru layouts'
rg -q '^[[:space:]]*kb_options[[:space:]]*=[[:space:]]*grp:alt_shift_toggle[[:space:]]*$' "$installer" \
  || fail 'legacy Hyprland integration does not configure Alt+Shift layout switching'

# Hyprland 0.55+ / Lua path. This follows Hyprland's native XKB configuration
# API instead of emulating modifier-only switching with a compositor bind.
rg -q 'hl\.config\([[:space:]]*\{' "$installer" \
  || fail 'Hyprland 0.55+ integration has no hl.config input configuration'
rg -q 'kb_layout[[:space:]]*=[[:space:]]*"us,ru"' "$installer" \
  || fail 'Hyprland 0.55+ integration does not configure us,ru layouts'
rg -q 'kb_options[[:space:]]*=[[:space:]]*"grp:alt_shift_toggle"' "$installer" \
  || fail 'Hyprland 0.55+ integration does not configure Alt+Shift layout switching'

# The first layout remains US so symbol-based Raohane binds keep their stable
# physical-key behavior while the active typing layout can be Russian.
if rg -n 'resolve_binds_by_sym[[:space:]]*=[[:space:]]*(1|true)' "$installer"; then
  fail 'layout integration enables resolve_binds_by_sym and can make Raohane hotkeys layout-dependent'
fi

# Do not regress to an Alt/Shift keybind workaround; XKB owns this behavior.
if rg -n -i 'bind[^\n]*(alt[^\n]*shift|shift[^\n]*alt)[^\n]*(switchxkblayout|layout)' "$installer"; then
  fail 'layout switching is implemented as a compositor bind instead of XKB'
fi

printf 'keyboard-layout-boundary-audit: us/ru layouts use native XKB Alt+Shift switching on both Hyprland config paths\n'
