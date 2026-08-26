#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST_DIR="$ROOT/install/arch"
MODE="full"
ACTION="install"

usage() {
  cat <<'EOF'
Raohane dependency installer

Usage:
  scripts/install-deps.sh [--minimal|--full] [--check|--print]

Modes:
  --minimal   Install only packages required to start the shell.
  --full      Install required packages plus Raohane desktop features (default).

Actions:
  --check     Report missing packages without installing anything.
  --print     Print the resolved package list and exit.
  -h, --help  Show this help.

This installer uses only Raohane-owned manifests and the distribution package
manager. It never clones or executes another shell repository and never changes
GPU drivers.
EOF
}

while (($#)); do
  case "$1" in
    --minimal) MODE="minimal" ;;
    --full) MODE="full" ;;
    --check) ACTION="check" ;;
    --print) ACTION="print" ;;
    -h|--help) usage; exit 0 ;;
    *) echo "[Raohane] Unknown dependency option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

if [[ ${EUID:-$(id -u)} -eq 0 && "$ACTION" == "install" ]]; then
  echo '[Raohane] Do not run this installer as root; sudo is requested by pacman.' >&2
  exit 1
fi

[[ -f /etc/os-release ]] || { echo '[Raohane] /etc/os-release not found.' >&2; exit 1; }
# shellcheck disable=SC1091
source /etc/os-release
case " ${ID:-} ${ID_LIKE:-} " in
  *' arch '*|*' cachyos '*|*' endeavouros '*) ;;
  *)
    echo '[Raohane] The standalone dependency installer currently supports Arch-based systems.' >&2
    echo "Detected: ID=${ID:-unknown} ID_LIKE=${ID_LIKE:-unknown}" >&2
    exit 1
    ;;
esac

command -v pacman >/dev/null 2>&1 || { echo '[Raohane] pacman not found.' >&2; exit 1; }

read_manifest() {
  local file="$1"
  [[ -f "$file" ]] || { echo "[Raohane] Missing manifest: $file" >&2; exit 1; }
  sed -E 's/[[:space:]]*#.*$//' "$file" | awk 'NF { print $1 }'
}

packages=()
while IFS= read -r package; do packages+=("$package"); done < <(read_manifest "$MANIFEST_DIR/required.txt")
if [[ "$MODE" == "full" ]]; then
  while IFS= read -r package; do packages+=("$package"); done < <(read_manifest "$MANIFEST_DIR/features.txt")
fi

mapfile -t packages < <(printf '%s\n' "${packages[@]}" | awk '!seen[$0]++')

case "$ACTION" in
  print)
    printf '%s\n' "${packages[@]}"
    exit 0
    ;;
  check)
    missing=()
    for package in "${packages[@]}"; do
      pacman -Qq "$package" >/dev/null 2>&1 || missing+=("$package")
    done
    if ((${#missing[@]} == 0)); then
      echo "[Raohane] All $MODE manifest packages are installed."
      exit 0
    fi
    echo "[Raohane] Missing $MODE packages:"
    printf '  - %s\n' "${missing[@]}"
    exit 1
    ;;
  install)
    echo "[Raohane] Installing standalone $MODE dependency set (${#packages[@]} packages)."
    echo '[Raohane] Source: install/arch/*.txt in this repository.'
    echo '[Raohane] GPU drivers are not selected or replaced.'
    sudo pacman -S --needed -- "${packages[@]}"
    echo
    echo '[Raohane] Dependency installation complete.'
    echo '[Raohane] Run: raohane doctor deps'
    ;;
esac
