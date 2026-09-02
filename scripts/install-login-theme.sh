#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
THEME_SOURCE="$ROOT/login/sddm/raohane"
THEME_TARGET="/usr/share/sddm/themes/raohane"
CONFIG_TARGET="/etc/sddm.conf.d/20-raohane-theme.conf"
SYNC_SCRIPT="$ROOT/scripts/sync-login-wallpaper.sh"
LOGIN_CACHE_DIR="/var/cache/raohane-login"

LOGIN_OWNER="${SUDO_USER:-${USER:-$(id -un)}}"
LOGIN_HOME="$(getent passwd "$LOGIN_OWNER" | cut -d: -f6)"
if [[ -n "${SUDO_USER:-}" ]]; then
  USER_CONFIG_HOME="$LOGIN_HOME/.config"
  USER_CACHE_HOME="$LOGIN_HOME/.cache"
else
  USER_CONFIG_HOME="${XDG_CONFIG_HOME:-$LOGIN_HOME/.config}"
  USER_CACHE_HOME="${XDG_CACHE_HOME:-$LOGIN_HOME/.cache}"
fi
NATIVE_CONFIG="$USER_CONFIG_HOME/raohane/native.json"
STAGE_DIR="$USER_CACHE_HOME/raohane/sddm-theme-stage"

PREVIEW=0
SYNC_ONLY=0

usage() {
  cat <<'EOF'
Raohane login theme installer

Usage:
  bash ./scripts/install-login-theme.sh
  bash ./scripts/install-login-theme.sh --preview
  bash ./scripts/install-login-theme.sh --sync-wallpaper

The installer themes SDDM and mirrors the currently selected Raohane desktop
wallpaper into a small world-readable cache that SDDM can access. It does not
enable, disable, or replace your current display-manager service.
EOF
}

while (($#)); do
  case "$1" in
    --preview) PREVIEW=1 ;;
    --sync-wallpaper) SYNC_ONLY=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

[[ -f "$THEME_SOURCE/Main.qml" && -f "$THEME_SOURCE/metadata.desktop" && -f "$SYNC_SCRIPT" ]] || {
  echo '[Raohane] SDDM theme payload is incomplete.' >&2
  exit 1
}

resolve_wallpaper() {
  command -v python3 >/dev/null 2>&1 || return 0
  [[ -r "$NATIVE_CONFIG" ]] || return 0

  python3 - "$NATIVE_CONFIG" <<'PY'
import json
import pathlib
import sys
import urllib.parse

path = pathlib.Path(sys.argv[1])
try:
    document = json.loads(path.read_text(encoding="utf-8"))
except Exception:
    raise SystemExit(0)

wallpaper = document.get("wallpaper") or {}
for value in (wallpaper.get("path"), wallpaper.get("lockPath")):
    if not value:
        continue
    raw = str(value).strip()
    if raw.startswith("file://"):
        raw = urllib.parse.unquote(urllib.parse.urlparse(raw).path)
    candidate = pathlib.Path(raw).expanduser()
    if candidate.is_file():
        print(candidate)
        break
PY
}

prepare_stage() {
  rm -rf -- "$STAGE_DIR"
  mkdir -p -- "$STAGE_DIR"
  cp -a "$THEME_SOURCE/." "$STAGE_DIR/"
}

set_stage_wallpaper() {
  local value="$1"
  if grep -q '^wallpaper=' "$STAGE_DIR/theme.conf"; then
    sed -i "s|^wallpaper=.*$|wallpaper=$value|" "$STAGE_DIR/theme.conf"
  else
    printf '\nwallpaper=%s\n' "$value" >> "$STAGE_DIR/theme.conf"
  fi
}

sync_to_cache() {
  local source="$1"
  [[ -n "$source" ]] || return 0
  RAOHANE_LOGIN_CACHE_DIR="$LOGIN_CACHE_DIR" bash "$SYNC_SCRIPT" "$source"
}

wallpaper="$(resolve_wallpaper || true)"

if ((SYNC_ONLY)); then
  if [[ ! -d "$LOGIN_CACHE_DIR" || ! -w "$LOGIN_CACHE_DIR" ]]; then
    echo '[Raohane] Login wallpaper cache is not writable yet.' >&2
    echo '[Raohane] Run the login theme installer once first.' >&2
    exit 1
  fi
  if [[ -z "$wallpaper" ]]; then
    echo '[Raohane] No desktop wallpaper is configured in native.json.' >&2
    exit 1
  fi
  sync_to_cache "$wallpaper"
  printf '[Raohane] Login wallpaper synced from %s\n' "$wallpaper"
  exit 0
fi

if ((PREVIEW)); then
  prepare_stage
  mkdir -p -- "$STAGE_DIR/assets"

  if [[ -n "$wallpaper" ]]; then
    RAOHANE_LOGIN_CACHE_DIR="$STAGE_DIR/assets" bash "$SYNC_SCRIPT" "$wallpaper"
  fi

  if [[ -f "$STAGE_DIR/assets/wallpaper" ]]; then
    set_stage_wallpaper 'assets/wallpaper'
    printf '[Raohane] Preview wallpaper: %s\n' "$wallpaper"
  else
    set_stage_wallpaper ''
    echo '[Raohane] Preview uses the fallback background; no readable image wallpaper was found.'
  fi

  for greeter in sddm-greeter-qt6 sddm-greeter; do
    if command -v "$greeter" >/dev/null 2>&1; then
      exec "$greeter" --test-mode --theme "$STAGE_DIR"
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

prepare_stage

login_uid="$(id -u "$LOGIN_OWNER")"
login_gid="$(id -g "$LOGIN_OWNER")"
sudo install -d -m 0755 -o "$login_uid" -g "$login_gid" "$LOGIN_CACHE_DIR"

if [[ -n "$wallpaper" ]]; then
  sync_to_cache "$wallpaper"
fi

if [[ -f "$LOGIN_CACHE_DIR/wallpaper" ]]; then
  set_stage_wallpaper 'file:///var/cache/raohane-login/wallpaper'
  printf '[Raohane] Login wallpaper: %s\n' "$wallpaper"
else
  set_stage_wallpaper ''
  echo '[Raohane] No readable desktop image was available; the fallback background will be used.'
fi

printf '[Raohane] Installing SDDM theme to %s\n' "$THEME_TARGET"
sudo rm -rf -- "$THEME_TARGET"
sudo install -d -m 0755 "$THEME_TARGET" /etc/sddm.conf.d
sudo cp -a "$STAGE_DIR/." "$THEME_TARGET/"
sudo chmod -R a+rX "$THEME_TARGET"

cat <<'EOF' | sudo tee "$CONFIG_TARGET" >/dev/null
[Theme]
Current=raohane
EOF

printf '[Raohane] Raohane SDDM theme selected.\n'
printf '[Raohane] Desktop wallpaper mirror lives at %s/wallpaper.\n' "$LOGIN_CACHE_DIR"
printf '[Raohane] Existing display-manager services were left untouched.\n'
printf '[Raohane] Preview without logging out: bash %s --preview\n' "$0"
