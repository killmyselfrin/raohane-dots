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
  --check     Report missing requirements without installing anything.
  --print     Print the currently resolved provider for each requirement.
  -h, --help  Show this help.

Manifest syntax:
  package-a
  package-a|package-b

For an alternative requirement, any already-installed provider satisfies it.
If none is installed, the first provider is the preferred official-repository
package installed by Raohane.

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

preferred_provider() {
  local requirement="$1"
  printf '%s\n' "${requirement%%|*}"
}

installed_provider() {
  local requirement="$1"
  local provider
  local -a providers=()
  IFS='|' read -r -a providers <<< "$requirement"

  for provider in "${providers[@]}"; do
    if pacman -Qq "$provider" >/dev/null 2>&1; then
      printf '%s\n' "$provider"
      return 0
    fi
  done
  return 1
}

requirement_label() {
  local requirement="$1"
  printf '%s\n' "${requirement//|/ or }"
}

requirements=()
while IFS= read -r requirement; do requirements+=("$requirement"); done < <(read_manifest "$MANIFEST_DIR/required.txt")
if [[ "$MODE" == "full" ]]; then
  while IFS= read -r requirement; do requirements+=("$requirement"); done < <(read_manifest "$MANIFEST_DIR/features.txt")
fi

mapfile -t requirements < <(printf '%s\n' "${requirements[@]}" | awk '!seen[$0]++')

case "$ACTION" in
  print)
    for requirement in "${requirements[@]}"; do
      if provider="$(installed_provider "$requirement")"; then
        printf '%s\n' "$provider"
      else
        preferred_provider "$requirement"
      fi
    done
    exit 0
    ;;

  check)
    missing=()
    for requirement in "${requirements[@]}"; do
      installed_provider "$requirement" >/dev/null || missing+=("$requirement")
    done

    if ((${#missing[@]} == 0)); then
      echo "[Raohane] All $MODE dependency requirements are satisfied."
      exit 0
    fi

    echo "[Raohane] Missing $MODE requirements:"
    for requirement in "${missing[@]}"; do
      printf '  - %s\n' "$(requirement_label "$requirement")"
    done
    exit 1
    ;;

  install)
    missing=()
    install_packages=()

    for requirement in "${requirements[@]}"; do
      if ! installed_provider "$requirement" >/dev/null; then
        missing+=("$requirement")
        install_packages+=("$(preferred_provider "$requirement")")
      fi
    done

    echo "[Raohane] Resolving standalone $MODE dependency set (${#requirements[@]} requirements)."
    echo '[Raohane] Source: install/arch/*.txt in this repository.'
    echo '[Raohane] Existing compatible providers are preserved.'
    echo '[Raohane] GPU drivers are not selected or replaced.'

    if ((${#install_packages[@]} == 0)); then
      echo '[Raohane] All dependency requirements are already satisfied.'
    else
      echo "[Raohane] Installing ${#install_packages[@]} missing package(s):"
      printf '  - %s\n' "${install_packages[@]}"
      sudo pacman -S --needed -- "${install_packages[@]}"
    fi

    unresolved=()
    for requirement in "${requirements[@]}"; do
      installed_provider "$requirement" >/dev/null || unresolved+=("$requirement")
    done

    if ((${#unresolved[@]} > 0)); then
      echo '[Raohane] Dependency verification failed for:' >&2
      for requirement in "${unresolved[@]}"; do
        printf '  - %s\n' "$(requirement_label "$requirement")" >&2
      done
      exit 1
    fi

    echo
    echo '[Raohane] Dependency installation complete.'
    echo '[Raohane] Run: raohane doctor deps'
    ;;
esac
