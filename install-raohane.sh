#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
RUNTIME="$CONFIG_HOME/quickshell/raohane"
BIN_DIR="${HOME}/.local/bin"
SYSTEMD_DIR="$CONFIG_HOME/systemd/user"
HYPR_DIR="$CONFIG_HOME/hypr"
HYPR_SNIPPET="$HYPR_DIR/raohane.conf"
HYPR_AUTOSTART="$HYPR_DIR/raohane-autostart.conf"
RAOHANE_CONFIG="$CONFIG_HOME/raohane"
RAOHANE_CONFIG_FILE="$RAOHANE_CONFIG/config.json"
LEGACY_CONFIG_FILE="$CONFIG_HOME/illogical-impulse/config.json"
INSTALL_DEPS=0
START_AFTER_INSTALL=1
MIGRATE_LEGACY=0

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

mkdir -p "$RUNTIME" "$BIN_DIR" "$SYSTEMD_DIR" "$HYPR_DIR" "$RAOHANE_CONFIG"

# New installs start from Raohane defaults. Importing a legacy shell config is
# opt-in so ordinary installs have no dependency on another shell namespace.
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

[Service]
Type=simple
ExecStart=${BIN_DIR}/raohane run
Restart=on-failure
RestartSec=1
Environment=QT_QPA_PLATFORM=wayland

[Install]
WantedBy=default.target
SERVICE

cat > "$HYPR_SNIPPET" <<'HYPR'
# Raohane shell integration
# Managed by install-raohane.sh
exec-once = systemctl --user start raohane.service

# Raohane shell controls
bind = SUPER, R, exec, raohane launcher
bind = SUPER, escape, exec, raohane settings
bind = SUPER, C, exec, raohane control
bind = SUPER SHIFT, M, exec, raohane media
HYPR

if [[ ! -f "$HYPR_AUTOSTART" ]]; then
  cat > "$HYPR_AUTOSTART" <<'HYPR_AUTOSTART'
# Raohane autostart
# Generated by Raohane Settings.
HYPR_AUTOSTART
fi

HYPR_MAIN="$HYPR_DIR/hyprland.conf"
SOURCE_LINE='source = ~/.config/hypr/raohane.conf'
AUTOSTART_SOURCE_LINE='source = ~/.config/hypr/raohane-autostart.conf'
if [[ -f "$HYPR_MAIN" ]]; then
  if ! grep -Fqx "$SOURCE_LINE" "$HYPR_MAIN"; then
    printf '\n# Raohane shell\n%s\n' "$SOURCE_LINE" >> "$HYPR_MAIN"
  fi
  if ! grep -Fqx "$AUTOSTART_SOURCE_LINE" "$HYPR_MAIN"; then
    printf '%s\n' "$AUTOSTART_SOURCE_LINE" >> "$HYPR_MAIN"
  fi
else
  printf '%s\n%s\n' "$SOURCE_LINE" "$AUTOSTART_SOURCE_LINE" > "$HYPR_MAIN"
fi

systemctl --user daemon-reload
systemctl --user enable raohane.service >/dev/null 2>&1 || true

if ((START_AFTER_INSTALL)) && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
  systemctl --user start raohane.service >/dev/null 2>&1 || true
fi

printf '\n[Raohane] Installed.\n'
printf 'Runtime: %s\n' "$RUNTIME"
printf 'Settings: %s\n' "$RAOHANE_CONFIG_FILE"
printf 'Launcher: %s\n' "$BIN_DIR/raohane"
printf 'Hyprland snippet: %s\n' "$HYPR_SNIPPET"
printf 'Autostart snippet: %s\n\n' "$HYPR_AUTOSTART"
if ((START_AFTER_INSTALL == 0)); then
  printf 'Start manually with: raohane start\n'
else
  printf 'Start/restart with: raohane restart\n'
fi
printf 'Batch diagnostics: raohane doctor all\n'
printf 'Debug in terminal: raohane run\n'
