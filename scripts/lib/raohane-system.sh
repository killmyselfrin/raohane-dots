#!/usr/bin/env bash

RAOHANE_ROOT="${RAOHANE_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)}"
RAOHANE_MANIFEST="${RAOHANE_MANIFEST:-$RAOHANE_ROOT/manifests/raohane-dependencies.tsv}"

has() { command -v "$1" >/dev/null 2>&1; }
package_installed() { has pacman && pacman -Q "$1" >/dev/null 2>&1; }
user_unit_active() { systemctl --user is-active --quiet "$1" 2>/dev/null; }
system_unit_active() { systemctl is-active --quiet "$1" 2>/dev/null; }

manifest_rows() { tail -n +2 "$RAOHANE_MANIFEST"; }

profile_packages() {
  local profile="$1" include_aur="${2:-yes}"
  awk -F '\t' -v p="$profile" -v aur="$include_aur" '
    $5 ~ "(^|,)" p "(,|$)" && (aur == "yes" || $10 != "aur") { print $3 }
  ' "$RAOHANE_MANIFEST" | sort -u
}

missing_packages() {
  local package
  while IFS= read -r package; do
    package_installed "$package" || printf '%s\n' "$package"
  done
}

detect_distro() {
  if [[ -r /etc/os-release ]]; then . /etc/os-release; printf '%s\n' "${ID:-unknown}"; else printf 'unknown\n'; fi
}

detect_gpu() {
  if has lspci; then lspci -nnk 2>/dev/null | awk '/VGA compatible controller|3D controller|Display controller/{print; show=1; next} show && /Kernel driver in use/{print "  "$0; show=0}'; else printf 'lspci unavailable\n'; fi
}

service_state() {
  local unit="$1" scope="${2:-user}"
  if [[ "$scope" == system ]]; then systemctl is-active "$unit" 2>/dev/null || printf 'unavailable\n';
  else systemctl --user is-active "$unit" 2>/dev/null || printf 'unavailable\n'; fi
}

print_result() {
  local label="$1" state="$2" detail="$3" fix="${4:-}"
  printf '%-26s %s\n' "$label" "$state"
  if [[ "$state" != PASS ]]; then
    printf '  WHAT: %s\n  WHY: This capability is required for a complete Raohane session.\n' "$detail"
    printf '  DIAGNOSE: raohane doctor %s\n' "${label%% *}" | tr '[:upper:]' '[:lower:]'
    [[ -n "$fix" ]] && printf '  SAFE FIX: %s\n' "$fix"
  fi
}

doctor_deps() {
  local missing
  missing="$(profile_packages recommended | missing_packages || true)"
  if [[ -z "$missing" ]]; then print_result 'Dependencies' PASS 'recommended packages present'
  else print_result 'Dependencies' FAIL "Missing recommended packages: ${missing//$'\n'/, }" 'Review ./install-raohane.sh --recommended; confirm before installing.'; fi
}

doctor_graphics() {
  local renderer='unknown'
  has glxinfo && renderer="$(glxinfo -B 2>/dev/null | awk -F: '/OpenGL renderer string/{sub(/^ /,"",$2); print $2; exit}')"
  if [[ -d /sys/class/drm ]] && [[ "$renderer" != *llvmpipe* ]] && [[ "$renderer" != unknown ]]; then print_result Graphics PASS "$renderer"
  elif [[ -d /sys/class/drm ]]; then print_result Graphics WARN "DRM exists; hardware renderer could not be verified ($renderer)" 'Install mesa-utils and inspect `glxinfo -B`; do not change drivers blindly.'
  else print_result Graphics FAIL 'No DRM devices found' 'Inspect kernel logs and GPU driver binding before installing a driver.'; fi
}

doctor_display() {
  if ! has hyprctl; then print_result Display FAIL 'hyprctl is unavailable' 'Install Hyprland and run inside its session.'; return; fi
  if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then print_result Display WARN 'Not running inside a Hyprland session' 'Run this check from the target graphical session.'; return; fi
  local monitors; monitors="$(hyprctl -j monitors all 2>/dev/null || true)"
  [[ "$monitors" == \[* ]] && print_result Display PASS 'Hyprland monitor state available' || print_result Display FAIL 'Hyprland monitor query failed' 'Run `hyprctl monitors all`.'
}

doctor_audio() {
  if has wpctl && user_unit_active pipewire.socket && user_unit_active wireplumber.service; then print_result Audio PASS 'PipeWire and WirePlumber active'
  else print_result Audio FAIL 'PipeWire/WirePlumber command or user units unavailable' 'Install the audio group, then `systemctl --user restart pipewire wireplumber`.'; fi
}

doctor_network() {
  if has nmcli && system_unit_active NetworkManager.service; then print_result Network PASS 'NetworkManager active'
  else print_result Network FAIL 'NetworkManager CLI or service unavailable' 'Install networkmanager and enable NetworkManager.service.'; fi
}

doctor_bluetooth() {
  if [[ ! -d /sys/class/bluetooth ]] && ! compgen -G '/sys/class/rfkill/*' >/dev/null; then print_result Bluetooth WARN 'No Bluetooth adapter detected' 'No action is needed unless this machine should have Bluetooth.'
  elif has bluetoothctl && system_unit_active bluetooth.service; then print_result Bluetooth PASS 'BlueZ active'
  else print_result Bluetooth WARN 'Adapter found but BlueZ is not ready' 'Install bluez and bluez-utils, then enable bluetooth.service.'; fi
}

doctor_portals() {
  if user_unit_active xdg-desktop-portal.service && user_unit_active xdg-desktop-portal-hyprland.service; then print_result Portals PASS 'Portal broker and Hyprland backend active'
  else print_result Portals FAIL 'Portal user services are not both active' 'Install portal packages, relogin, and inspect `systemctl --user status xdg-desktop-portal*`.'; fi
}

doctor_ui() {
  if ! has qs; then print_result 'Raohane IPC' FAIL 'Quickshell is unavailable' 'Install quickshell-git and reinstall Raohane.'
  elif pgrep -af 'qs.*(-c|--config)[ =]raohane' >/dev/null 2>&1 || user_unit_active raohane.service; then print_result 'Raohane IPC' PASS 'Named configuration is running'
  else print_result 'Raohane IPC' WARN 'Named Raohane instance is not running' 'Start `systemctl --user start raohane.service` and inspect its journal.'; fi
}

doctor_core() {
  if has bash && [[ -r "$RAOHANE_MANIFEST" ]]; then print_result Core PASS 'runtime and manifest available'; else print_result Core FAIL 'runtime or manifest missing' 'Reinstall Raohane.'; fi
  if has qs && has qmake6; then print_result 'Quickshell / Qt' PASS 'runtime commands found'; else print_result 'Quickshell / Qt' FAIL 'qs or Qt 6 tools missing' 'Review the quickshell/Qt package group.'; fi
  if has hyprctl && has wayland-info; then print_result 'Hyprland / Wayland' PASS 'session tools found'; else print_result 'Hyprland / Wayland' FAIL 'Hyprland or Wayland diagnostics missing' 'Install the Hyprland/Wayland package group.'; fi
}

doctor_all() {
  doctor_core; doctor_portals; doctor_audio; doctor_network; doctor_bluetooth; doctor_graphics; doctor_display; doctor_ui
}
