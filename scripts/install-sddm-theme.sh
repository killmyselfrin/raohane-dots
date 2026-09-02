#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
THEME_SOURCE="$ROOT/display-manager/sddm/raohane"
THEME_TARGET="/usr/share/sddm/themes/raohane"
CONFIG_TARGET="/etc/sddm.conf.d/raohane-theme.conf"
ENABLE_SDDM=0
PREVIEW_ONLY=0

usage() {
  cat <<'EOF'
Raohane SDDM greeter installer

Usage:
  scripts/install-sddm-theme.sh [--enable|--preview]

Options:
  --enable   Install the theme and explicitly enable SDDM as display manager.
             This can replace another display-manager.service symlink.
  --preview  Launch the source theme in SDDM test mode; make no system changes.
  -h, --help Show this help.

Without --enable the theme is installed and selected in SDDM configuration,
but the script does not switch your active display manager.
EOF
}

while (($#)); do
  case "$1" in
    --enable) ENABLE_SDDM=1 ;;
    --preview) PREVIEW_ONLY=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "[Raohane] Unknown SDDM option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

[[ -f "$THEME_SOURCE/Main.qml" ]] || {
  echo "[Raohane] Missing SDDM theme source: $THEME_SOURCE/Main.qml" >&2
  exit 1
}
[[ -f "$THEME_SOURCE/metadata.desktop" ]] || {
  echo "[Raohane] Missing SDDM theme metadata." >&2
  exit 1
}
[[ -f "$THEME_SOURCE/background.png" ]] || {
  echo "[Raohane] Missing SDDM background asset." >&2
  exit 1
}

if ((PREVIEW_ONLY)); then
  greeter=""
  for candidate in sddm-greeter-qt6 sddm-greeter; do
    if command -v "$candidate" >/dev/null 2>&1; then
      greeter="$candidate"
      break
    fi
  done
  [[ -n "$greeter" ]] || {
    echo '[Raohane] SDDM greeter is not installed. On Arch: sudo pacman -S sddm' >&2
    exit 1
  }
  exec "$greeter" --test-mode --theme "$THEME_SOURCE"
fi

if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
  echo '[Raohane] Run this script as your normal user; it requests sudo only for system files.' >&2
  exit 1
fi
command -v sudo >/dev/null 2>&1 || {
  echo '[Raohane] sudo is required to install a system SDDM theme.' >&2
  exit 1
}
command -v sddm >/dev/null 2>&1 || {
  echo '[Raohane] SDDM is not installed.' >&2
  echo 'Install the full Raohane dependency set or run: sudo pacman -S sddm' >&2
  exit 1
}
command -v rsync >/dev/null 2>&1 || {
  echo '[Raohane] rsync is required. Install Raohane dependencies first.' >&2
  exit 1
}

printf '[Raohane] Installing SDDM theme...\n'
sudo install -d -m 0755 "$THEME_TARGET" /etc/sddm.conf.d
sudo rsync -a --delete --chown=root:root "$THEME_SOURCE/" "$THEME_TARGET/"

config_tmp="$(mktemp)"
cleanup() { rm -f -- "$config_tmp"; }
trap cleanup EXIT
cat > "$config_tmp" <<'EOF'
# Raohane SDDM greeter
# Managed by scripts/install-sddm-theme.sh
[Theme]
Current=raohane
EOF
sudo install -m 0644 "$config_tmp" "$CONFIG_TARGET"

if ((ENABLE_SDDM)); then
  printf '[Raohane] Enabling SDDM as the system display manager...\n'
  sudo systemctl enable sddm.service --force
fi

printf '\n[Raohane] Raohane SDDM greeter installed.\n'
printf 'Theme:  %s\n' "$THEME_TARGET"
printf 'Config: %s\n' "$CONFIG_TARGET"

if ((ENABLE_SDDM)); then
  printf 'SDDM is enabled. The greeter will be used on the next graphical login/boot.\n'
elif systemctl is-enabled sddm.service >/dev/null 2>&1; then
  printf 'SDDM is already enabled. The greeter will be used on the next graphical login/boot.\n'
else
  printf 'SDDM was not enabled automatically. To switch explicitly, run:\n'
  printf '  scripts/install-sddm-theme.sh --enable\n'
fi
printf 'Preview at any time with:\n'
printf '  scripts/install-sddm-theme.sh --preview\n'
