#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BACKEND="$ROOT/install-raohane.sh"
DEPS="$ROOT/scripts/install-deps.sh"
ASSUME_YES=0
INSTALL_LOGIN_THEME=1
START_AFTER_INSTALL=1
MIGRATE_LEGACY=0

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  RESET=$'\033[0m'
  BOLD=$'\033[1m'
  DIM=$'\033[2m'
  VIOLET=$'\033[38;5;141m'
  PINK=$'\033[38;5;218m'
  CYAN=$'\033[38;5;117m'
  GREEN=$'\033[38;5;114m'
  YELLOW=$'\033[38;5;221m'
  RED=$'\033[38;5;203m'
  WHITE=$'\033[38;5;255m'
else
  RESET="" BOLD="" DIM="" VIOLET="" PINK="" CYAN="" GREEN="" YELLOW="" RED="" WHITE=""
fi

usage() {
  cat <<'EOF'
Raohane guided installer

Usage:
  bash install.sh [OPTIONS]

Options:
  --yes             Accept recommended choices without interactive questions.
  --no-login-theme  Do not install/select the Raohane SDDM theme.
  --no-start        Install and enable autostart without starting Raohane now.
  --migrate-legacy  Import the supported subset of an older compatible config.
  -h, --help        Show this help.
EOF
}

while (($#)); do
  case "$1" in
    --yes|-y) ASSUME_YES=1 ;;
    --no-login-theme) INSTALL_LOGIN_THEME=0 ;;
    --no-start) START_AFTER_INSTALL=0 ;;
    --migrate-legacy) MIGRATE_LEGACY=1 ;;
    -h|--help) usage; exit 0 ;;
    *) printf '%sUnknown option: %s%s\n' "$RED" "$1" "$RESET" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

line() {
  printf '%s%s%s\n' "$DIM" '────────────────────────────────────────────────────────────' "$RESET"
}

header() {
  clear 2>/dev/null || true
  printf '\n%s%s  ラオハネ%s  %sRAOHANE%s\n' "$BOLD" "$VIOLET" "$RESET" "$BOLD$WHITE" "$RESET"
  printf '%s  Hyprland desktop shell · guided installation%s\n\n' "$DIM" "$RESET"
  line
}

section() {
  printf '\n%s◆%s %s%s%s\n' "$VIOLET" "$RESET" "$BOLD" "$1" "$RESET"
}

ok() { printf '  %s✓%s %s\n' "$GREEN" "$RESET" "$1"; }
info() { printf '  %s•%s %s\n' "$CYAN" "$RESET" "$1"; }
warn() { printf '  %s!%s %s\n' "$YELLOW" "$RESET" "$1"; }
fail() { printf '  %s×%s %s\n' "$RED" "$RESET" "$1" >&2; }

confirm() {
  local prompt="$1"
  local default="${2:-yes}"
  local reply=""

  if ((ASSUME_YES)); then
    return 0
  fi

  if [[ ! -t 0 ]]; then
    fail "Interactive confirmation is unavailable. Re-run with --yes."
    return 1
  fi

  if [[ "$default" == "yes" ]]; then
    printf '\n%s?%s %s %s[Y/n]%s ' "$PINK" "$RESET" "$prompt" "$DIM" "$RESET"
  else
    printf '\n%s?%s %s %s[y/N]%s ' "$PINK" "$RESET" "$prompt" "$DIM" "$RESET"
  fi
  IFS= read -r reply
  reply="${reply,,}"

  if [[ "$default" == "yes" ]]; then
    [[ -z "$reply" || "$reply" == "y" || "$reply" == "yes" || "$reply" == "д" || "$reply" == "да" ]]
  else
    [[ "$reply" == "y" || "$reply" == "yes" || "$reply" == "д" || "$reply" == "да" ]]
  fi
}

header

if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
  fail 'Run the installer as your normal user. It asks for sudo only when required.'
  exit 1
fi

[[ -x "$BACKEND" || -f "$BACKEND" ]] || { fail 'install-raohane.sh is missing.'; exit 1; }
[[ -f "$DEPS" ]] || { fail 'scripts/install-deps.sh is missing.'; exit 1; }

section 'System preflight'

if [[ ! -f /etc/os-release ]]; then
  fail '/etc/os-release was not found.'
  exit 1
fi
# shellcheck disable=SC1091
source /etc/os-release
case " ${ID:-} ${ID_LIKE:-} " in
  *' arch '*|*' cachyos '*|*' endeavouros '*)
    ok "Supported Arch-family system: ${PRETTY_NAME:-${ID:-unknown}}"
    ;;
  *)
    fail "The guided installer currently supports Arch-based systems only (${PRETTY_NAME:-unknown})."
    exit 1
    ;;
esac

if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
  ok 'Hyprland session detected'
else
  warn 'Hyprland session not detected; Raohane will be installed and enabled, but cannot be live-tested now.'
fi

command -v pacman >/dev/null 2>&1 || { fail 'pacman is required.'; exit 1; }
ok 'Package manager ready'

section 'Dependencies'
mapfile -t missing_packages < <(bash "$DEPS" --full --missing)

if ((${#missing_packages[@]} == 0)); then
  ok 'All Raohane runtime and desktop-feature dependencies are already installed.'
else
  info "${#missing_packages[@]} package(s) are missing and required for the complete Raohane experience:"
  printf '\n'
  columns=3
  index=0
  for package in "${missing_packages[@]}"; do
    printf '  %-27s' "$package"
    ((index += 1))
    if ((index % columns == 0)); then printf '\n'; fi
  done
  if ((index % columns != 0)); then printf '\n'; fi

  printf '\n%sRaohane never changes GPU drivers automatically.%s\n' "$DIM" "$RESET"
  if ! confirm 'Install these dependencies with pacman?' yes; then
    fail 'Installation cancelled before making system changes.'
    exit 1
  fi

  section 'Installing dependencies'
  bash "$DEPS" --full --yes
  ok 'Dependency set verified'
fi

if ((INSTALL_LOGIN_THEME)) && ((ASSUME_YES == 0)); then
  if ! confirm 'Install and select the Raohane SDDM login theme?' yes; then
    INSTALL_LOGIN_THEME=0
  fi
fi

if ((START_AFTER_INSTALL)) && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && ((ASSUME_YES == 0)); then
  if ! confirm 'Start Raohane automatically after installation?' yes; then
    START_AFTER_INSTALL=0
  fi
fi

section 'Installing Raohane'
backend_args=(--no-deps)
((INSTALL_LOGIN_THEME)) || backend_args+=(--no-login-theme)
((START_AFTER_INSTALL)) || backend_args+=(--no-start)
((MIGRATE_LEGACY)) && backend_args+=(--migrate-legacy)

bash "$BACKEND" "${backend_args[@]}"

section 'Autostart'
systemctl --user daemon-reload
if ! systemctl --user --quiet is-enabled raohane.service; then
  systemctl --user enable raohane.service >/dev/null
fi

if systemctl --user --quiet is-enabled raohane.service; then
  ok 'raohane.service enabled for future sessions'
else
  fail 'Could not enable raohane.service'
  exit 1
fi

if [[ -f "$HOME/.config/hypr/hyprland.lua" ]]; then
  if grep -Fq 'require("raohane")' "$HOME/.config/hypr/hyprland.lua" 2>/dev/null; then
    ok 'Hyprland 0.55+ integration installed'
  else
    warn 'Hyprland Lua integration could not be verified.'
  fi
elif grep -Fq 'source = ~/.config/hypr/raohane.conf' "$HOME/.config/hypr/hyprland.conf" 2>/dev/null; then
  ok 'Hyprland integration installed'
else
  warn 'Hyprland integration could not be verified.'
fi

section 'Installation complete'
line
printf '\n  %s%sRaohane is ready.%s\n' "$BOLD" "$WHITE" "$RESET"
printf '  %sRuntime%s     %s\n' "$DIM" "$RESET" "$HOME/.config/quickshell/raohane"
printf '  %sSettings%s    %s\n' "$DIM" "$RESET" "$HOME/.config/raohane/native.json"
printf '  %sAutostart%s   %s\n' "$DIM" "$RESET" 'raohane.service · enabled'
printf '  %sLogin theme%s %s\n' "$DIM" "$RESET" "$([[ $INSTALL_LOGIN_THEME -eq 1 ]] && printf 'Raohane SDDM' || printf 'unchanged')"

if ((START_AFTER_INSTALL)) && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
  printf '\n  %sThe visual Raohane welcome/onboarding should open on first launch.%s\n' "$VIOLET" "$RESET"
else
  printf '\n  Start later with: %sraohane start%s\n' "$BOLD" "$RESET"
fi

printf '  Diagnostics:     %sraohane doctor all%s\n\n' "$BOLD" "$RESET"
line
printf '\n'
