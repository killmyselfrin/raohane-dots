#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'nix-boundary-audit: %s\n' "$*" >&2
  exit 1
}

for path in flake.nix nix/package.nix nix/home-module.nix nix/nixos-module.nix; do
  [[ -f "$path" ]] || fail "missing Nix path: $path"
done

if rg -n -i '\binir\b|\bniri\b|programs\.serpantinum|share/serpantinum' flake.nix nix; then
  fail 'Nix deployment still contains a non-Raohane shell identity'
fi

rg -q 'Raohane desktop shell for Hyprland' flake.nix || fail 'flake description is not Raohane/Hyprland owned'
rg -q 'raohane = package' flake.nix || fail 'flake does not export the named Raohane package'
rg -q 'nixosModules' flake.nix || fail 'flake does not export a NixOS module'
rg -q 'homeManagerModules' flake.nix || fail 'flake does not export a Home Manager module'
rg -q 'share/raohane' nix/package.nix || fail 'package runtime path is not Raohane owned'
rg -q 'prune-runtime\.sh' nix/package.nix || fail 'Nix package does not prune source-only runtime files'
rg -q 'validate-runtime-payload\.sh' nix/package.nix || fail 'Nix package does not validate its staged runtime'
rg -q 'quickshell/raohane' nix/home-module.nix || fail 'Home Manager does not expose the Quickshell config'
rg -q 'systemd\.user\.services\.raohane' nix/home-module.nix || fail 'Home Manager does not own the user service'

for marker in \
  quickshell hyprland networkmanager networkmanagerapplet wireplumber pipewire bluez blueman upower \
  polkit xdg-desktop-portal-hyprland brightnessctl ddcutil grim slurp cliphist \
  ffmpeg imagemagick hyprsunset wf-recorder ydotool easyeffects fprintd libqalculate pciutils \
  tesseract translate-shell ripgrep jq libnotify wl-clipboard; do
  rg -q "\\b${marker}\\b" nix/package.nix || fail "Nix runtime dependency missing: $marker"
done

rg -q 'QML2_IMPORT_PATH' nix/package.nix || fail 'Nix wrapper does not expose Qt QML imports'
rg -q 'qt6\.qtmultimedia' nix/package.nix || fail 'Nix runtime lost Qt Multimedia'
rg -q 'qt6\.qt5compat' nix/package.nix || fail 'Nix runtime lost Qt 5Compat effects'

for marker in networkmanager bluetooth pipewire polkit material-symbols noto-fonts nerd-fonts; do
  rg -q "$marker" nix/nixos-module.nix || fail "NixOS system boundary missing: $marker"
done

if command -v nix-instantiate >/dev/null 2>&1; then
  for file in flake.nix nix/package.nix nix/home-module.nix nix/nixos-module.nix; do
    nix-instantiate --parse "$file" >/dev/null || fail "Nix parser rejected $file"
  done
fi

printf 'nix-boundary-audit: native package, Home Manager service and NixOS dependency boundaries are valid\n'
