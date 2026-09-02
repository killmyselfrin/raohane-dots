#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
THEME_SOURCE="$ROOT/login/sddm/raohane"
THEME_TARGET="/usr/share/sddm/themes/raohane"
CONFIG_TARGET="/etc/sddm.conf.d/20-raohane-theme.conf"
PREVIEW=0

usage() {
  cat <<'EOF'
Raohane login theme installer

Usage:
  bash ./scripts/install-login-theme.sh
  bash ./scripts/install-login-theme.sh --preview

The installer only themes SDDM. It does not enable, disable, or replace your
current display-manager service.
EOF
}

while (($#)); do
  case "$1" in
    --preview) PREVIEW=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

[[ -f "$THEME_SOURCE/Main.qml" && -f "$THEME_SOURCE/metadata.desktop" ]] || {
  echo '[Raohane] SDDM theme payload is incomplete.' >&2
  exit 1
}

if ((PREVIEW)); then
  for greeter in sddm-greeter-qt6 sddm-greeter; do
    if command -v "$greeter" >/dev/null 2>&1; then
      exec "$greeter" --test-mode --theme "$THEME_SOURCE"
    fi
  done
  echo '[Raohane] SDDM greeter executable was not found.' >&2
  echo '[Raohane] On Arch Linux install SDDM first: sudo pacman -S sddm' >&2
  exit 1
fi

if ! command -v sddm >/dev/null 2>&1; then
  echo '[Raohane] SDDM is not installed.' >&2
  echo 'On Arch Linux: sudo pacman -S sddm' >&2
  exit 1
fi

printf '[Raohane] Installing SDDM theme to %s\n' "$THEME_TARGET"
sudo install -d -m 0755 "$THEME_TARGET" /etc/sddm.conf.d
sudo cp -a "$THEME_SOURCE/." "$THEME_TARGET/"
sudo chmod -R a+rX "$THEME_TARGET"

cat <<'EOF' | sudo tee "$CONFIG_TARGET" >/dev/null
[Theme]
Current=raohane
EOF

printf '[Raohane] Raohane SDDM theme selected.\n'
printf '[Raohane] Existing display-manager services were left untouched.\n'
printf '[Raohane] Preview without logging out: bash %s --preview\n' "$0"
