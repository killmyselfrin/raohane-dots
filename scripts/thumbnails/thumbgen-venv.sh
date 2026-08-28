#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

command -v python3 >/dev/null 2>&1 || {
  echo '[Raohane] python3 is required for thumbnail generation.' >&2
  exit 1
}

exec python3 "$SCRIPT_DIR/thumbgen.py" "$@"
