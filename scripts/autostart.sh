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

run_once() {
  ensure_config
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
