#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'graphics-driver-boundary-audit: %s\n' "$*" >&2
  exit 1
}

probe='scripts/graphics-driver-check.py'
service='modules/raohane/services/RaohaneGraphics.qml'
page='modules/raohane/RaohaneSettingsGraphics.qml'
registry='modules/raohane/RaohaneSettingsPageRegistry.qml'
runtime_validator='scripts/validate-runtime-payload.sh'

for path in "$probe" "$service" "$page" "$registry" "$runtime_validator"; do
  [[ -f "$path" ]] || fail "missing graphics driver path: $path"
done

python3 - "$probe" <<'PY' || fail 'graphics driver probe has invalid Python syntax'
import pathlib
import sys
path = pathlib.Path(sys.argv[1])
compile(path.read_text(encoding="utf-8"), str(path), "exec")
PY

rg -q 'FULL_UPGRADE_COMMAND[[:space:]]*=[[:space:]]*"sudo pacman -Syu"' "$probe" \
  || fail 'Arch update recommendation is no longer the full-system pacman upgrade'
rg -q 'checkupdates' "$probe" \
  || fail 'fresh Arch repository update check is missing'
rg -q 'pacman", "-Qu"' "$probe" \
  || fail 'local pacman database fallback is missing'
rg -q '^pacman-contrib$' install/arch/features.txt \
  || fail 'pacman-contrib is not part of the full feature dependency profile'
rg -q '^polkit$' install/arch/required.txt \
  || fail 'Polkit is not part of the required runtime profile'

# Detection remains read-only. The probe may inspect package names, but must
# never install/remove/switch a graphics driver family.
if rg -n \
  'pacman[[:space:]]+-(S|R)[^\n]*(nvidia|nouveau|mesa|vulkan|amdvlk)|subprocess\.(run|Popen).*pacman.*-(S|R)|\["pacman",[[:space:]]*"-(S|R)' \
  "$probe"; then
  fail 'graphics probe can mutate installed driver packages'
fi
if rg -n \
  '(nvidia-open|nvidia-dkms|xf86-video-amdgpu|vulkan-radeon|vulkan-intel).*(install|remove|replace|switch)' \
  "$probe"; then
  fail 'graphics probe contains a driver-family switch path'
fi

rg -q '^singleton RaohaneGraphics 1\.0 RaohaneGraphics\.qml$' modules/raohane/services/qmldir \
  || fail 'RaohaneGraphics singleton is not registered'
rg -q '^RaohaneSettingsGraphics 1\.0 RaohaneSettingsGraphics\.qml$' modules/raohane/qmldir \
  || fail 'Graphics settings page is not registered'
rg -q 'key:[[:space:]]*"graphics"' "$registry" \
  || fail 'Graphics & Drivers is missing from Settings navigation'
rg -q 'source:[[:space:]]*"RaohaneSettingsGraphics\.qml"' "$registry" \
  || fail 'Graphics Settings route does not load the native page'

# The check is intentionally lazy: opening the page triggers it, shell startup
# must not perform a repository/network probe.
if rg -n 'Component\.onCompleted:[^\n]*checkNow|Component\.onCompleted[[:space:]]*\{[^}]*checkNow' "$service"; then
  fail 'graphics service performs an automatic shell-start update check'
fi
rg -q 'Component\.onCompleted:[[:space:]]*root\.refresh\(false\)' "$page" \
  || fail 'Graphics Settings no longer owns the lazy first check'
rg -q 'minimumAutomaticCheckInterval:[[:space:]]*10[[:space:]]*\*[[:space:]]*60[[:space:]]*\*[[:space:]]*1000' "$service" \
  || fail 'graphics update probe lost its 10-minute UI cache'

# One-click updates are allowed only through the root-owned pkexec and pacman
# binaries, and only as a normal full Arch system upgrade. A user-writable
# script must never become a privileged update helper.
rg -q 'function updateNow\(\): void' "$service" \
  || fail 'graphics service lost the explicit update action'
rg -q 'updater\.command[[:space:]]*=[[:space:]]*\["pkexec",[[:space:]]*"/usr/bin/pacman",[[:space:]]*"-Syu",[[:space:]]*"--noconfirm"\]' "$service" \
  || fail 'graphics update action is not the exact Polkit full-system upgrade'
rg -q 'RaohaneGraphics\.updateNow\(\)' "$page" \
  || fail 'Graphics Settings does not expose the native update action'
rg -q 'RaohaneGraphics\.canUpdate' "$page" \
  || fail 'Graphics update button is not gated by service state'

if rg -n '(pkexec|sudo|pacman[[:space:]]+-S)' "$page"; then
  fail 'presentation QML gained a direct privileged package command'
fi
if rg -n \
  'updater\.command[^\n]*(nvidia|nouveau|mesa|vulkan|amdvlk|xf86-video)|updater\.command[^\n]*(scripts/|Quickshell\.shellPath|bash|python|/bin/sh)' \
  "$service"; then
  fail 'graphics updater can select a driver family or execute a user-writable helper as root'
fi
if rg -n 'Process[[:space:]]*\{[^}]*pkexec' "$page"; then
  fail 'privileged update process escaped from the graphics service boundary'
fi

rg -q 'Quickshell\.clipboardText[[:space:]]*=[[:space:]]*RaohaneGraphics\.updateCommand' "$page" \
  || fail 'manual copy fallback for the full upgrade command is missing'
rg -q 'scripts/graphics-driver-check\.py' "$runtime_validator" \
  || fail 'installed runtime validator does not require the graphics probe'

printf 'graphics-driver-boundary-audit: hardware-aware detection, lazy freshness checks, Polkit-gated full upgrades, root-owned executables and no driver-family switching are enforced\n'
