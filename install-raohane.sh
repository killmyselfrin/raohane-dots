#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
RUNTIME="$CONFIG_HOME/quickshell/raohane"
BIN_DIR="${HOME}/.local/bin"
SYSTEMD_DIR="$CONFIG_HOME/systemd/user"
HYPR_DIR="$CONFIG_HOME/hypr"
HYPR_LEGACY_SNIPPET="$HYPR_DIR/raohane.conf"
HYPR_LUA_SNIPPET="$HYPR_DIR/raohane.lua"
HYPR_AUTOSTART="$HYPR_DIR/raohane-autostart.conf"
HYPR_INTEGRATION="$HYPR_LEGACY_SNIPPET"
RAOHANE_CONFIG="$CONFIG_HOME/raohane"
RAOHANE_CONFIG_FILE="$RAOHANE_CONFIG/config.json"
LEGACY_CONFIG_FILE="$CONFIG_HOME/illogical-impulse/config.json"
INSTALL_DEPS=0
START_AFTER_INSTALL=1
MIGRATE_LEGACY=0
START_FAILED=0

usage() {
  cat <<'EOF'
Raohane installer

Usage:
  ./install-raohane.sh [OPTIONS]

Options:
  --deps            Install the Raohane-owned Arch dependency manifest first.
                    No other shell repository is cloned or executed.
  --migrate-legacy  On first install, import an existing illogical-impulse
                    config if one exists. This is never done implicitly.
  --no-start        Install files and systemd integration without starting Raohane.
  -h, --help        Show this help.

Examples:
  ./install-raohane.sh --deps
  ./install-raohane.sh --deps --no-start
EOF
}

while (($#)); do
  case "$1" in
    --deps) INSTALL_DEPS=1 ;;
    --migrate-legacy) MIGRATE_LEGACY=1 ;;
    --no-start) START_AFTER_INSTALL=0 ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "[Raohane] Unknown installer option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
  echo '[Raohane] Do not run the installer as root.' >&2
  exit 1
fi

if ((INSTALL_DEPS)); then
  [[ -f "$ROOT/scripts/install-deps.sh" ]] || {
    echo '[Raohane] scripts/install-deps.sh is missing.' >&2
    exit 1
  }
  printf '[Raohane] Installing Raohane dependency manifest...\n\n'
  bash "$ROOT/scripts/install-deps.sh" --full
  printf '\n[Raohane] Raohane dependencies installed.\n\n'
fi

missing_core=()
for cmd in hyprctl qs python3; do
  command -v "$cmd" >/dev/null 2>&1 || missing_core+=("$cmd")
done

if ((${#missing_core[@]})); then
  echo '[Raohane] Missing required runtime commands:' >&2
  for cmd in "${missing_core[@]}"; do
    case "$cmd" in
      hyprctl) echo '  - hyprctl (Hyprland)' >&2 ;;
      qs) echo '  - qs (Quickshell)' >&2 ;;
      python3) echo '  - python3' >&2 ;;
    esac
  done
  if ((INSTALL_DEPS == 0)); then
    echo >&2
    echo '[Raohane] On Arch-based systems retry with:' >&2
    echo '  ./install-raohane.sh --deps' >&2
  fi
  exit 1
fi

required_runtime=(
  "scripts/raohane"
  "scripts/raohane-audit.sh"
  "scripts/install-deps.sh"
  "install/arch/required.txt"
  "install/arch/features.txt"
  "modules/common"
  "modules/ii"
  "modules/raohane"
  "services"
  "panelFamilies/IllogicalImpulseFamily.qml"
  "panelFamilies/RaohaneFamily.qml"
)
missing_runtime=()
for path in "${required_runtime[@]}"; do
  [[ -e "$ROOT/$path" ]] || missing_runtime+=("$path")
done

if ((${#missing_runtime[@]})); then
  echo '[Raohane] This checkout is missing required runtime files.' >&2
  printf '  missing: %s\n' "${missing_runtime[@]}" >&2
  echo '[Raohane] Update/re-clone raohane-dots before installing.' >&2
  exit 1
fi

if command -v rg >/dev/null 2>&1; then
  printf '[Raohane] Running static Raohane audit...\n'
  bash "$ROOT/scripts/raohane-audit.sh"
else
  echo '[Raohane] ripgrep (rg) is unavailable; skipping extended static audit.'
fi

printf '[Raohane] Installing Hyprland shell...\n'

systemctl --user stop raohane.service >/dev/null 2>&1 || true
systemctl --user reset-failed raohane.service >/dev/null 2>&1 || true

mkdir -p "$RUNTIME" "$BIN_DIR" "$SYSTEMD_DIR" "$HYPR_DIR" "$RAOHANE_CONFIG"

if [[ ! -f "$RAOHANE_CONFIG_FILE" ]]; then
  if ((MIGRATE_LEGACY)) && [[ -f "$LEGACY_CONFIG_FILE" ]]; then
    cp -a "$LEGACY_CONFIG_FILE" "$RAOHANE_CONFIG_FILE"
    printf '[Raohane] Imported legacy settings from %s\n' "$LEGACY_CONFIG_FILE"
  elif [[ -f "$ROOT/defaults/config.json" ]]; then
    cp -a "$ROOT/defaults/config.json" "$RAOHANE_CONFIG_FILE"
    printf '[Raohane] Seeded settings from Raohane defaults.\n'
  fi
fi

if [[ -f "$RAOHANE_CONFIG_FILE" ]]; then
  python3 - "$RAOHANE_CONFIG_FILE" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
try:
    data = json.loads(path.read_text(encoding="utf-8"))
except (OSError, json.JSONDecodeError) as exc:
    raise SystemExit(f"[Raohane] Invalid config {path}: {exc}")

data["panelFamily"] = "raohane"
tmp = path.with_suffix(path.suffix + ".tmp")
tmp.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
tmp.replace(path)
PY
fi

find "$RUNTIME" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +
cp -a "$ROOT"/. "$RUNTIME"/
rm -f "$RUNTIME/install-raohane.sh"
rm -rf "$RUNTIME/.git" "$RUNTIME/.github" "$RUNTIME/upstream"

install -m 0755 "$ROOT/scripts/raohane" "$BIN_DIR/raohane"

cat > "$SYSTEMD_DIR/raohane.service" <<SERVICE
[Unit]
Description=Raohane shell for Hyprland
PartOf=graphical-session.target
After=graphical-session.target
StartLimitIntervalSec=20
StartLimitBurst=3

[Service]
Type=simple
ExecStart=${BIN_DIR}/raohane run
Restart=on-failure
RestartSec=2
Environment=QT_QPA_PLATFORM=wayland

[Install]
WantedBy=default.target
SERVICE

# Hyprland 0.54 and older compatibility. Hyprland 0.55+ uses raohane.lua below.
cat > "$HYPR_LEGACY_SNIPPET" <<'HYPR'
# Raohane shell integration
# Managed by install-raohane.sh
exec-once = systemctl --user start raohane.service

# Remove inherited shell launcher/binds before owning these combinations.
unbind = SUPER, Super_L
unbind = SUPER, Super_R
unbind = SUPER, R
unbind = SUPER, escape
unbind = SUPER, C
unbind = SUPER SHIFT, M

# Raohane shell controls
bind = SUPER, R, exec, raohane launcher
bind = SUPER, escape, exec, raohane settings
bind = SUPER, C, exec, raohane control
bind = SUPER SHIFT, M, exec, raohane media
HYPR

# Hyprland 0.55+ native Lua integration. This file is required last from
# hyprland.lua so inherited end4 binds cannot re-register after Raohane.
cat > "$HYPR_LUA_SNIPPET" <<'LUA'
-- Raohane shell integration for Hyprland 0.55+
-- Managed by install-raohane.sh

-- end4 binds bare Super twice: Quickshell search and a fuzzel fallback.
-- Raohane deliberately owns neither bare Super_L nor bare Super_R.
hl.unbind("SUPER + SUPER_L")
hl.unbind("SUPER + SUPER_R")

-- Own Raohane combinations after inherited keybind modules have loaded.
hl.unbind("SUPER + R")
hl.unbind("SUPER + Escape")
hl.unbind("SUPER + C")
hl.unbind("SUPER + SHIFT + M")

hl.bind("SUPER + R", hl.dsp.global("quickshell:raohaneLauncherToggle"),
    { description = "Raohane: Launcher" })
hl.bind("SUPER + Escape", hl.dsp.global("quickshell:settingsToggle"),
    { description = "Raohane: Settings" })
hl.bind("SUPER + C", hl.dsp.global("quickshell:sidebarRightToggle"),
    { description = "Raohane: Control Center" })
hl.bind("SUPER + SHIFT + M", hl.dsp.global("quickshell:raohaneMediaOverlayToggle"),
    { description = "Raohane: Media Overlay" })
LUA

if [[ ! -f "$HYPR_AUTOSTART" ]]; then
  cat > "$HYPR_AUTOSTART" <<'HYPR_AUTOSTART'
# Raohane autostart
# Generated by Raohane Settings.
HYPR_AUTOSTART
fi

HYPR_LUA_MAIN="$HYPR_DIR/hyprland.lua"
HYPR_LEGACY_MAIN="$HYPR_DIR/hyprland.conf"
SOURCE_LINE='source = ~/.config/hypr/raohane.conf'
AUTOSTART_SOURCE_LINE='source = ~/.config/hypr/raohane-autostart.conf'

if [[ -f "$HYPR_LUA_MAIN" ]]; then
  HYPR_INTEGRATION="$HYPR_LUA_SNIPPET"
  python3 - "$HYPR_LUA_MAIN" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
marker = "-- Raohane shell integration (managed by install-raohane.sh)"
require_lines = {'require("raohane")', "require('raohane')"}
lines = path.read_text(encoding="utf-8").splitlines()
lines = [line for line in lines if line.strip() != marker and line.strip() not in require_lines]
content = "\n".join(lines).rstrip() + "\n\n" + marker + "\n" + 'require("raohane")' + "\n"
tmp = path.with_suffix(path.suffix + ".tmp")
tmp.write_text(content, encoding="utf-8")
tmp.replace(path)
PY
  printf '[Raohane] Hyprland Lua config detected; installed 0.55+ keybind overrides.\n'
else
  # Keep the Raohane sources last so older inherited binds cannot override them.
  if [[ -f "$HYPR_LEGACY_MAIN" ]]; then
    python3 - "$HYPR_LEGACY_MAIN" "$SOURCE_LINE" "$AUTOSTART_SOURCE_LINE" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
managed = {sys.argv[2], sys.argv[3]}
lines = path.read_text(encoding="utf-8").splitlines()
lines = [line for line in lines if line.strip() not in managed]
content = "\n".join(lines).rstrip() + "\n\n# Raohane shell\n" + sys.argv[2] + "\n" + sys.argv[3] + "\n"
tmp = path.with_suffix(path.suffix + ".tmp")
tmp.write_text(content, encoding="utf-8")
tmp.replace(path)
PY
  else
    printf '%s\n%s\n' "$SOURCE_LINE" "$AUTOSTART_SOURCE_LINE" > "$HYPR_LEGACY_MAIN"
  fi
  printf '[Raohane] Legacy Hyprland config detected; installed hyprlang keybind overrides.\n'
fi

systemctl --user daemon-reload
systemctl --user enable raohane.service >/dev/null 2>&1 || true
systemctl --user reset-failed raohane.service >/dev/null 2>&1 || true

if ((START_AFTER_INSTALL)) && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
  printf '[Raohane] Starting shell for runtime validation...\n'
  if ! "$BIN_DIR/raohane" start; then
    START_FAILED=1
  fi
fi

printf '\n[Raohane] Installed.\n'
printf 'Runtime: %s\n' "$RUNTIME"
printf 'Settings: %s\n' "$RAOHANE_CONFIG_FILE"
printf 'Launcher: %s\n' "$BIN_DIR/raohane"
printf 'Hyprland integration: %s\n' "$HYPR_INTEGRATION"
printf 'Autostart snippet: %s\n\n' "$HYPR_AUTOSTART"
if ((START_AFTER_INSTALL == 0)); then
  printf 'Start manually with: raohane start\n'
elif ((START_FAILED)); then
  printf 'Runtime startup failed; the diagnostic log was printed above.\n'
  printf 'Foreground debug: raohane stop && raohane run\n'
else
  printf 'Start/restart with: raohane restart\n'
fi
printf 'Batch diagnostics: raohane doctor all\n'
printf 'Debug in terminal: raohane run\n'

if ((START_FAILED)); then
  exit 1
fi