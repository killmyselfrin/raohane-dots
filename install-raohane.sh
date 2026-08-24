#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export RAOHANE_ROOT="$ROOT"
# shellcheck source=scripts/lib/raohane-system.sh
source "$ROOT/scripts/lib/raohane-system.sh"
RUNTIME="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/raohane"
BIN_DIR="$HOME/.local/bin"
SYSTEMD_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
HYPR_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
MODE=recommended
CHECK_ONLY=no

usage() { cat <<'EOF'
Usage: ./install-raohane.sh [--check|--minimal|--recommended|--full|--install-deps]
  --check          inspect this system and print the recommended package plan
  --minimal        install the minimum shell runtime, then Raohane
  --recommended    install the supported desktop foundation, then Raohane (default)
  --full           add optional integrations and tools
  --install-deps   compatibility alias for --recommended

Package installation is supported on Arch-family systems. The plan is always
shown and confirmation is required. GPU driver packages are plan-only and are
never installed by this bootstrapper.
EOF
}

[[ $# -le 1 ]] || { usage >&2; exit 2; }
case "${1:---recommended}" in
  --check) CHECK_ONLY=yes; MODE=recommended ;;
  --minimal) MODE=minimal ;;
  --recommended|--install-deps) MODE=recommended ;;
  --full) MODE=full ;;
  -h|--help) usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
esac

printf 'Raohane bootstrap — system inspection\n'
printf 'Distro: %s\nKernel: %s\n' "$(detect_distro)" "$(uname -r)"
printf 'GPU and active kernel driver:\n'; detect_gpu | sed 's/^/  /'
printf 'DRM cards: '; compgen -G '/sys/class/drm/card*' 2>/dev/null | tr '\n' ' ' || true; printf '\n'
printf 'OpenGL: '; if command -v glxinfo >/dev/null; then glxinfo -B 2>/dev/null | awk -F: '/OpenGL renderer/{print $2; found=1} END{if(!found)print "unavailable"}'; else printf 'not checked (mesa-utils missing)\n'; fi
printf 'Vulkan: '; command -v vulkaninfo >/dev/null && vulkaninfo --summary >/dev/null 2>&1 && printf 'available\n' || printf 'not verified\n'
printf 'Hyprland: %s | Quickshell: %s\n' "$(command -v hyprctl || printf missing)" "$(command -v qs || printf missing)"

mapfile -t wanted < <(profile_packages "$MODE" no)
mapfile -t missing < <(printf '%s\n' "${wanted[@]}" | missing_packages || true)
mapfile -t aur < <(awk -F '\t' -v p="$MODE" '$5 ~ "(^|,)" p "(,|$)" && $10=="aur" {print $3}' "$RAOHANE_MANIFEST" | sort -u)
printf '\nPackage plan (%s):\n' "$MODE"
if ((${#missing[@]})); then printf '  Official repository, missing (%d):\n' "${#missing[@]}"; printf '    %s\n' "${missing[@]}"; else printf '  Official repository dependencies are present.\n'; fi
if ((${#aur[@]})); then printf '  AUR/manual review (not automatically installed):\n'; printf '    %s\n' "${aur[@]}"; fi
printf '  GPU groups: excluded from automatic installation; use a graphics plan in Phase B.\n'

if [[ "$CHECK_ONLY" == yes ]]; then
  printf '\nDoctor results:\n'; doctor_all
  exit 0
fi
[[ "$(detect_distro)" == arch || "$(detect_distro)" == cachyos || "$(detect_distro)" == endeavouros || "$(detect_distro)" == manjaro ]] || { printf 'Automatic dependency installation only supports Arch-family distributions.\n' >&2; exit 1; }
if ((${#missing[@]})); then
  [[ -t 0 ]] || { printf 'Confirmation requires an interactive terminal. Re-run from a terminal.\n' >&2; exit 1; }
  read -r -p 'Install the listed official packages with pacman? [y/N] ' answer
  [[ "$answer" =~ ^[Yy]$ ]] || { printf 'Cancelled without changes.\n'; exit 0; }
  sudo pacman -S --needed -- "${missing[@]}"
fi
command -v hyprctl >/dev/null || { printf 'Hyprland verification failed after dependency step.\n' >&2; exit 1; }
command -v qs >/dev/null || { printf 'Quickshell is an AUR/manual dependency. Install it, then rerun.\n' >&2; exit 1; }

printf '\nInstalling Raohane named configuration...\n'
systemctl --user stop raohane.service >/dev/null 2>&1 || true
mkdir -p "$RUNTIME" "$BIN_DIR" "$SYSTEMD_DIR" "$HYPR_DIR" "${XDG_CONFIG_HOME:-$HOME/.config}/raohane"
find "$RUNTIME" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +
tar -C "$ROOT" --exclude=.git --exclude=install-raohane.sh -cf - . | tar -C "$RUNTIME" -xf -
install -m 0755 "$ROOT/scripts/raohane" "$BIN_DIR/raohane"
cat > "$SYSTEMD_DIR/raohane.service" <<SERVICE
[Unit]
Description=Raohane shell for Hyprland
PartOf=graphical-session.target
After=graphical-session.target pipewire.service wireplumber.service

[Service]
Type=simple
ExecStart=${BIN_DIR}/raohane run
Restart=on-failure
RestartSec=1
Environment=QT_QPA_PLATFORM=wayland

[Install]
WantedBy=default.target
SERVICE
cat > "$HYPR_DIR/raohane.conf" <<'HYPR'
# Managed Raohane integration; user monitor configuration is never written here.
exec-once = systemctl --user start raohane.service
bind = SUPER, R, exec, raohane launcher
bind = SUPER, escape, exec, raohane settings
bind = SUPER, C, exec, raohane control
bind = SUPER SHIFT, M, exec, raohane media-overlay
HYPR
touch "$HYPR_DIR/raohane-autostart.conf"
main="$HYPR_DIR/hyprland.conf"
touch "$main"
for line in 'source = ~/.config/hypr/raohane.conf' 'source = ~/.config/hypr/raohane-autostart.conf'; do grep -Fqx "$line" "$main" || printf '\n%s\n' "$line" >> "$main"; done
systemctl --user daemon-reload
systemctl --user enable raohane.service >/dev/null
systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service >/dev/null 2>&1 || true
sudo systemctl enable --now NetworkManager.service >/dev/null 2>&1 || true
[[ -d /sys/class/bluetooth ]] && sudo systemctl enable --now bluetooth.service >/dev/null 2>&1 || true
[[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && systemctl --user restart raohane.service || true
printf '\nRuntime verification:\n'; doctor_all
printf '\nInstalled at %s. Relogin may be required for portals, keyring, and Wayland environment changes.\n' "$RUNTIME"
