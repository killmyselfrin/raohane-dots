#!/usr/bin/env bash
set -euo pipefail

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
CONFIG_DIR="$CONFIG_HOME/raohane"
CONFIG_FILE="$CONFIG_DIR/autostart.conf"
HYPR_DIR="$CONFIG_HOME/hypr"
HYPR_LUA_SNIPPET="$HYPR_DIR/raohane.lua"
HYPR_LEGACY_SNIPPET="$HYPR_DIR/raohane.conf"
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

persist_managed_keybinds() {
  command -v python3 >/dev/null 2>&1 || return 0

  if [[ -f "$HYPR_LUA_SNIPPET" ]]; then
    python3 - "$HYPR_LUA_SNIPPET" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
start = "-- Raohane managed core shortcuts"
end = "-- End Raohane managed core shortcuts"
block = """-- Raohane managed core shortcuts
hl.unbind(\"ALT + Q\")
hl.unbind(\"SUPER + SHIFT + S\")
hl.bind(\"ALT + Q\", hl.dsp.window.close(), { description = \"Raohane: Close active window\" })
hl.bind(\"SUPER + SHIFT + S\", hl.dsp.global(\"quickshell:regionScreenshot\"), { description = \"Raohane: Region screenshot\" })
-- End Raohane managed core shortcuts"""
text = path.read_text(encoding="utf-8")
lines = text.splitlines()
out = []
skipping = False
for line in lines:
    if line.strip() == start:
        skipping = True
        continue
    if skipping:
        if line.strip() == end:
            skipping = False
        continue
    out.append(line)
content = "\n".join(out).rstrip() + "\n\n" + block + "\n"
tmp = path.with_suffix(path.suffix + ".tmp")
tmp.write_text(content, encoding="utf-8")
tmp.replace(path)
PY
    return 0
  fi

  if [[ -f "$HYPR_LEGACY_SNIPPET" ]]; then
    python3 - "$HYPR_LEGACY_SNIPPET" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
start = "# Raohane managed core shortcuts"
end = "# End Raohane managed core shortcuts"
block = """# Raohane managed core shortcuts
unbind = ALT, Q
unbind = SUPER SHIFT, S
bind = ALT, Q, killactive
bind = SUPER SHIFT, S, global, quickshell:regionScreenshot
# End Raohane managed core shortcuts"""
text = path.read_text(encoding="utf-8")
lines = text.splitlines()
out = []
skipping = False
for line in lines:
    if line.strip() == start:
        skipping = True
        continue
    if skipping:
        if line.strip() == end:
            skipping = False
        continue
    out.append(line)
content = "\n".join(out).rstrip() + "\n\n" + block + "\n"
tmp = path.with_suffix(path.suffix + ".tmp")
tmp.write_text(content, encoding="utf-8")
tmp.replace(path)
PY
  fi
}

install_managed_keybinds() {
  command -v hyprctl >/dev/null 2>&1 || return 0

  persist_managed_keybinds

  # Hyprland 0.55+ uses Lua configuration. Apply Raohane's small set of
  # shell-owned workflow binds at runtime as well so an upgraded shell can
  # self-heal immediately without requiring a compositor reload.
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
