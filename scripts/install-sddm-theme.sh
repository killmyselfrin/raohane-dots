#!/usr/bin/env bash
set -euo pipefail
# Compatibility entry point: both commands install the same canonical theme.
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
exec bash "$ROOT/scripts/install-login-theme.sh" "$@"
