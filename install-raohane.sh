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
HYPR_INTEGRATION="$HYPR_LEGACY_SNIPPET"
RAOHANE_CONFIG="$CONFIG_HOME/raohane"
RAOHANE_CONFIG_FILE="$RAOHANE_CONFIG/native.json"
RAOHANE_AUTOSTART_FILE="$RAOHANE_CONFIG/autostart.conf"
PREVIOUS_RAOHANE_CONFIG="$RAOHANE_CONFIG/config.json"
LEGACY_CONFIG_FILE="$CONFIG_HOME/illogical-impulse/config.json"
LEGACY_HYPR_AUTOSTART="$HYPR_DIR/raohane-autostart.conf"
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
  --migrate-legacy  Import the directly supported subset of an existing
                    illogical-impulse config into Raohane native schema v10.
  --no-start        Install files and systemd integration without starting Raohane.
  -h, --help        Show this help.

Examples:
  ./install-raohane.sh --deps
  ./install-raohane.sh --deps --no-start
  ./install-raohane.sh --migrate-legacy
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
  "shell.qml"
  "qmldir"
  "VERSION"
  "assets"
  "translations"
  "scripts/raohane"
  "scripts/raohane-audit.sh"
  "scripts/install-deps.sh"
  "scripts/migrate-legacy-config.py"
  "scripts/prune-runtime.sh"
  "scripts/validate-runtime-payload.sh"
  "defaults/native.json"
  "defaults/themes/serpantinum.json"
  "install/arch/required.txt"
  "install/arch/features.txt"
  "modules/raohane"
  "panelFamilies/RaohaneFamily.qml"
)
missing_runtime=()
for path in "${required_runtime[@]}"; do
  [[ -e "$ROOT/$path" ]] || missing_runtime+=("$path")
done

if ((${#missing_runtime[@]})); then
  echo '[Raohane] This checkout is missing required native runtime files.' >&2
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
  migration_source=""
  if ((MIGRATE_LEGACY)) && [[ -f "$LEGACY_CONFIG_FILE" ]]; then
    migration_source="$LEGACY_CONFIG_FILE"
  elif [[ -f "$PREVIOUS_RAOHANE_CONFIG" ]]; then
    # Previous Raohane installers wrote the inherited document to config.json.
    # Convert the safe subset automatically rather than discarding user choices.
    migration_source="$PREVIOUS_RAOHANE_CONFIG"
  fi

  if [[ -n "$migration_source" ]]; then
    python3 "$ROOT/scripts/migrate-legacy-config.py" \
      "$migration_source" "$ROOT/defaults/native.json" "$RAOHANE_CONFIG_FILE"
    printf '[Raohane] Migrated supported settings from %s\n' "$migration_source"
  else
    cp -a "$ROOT/defaults/native.json" "$RAOHANE_CONFIG_FILE"
    printf '[Raohane] Seeded native schema v10 settings.\n'
  fi
fi

# Native autostart is consumed by RaohaneAutostart and runs once per Hyprland
# session. Migrate the old generated Hyprland snippet if it exists, but never
# source it again after installation.
if [[ ! -f "$RAOHANE_AUTOSTART_FILE" ]]; then
  cat > "$RAOHANE_AUTOSTART_FILE" <<'AUTOSTART'
# Raohane autostart
# One shell command per line. Blank lines and # comments are ignored.
AUTOSTART

  if [[ -f "$LEGACY_HYPR_AUTOSTART" ]]; then
    python3 - "$LEGACY_HYPR_AUTOSTART" "$RAOHANE_AUTOSTART_FILE" <<'PY'
import pathlib
import re
import sys

source = pathlib.Path(sys.argv[1])
target = pathlib.Path(sys.argv[2])
commands = []
for raw in source.read_text(encoding="utf-8", errors="replace").splitlines():
    line = raw.strip()
    if not line or line.startswith("#"):
        continue
    match = re.match(r"^(?:exec|exec-once)\s*=\s*(.+)$", line)
    commands.append(match.group(1).strip() if match else line)
if commands:
    with target.open("a", encoding="utf-8") as handle:
        handle.write("\n# Migrated from ~/.config/hypr/raohane-autostart.conf\n")
        for command in commands:
            handle.write(command + "\n")
PY
    printf '[Raohane] Migrated legacy Hyprland autostart commands to %s\n' "$RAOHANE_AUTOSTART_FILE"
  fi
fi

# Stage only the standalone product payload. Development documents, patches,
# repository metadata and unrelated root files never enter the installed
# Quickshell configuration. scripts/ remains conservative so every native
# backend is preserved; prune-runtime removes source-only audits afterwards.
find "$RUNTIME" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +
mkdir -p "$RUNTIME/modules" "$RUNTIME/panelFamilies" "$RUNTIME/defaults" "$RUNTIME/install"
cp -a "$ROOT/shell.qml" "$ROOT/qmldir" "$ROOT/VERSION" "$RUNTIME/"
cp -a "$ROOT/modules/raohane" "$RUNTIME/modules/"
cp -a "$ROOT/panelFamilies/RaohaneFamily.qml" "$RUNTIME/panelFamilies/"
cp -a "$ROOT/defaults/native.json" "$RUNTIME/defaults/"
cp -a "$ROOT/defaults/themes" "$RUNTIME/defaults/"
cp -a "$ROOT/install/arch" "$RUNTIME/install/"
cp -a "$ROOT/assets" "$RUNTIME/"
cp -a "$ROOT/translations" "$RUNTIME/"
cp -a "$ROOT/scripts" "$RUNTIME/"

# Keep the pruner as an upgrade/self-heal boundary for users coming from older
# installations. On a fresh staged runtime it mainly removes source-only audits.
bash "$ROOT/scripts/prune-runtime.sh" "$RUNTIME"
bash "$ROOT/scripts/validate-runtime-payload.sh" "$RUNTIME"

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

# Hyprland <=0.54 integration.
cat > "$HYPR_LEGACY_SNIPPET" <<'HYPR'
# Raohane shell integration
# Managed by install-raohane.sh
exec-once = systemctl --user start raohane.service

# Native XKB layout switching. US stays first so Raohane's symbol-based binds
# retain stable physical-key behavior while typing can switch between EN/RU.
input {
    kb_layout = us,ru
    kb_options = grp:alt_shift_toggle
}

unbind = SUPER, Super_L
unbind = SUPER, Super_R
unbind = SUPER, R
unbind = SUPER, escape
unbind = SUPER, C
unbind = SUPER SHIFT, M

bind = SUPER, R, exec, raohane launcher
bind = SUPER, escape, exec, raohane settings
bind = SUPER, C, exec, raohane control
bind = SUPER SHIFT, M, exec, raohane media

unbind = SUPER, 1
unbind = SUPER, 2
unbind = SUPER, 3
unbind = SUPER, 4
unbind = SUPER, 5
unbind = SUPER, 6
unbind = SUPER, 7
unbind = SUPER, 8
unbind = SUPER, 9
unbind = SUPER, 0
unbind = SUPER SHIFT, 1
unbind = SUPER SHIFT, 2
unbind = SUPER SHIFT, 3
unbind = SUPER SHIFT, 4
unbind = SUPER SHIFT, 5
unbind = SUPER SHIFT, 6
unbind = SUPER SHIFT, 7
unbind = SUPER SHIFT, 8
unbind = SUPER SHIFT, 9
unbind = SUPER SHIFT, 0

bind = SUPER, 1, workspace, 1
bind = SUPER, 2, workspace, 2
bind = SUPER, 3, workspace, 3
bind = SUPER, 4, workspace, 4
bind = SUPER, 5, workspace, 5
bind = SUPER, 6, workspace, 6
bind = SUPER, 7, workspace, 7
bind = SUPER, 8, workspace, 8
bind = SUPER, 9, workspace, 9
bind = SUPER, 0, workspace, 10
bind = SUPER SHIFT, 1, movetoworkspace, 1
bind = SUPER SHIFT, 2, movetoworkspace, 2
bind = SUPER SHIFT, 3, movetoworkspace, 3
bind = SUPER SHIFT, 4, movetoworkspace, 4
bind = SUPER SHIFT, 5, movetoworkspace, 5
bind = SUPER SHIFT, 6, movetoworkspace, 6
bind = SUPER SHIFT, 7, movetoworkspace, 7
bind = SUPER SHIFT, 8, movetoworkspace, 8
bind = SUPER SHIFT, 9, movetoworkspace, 9
bind = SUPER SHIFT, 0, movetoworkspace, 10
HYPR

# Hyprland 0.55+ integration.
cat > "$HYPR_LUA_SNIPPET" <<'LUA'
-- Raohane shell integration for Hyprland 0.55+
-- Managed by install-raohane.sh

-- Native XKB layout switching. This is the Hyprland 0.55+ equivalent of the
-- managed input block in raohane.conf and avoids modifier-only bind hacks.
hl.config({
    input = {
        kb_layout = "us,ru",
        kb_options = "grp:alt_shift_toggle",
    },
})

hl.unbind("SUPER + SUPER_L")
hl.unbind("SUPER + SUPER_R")
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

for workspace = 1, 10 do
    local key = workspace % 10
    hl.unbind("SUPER + " .. key)
    hl.unbind("SUPER + SHIFT + " .. key)
    hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = workspace }),
        { description = "Raohane: Workspace " .. workspace })
    hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = workspace }),
        { description = "Raohane: Move window to workspace " .. workspace })
end
LUA

HYPR_LUA_MAIN="$HYPR_DIR/hyprland.lua"
HYPR_LEGACY_MAIN="$HYPR_DIR/hyprland.conf"
SOURCE_LINE='source = ~/.config/hypr/raohane.conf'
OLD_AUTOSTART_SOURCE='source = ~/.config/hypr/raohane-autostart.conf'

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
  printf '[Raohane] Hyprland Lua config detected; installed 0.55+ integration.\n'
else
  if [[ -f "$HYPR_LEGACY_MAIN" ]]; then
    python3 - "$HYPR_LEGACY_MAIN" "$SOURCE_LINE" "$OLD_AUTOSTART_SOURCE" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
source_line = sys.argv[2]
old_autostart = sys.argv[3]
lines = path.read_text(encoding="utf-8").splitlines()
lines = [line for line in lines if line.strip() not in {source_line, old_autostart}]
content = "\n".join(lines).rstrip() + "\n\n# Raohane shell\n" + source_line + "\n"
tmp = path.with_suffix(path.suffix + ".tmp")
tmp.write_text(content, encoding="utf-8")
tmp.replace(path)
PY
  else
    printf '%s\n' "$SOURCE_LINE" > "$HYPR_LEGACY_MAIN"
  fi
  printf '[Raohane] Legacy Hyprland config detected; installed hyprlang integration.\n'
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
printf 'Autostart: %s\n' "$RAOHANE_AUTOSTART_FILE"
printf 'Launcher: %s\n' "$BIN_DIR/raohane"
printf 'Hyprland integration: %s\n\n' "$HYPR_INTEGRATION"
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
