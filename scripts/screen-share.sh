#!/usr/bin/env bash
set -euo pipefail

mode="${1:-status}"

ok() { printf '  [ok] %s\n' "$*"; }
warn() { printf '  [--] %s\n' "$*"; }
fail() { printf '  [!!] %s\n' "$*"; }

package_installed() {
  command -v pacman >/dev/null 2>&1 && pacman -Q "$1" >/dev/null 2>&1
}

unit_state() {
  local unit="$1"
  if systemctl --user --quiet is-active "$unit" 2>/dev/null; then
    ok "$unit active"
    return 0
  fi
  fail "$unit inactive/not found"
  return 1
}

portal_bus_ready() {
  if command -v busctl >/dev/null 2>&1 \
      && busctl --user --list 2>/dev/null | grep -q 'org.freedesktop.portal.Desktop'; then
    ok 'org.freedesktop.portal.Desktop available on the user bus'
    return 0
  fi
  fail 'org.freedesktop.portal.Desktop is not available on the user bus'
  return 1
}

print_discord_mode() {
  command -v hyprctl >/dev/null 2>&1 || return 0
  command -v jq >/dev/null 2>&1 || return 0

  local rows=""
  rows="$(hyprctl clients -j 2>/dev/null | jq -r '
    .[]
    | select(((.class // "") + " " + (.initialClass // "") + " " + (.title // ""))
      | test("discord|vesktop|webcord"; "i"))
    | [(.class // .initialClass // "Discord"), ((.xwayland // false) | tostring)]
    | @tsv
  ' 2>/dev/null || true)"

  if [[ -z "$rows" ]]; then
    warn 'Discord/Vesktop/WebCord window not detected; client mode cannot be checked'
    return 0
  fi

  while IFS=$'\t' read -r class xwayland; do
    if [[ "$xwayland" == "true" ]]; then
      fail "$class is running through XWayland; full Wayland screen capture may be black/unavailable"
      warn 'Launch a native-Wayland Discord client/session before testing the portal again'
    else
      ok "$class is running as a native Wayland client"
    fi
  done <<< "$rows"
}

print_status() {
  local failures=0

  echo 'Raohane screen-share health'
  echo
  echo 'Packages'
  for package in pipewire wireplumber xdg-desktop-portal xdg-desktop-portal-hyprland qt6-wayland; do
    if package_installed "$package"; then
      ok "$package installed"
    else
      fail "$package missing"
      failures=$((failures + 1))
    fi
  done
  if package_installed xdg-desktop-portal-gtk; then
    ok 'xdg-desktop-portal-gtk installed (fallback/file chooser)'
  else
    warn 'xdg-desktop-portal-gtk missing (recommended fallback backend)'
  fi

  echo
  echo 'Session environment'
  printf '  WAYLAND_DISPLAY=%s\n' "${WAYLAND_DISPLAY:-<unset>}"
  printf '  XDG_CURRENT_DESKTOP=%s\n' "${XDG_CURRENT_DESKTOP:-<unset>}"
  printf '  XDG_SESSION_DESKTOP=%s\n' "${XDG_SESSION_DESKTOP:-<unset>}"
  printf '  XDG_SESSION_TYPE=%s\n' "${XDG_SESSION_TYPE:-<unset>}"
  printf '  HYPRLAND_INSTANCE_SIGNATURE=%s\n' "${HYPRLAND_INSTANCE_SIGNATURE:-<unset>}"

  [[ -n "${WAYLAND_DISPLAY:-}" ]] || failures=$((failures + 1))
  [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] || failures=$((failures + 1))
  if [[ "${XDG_SESSION_TYPE:-wayland}" != "wayland" ]]; then
    fail 'XDG_SESSION_TYPE is not wayland'
    failures=$((failures + 1))
  fi
  if [[ "${XDG_CURRENT_DESKTOP:-Hyprland}" != *Hyprland* && "${XDG_CURRENT_DESKTOP:-}" != *Hyprland* ]]; then
    warn 'XDG_CURRENT_DESKTOP does not identify Hyprland'
  fi

  echo
  echo 'User services'
  unit_state pipewire.service || failures=$((failures + 1))
  unit_state wireplumber.service || failures=$((failures + 1))
  unit_state xdg-desktop-portal-hyprland.service || failures=$((failures + 1))
  unit_state xdg-desktop-portal.service || failures=$((failures + 1))
  portal_bus_ready || failures=$((failures + 1))

  echo
  echo 'Client mode'
  print_discord_mode

  echo
  echo 'Recent XDPH messages'
  journalctl --user -u xdg-desktop-portal-hyprland.service -n 8 --no-pager 2>/dev/null \
    | sed 's/^/  /' || true

  echo
  if ((failures == 0)); then
    ok 'Wayland screen-share backend looks ready'
    return 0
  fi

  fail "screen-share health found $failures blocking issue(s)"
  echo '  Run: bash screen-share.sh repair'
  return 1
}

repair_portals() {
  if [[ -z "${WAYLAND_DISPLAY:-}" || -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    fail 'Run repair from inside the active Hyprland session.'
    return 1
  fi

  export XDG_CURRENT_DESKTOP="${XDG_CURRENT_DESKTOP:-Hyprland}"
  export XDG_SESSION_DESKTOP="${XDG_SESSION_DESKTOP:-Hyprland}"
  export XDG_SESSION_TYPE="${XDG_SESSION_TYPE:-wayland}"

  echo '[Raohane] Importing the active Hyprland environment into user services...'
  systemctl --user import-environment \
    WAYLAND_DISPLAY \
    XDG_CURRENT_DESKTOP \
    XDG_SESSION_DESKTOP \
    XDG_SESSION_TYPE \
    HYPRLAND_INSTANCE_SIGNATURE

  if command -v dbus-update-activation-environment >/dev/null 2>&1; then
    dbus-update-activation-environment --systemd \
      WAYLAND_DISPLAY \
      XDG_CURRENT_DESKTOP \
      XDG_SESSION_DESKTOP \
      XDG_SESSION_TYPE \
      HYPRLAND_INSTANCE_SIGNATURE
  fi

  local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/xdg-desktop-portal"
  local config_file="$config_dir/hyprland-portals.conf"
  mkdir -p "$config_dir"
  if [[ ! -e "$config_file" ]]; then
    cat > "$config_file" <<'EOF'
[preferred]
default=hyprland;gtk
org.freedesktop.impl.portal.ScreenCast=hyprland
org.freedesktop.impl.portal.Screenshot=hyprland
EOF
    ok "created $config_file"
  else
    warn "kept existing $config_file unchanged"
  fi

  echo '[Raohane] Restarting the portal stack...'
  systemctl --user stop xdg-desktop-portal.service >/dev/null 2>&1 || true
  systemctl --user restart xdg-desktop-portal-hyprland.service
  systemctl --user restart xdg-desktop-portal-gtk.service >/dev/null 2>&1 || true
  systemctl --user restart xdg-desktop-portal.service
  sleep 1

  print_status
}

case "$mode" in
  status|doctor)
    print_status
    ;;
  repair|fix)
    repair_portals
    ;;
  *)
    echo 'Usage: screen-share.sh [status|repair]' >&2
    exit 2
    ;;
esac
