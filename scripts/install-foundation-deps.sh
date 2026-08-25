#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
LOCK_FILE="$ROOT/upstream/illogical-impulse.lock"
CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
CACHE_DIR="$CACHE_HOME/raohane/illogical-impulse"

if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
  echo '[Raohane] Do not run this installer as root. It will request sudo when needed.' >&2
  exit 1
fi

[[ -f /etc/os-release ]] || { echo '[Raohane] /etc/os-release not found.' >&2; exit 1; }
# shellcheck disable=SC1091
source /etc/os-release
case " ${ID:-} ${ID_LIKE:-} " in
  *' arch '*|*' cachyos '*|*' endeavouros '*) ;;
  *)
    echo "[Raohane] Foundation dependency bootstrap is currently implemented for Arch-based systems only." >&2
    echo "Detected: ID=${ID:-unknown} ID_LIKE=${ID_LIKE:-unknown}" >&2
    exit 1
    ;;
esac

for cmd in git bash; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "[Raohane] Missing command: $cmd" >&2; exit 1; }
done

[[ -f "$LOCK_FILE" ]] || { echo "[Raohane] Missing $LOCK_FILE" >&2; exit 1; }
# shellcheck disable=SC1090
source "$LOCK_FILE"
: "${repo:?Missing repo in dependency lock}"
: "${ref:?Missing ref in dependency lock}"

mkdir -p "$(dirname "$CACHE_DIR")"
if [[ ! -d "$CACHE_DIR/.git" ]]; then
  git clone "$repo" "$CACHE_DIR"
fi

git -C "$CACHE_DIR" fetch --all --tags --prune
git -C "$CACHE_DIR" checkout --detach "$ref"

actual_ref="$(git -C "$CACHE_DIR" rev-parse HEAD)"
[[ "$actual_ref" == "$ref" ]] || {
  echo "[Raohane] Dependency source lock mismatch." >&2
  exit 1
}

cat <<EOF
[Raohane] Using illogical-impulse dependency model @ $ref
[Raohane] Source: $CACHE_DIR

This installs the tracked Arch dependency meta-packages used by the end4-pC/
illogical-impulse foundation. GPU drivers are intentionally NOT selected or
replaced by this helper.
EOF

cd "$CACHE_DIR"
./setup install-deps

echo
printf '[Raohane] Foundation dependencies installed from %s\n' "$ref"
echo '[Raohane] Next: run the Raohane foundation sync and then test qs -c raohane.'
