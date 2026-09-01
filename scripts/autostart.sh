#!/usr/bin/env bash
set -euo pipefail

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
CONFIG_DIR="$CONFIG_HOME/raohane"
CONFIG_FILE="$CONFIG_DIR/autostart.conf"
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}"
SESSION_KEY="${HYPRLAND_INSTANCE_SIGNATURE:-${WAYLAND_DISPLAY:-session}}"
SESSION_KEY="${SESSION_KEY//[^A-Za-z0-9_.-]/_}"
MARKER="$RUNTIME_DIR/raohane-autostart-${SESSION_KEY}.done"

ensure_config() {
  mkdir -p "$CONFIG_DIR"
  if [[ ! -f "$CONFIG_FILE" ]]; then
    cat > "$CONFIG_FILE" <<'EOF'
# Raohane autostart
# One shell command per line. Empty lines and lines starting with # are ignored.
# Commands run once per Hyprland session, even if the Raohane shell is restarted.
#
# Examples:
# nm-applet --indicator
# blueman-applet
EOF
  fi
}

install_managed_keybinds() {
  command -v hyprctl >/dev/null 2>&1 || return 0

  # Hyprland 0.55+ uses Lua configuration. Apply Raohane's small set of
  # shell-owned emergency/workflow binds at runtime as well as through the
  # installer-generated config so an upgraded shell can self-heal stale binds.
  local lua_code
  lua_code="$(cat <<'LUA'
hl.unbind("ALT + Q")
hl.unbind("SUPER + SHIFT + S")
hl.bind("ALT + Q", hl.dsp.window.close(), { description = "Raohane: Close active window" })
hl.bind("SUPER + SHIFT + S", hl.dsp.global("quickshell:regionScreenshot"), { description = "Raohane: Region screenshot" })
LUA
)"

  if hyprctl eval "$lua_code" >/dev/null 2>&1; then
    return 0
  fi

  # Hyprland <=0.54 fallback. Ignore individual failures so user autostart is
  # never blocked merely because the compositor changed one keyword shape.
  hyprctl keyword unbind "ALT,Q" >/dev/null 2>&1 || true
  hyprctl keyword unbind "SUPER SHIFT,S" >/dev/null 2>&1 || true
  hyprctl keyword bind "ALT,Q,killactive," >/dev/null 2>&1 || true
  hyprctl keyword bind "SUPER SHIFT,S,global,quickshell:regionScreenshot" >/dev/null 2>&1 || true
}

run_once() {
  ensure_config

  # Managed compositor binds are deliberately refreshed on every Raohane start,
  # even when normal user autostart commands already ran earlier this session.
  install_managed_keybinds

  [[ -e "$MARKER" ]] && exit 0

  # Claim the session before spawning commands so simultaneous shell starts do
  # not duplicate applications.
  : > "$MARKER"

  while IFS= read -r raw || [[ -n "$raw" ]]; do
    command="${raw#"${raw%%[![:space:]]*}"}"
    command="${command%"${command##*[![:space:]]}"}"
    [[ -z "$command" || "$command" == \#* ]] && continue

    setsid bash -lc "$command" >/dev/null 2>&1 &
  done < "$CONFIG_FILE"
}

case "${1:-run}" in
  run)
    run_once
    ;;
  rerun)
    rm -f "$MARKER"
    run_once
    ;;
  reset)
    rm -f "$MARKER"
    ;;
  status)
    ensure_config
    printf 'Config: %s\n' "$CONFIG_FILE"
    if [[ -e "$MARKER" ]]; then
      printf 'Session: already executed\n'
    else
      printf 'Session: pending\n'
    fi
    ;;
  config)
    ensure_config
    printf '%s\n' "$CONFIG_FILE"
    ;;
  *)
    echo "Usage: $0 [run|rerun|reset|status|config]" >&2
    exit 2
    ;;
esac
