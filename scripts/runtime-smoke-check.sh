#!/usr/bin/env bash
set -euo pipefail

QS_CONFIG="${RAOHANE_QS_CONFIG:-raohane}"
SERVICE="${RAOHANE_SERVICE:-raohane.service}"
SINCE="${RAOHANE_SMOKE_SINCE:-}"
LOG_FILE="${RAOHANE_SMOKE_LOG_FILE:-}"
STRICT_LOGS=0
failures=0
warnings=0
log_tmp=""

usage() {
  cat <<'EOF'
Raohane runtime smoke validator

Usage:
  runtime-smoke-check.sh [--since WHEN] [--log-file FILE] [--strict-logs]

Checks the live Raohane IPC snapshot and scans current-runtime logs for high-value
QML/Qt runtime failures that static qmlformat parsing cannot detect.

Options:
  --since WHEN       override journal start time (journalctl --since syntax)
  --log-file FILE    scan an explicit foreground Quickshell log file
  --strict-logs      fail instead of warn when no trustworthy log source exists
  -h, --help         show this help

When raohane.service is active and --since is omitted, logs are scanned only
from the service's current ActiveEnterTimestamp so stale failures from older
runs cannot poison the result.
EOF
}

ok() { printf '  [ok] %s\n' "$*"; }
warn() { printf '  [--] %s\n' "$*"; warnings=$((warnings + 1)); }
bad() { printf '  [!!] %s\n' "$*"; failures=$((failures + 1)); }
have() { command -v "$1" >/dev/null 2>&1; }

cleanup() {
  [[ -z "$log_tmp" ]] || rm -f -- "$log_tmp"
}
trap cleanup EXIT

while (($# > 0)); do
  case "$1" in
    --since)
      [[ $# -ge 2 ]] || { echo '--since requires a value' >&2; exit 2; }
      SINCE="$2"
      shift 2
      ;;
    --log-file)
      [[ $# -ge 2 ]] || { echo '--log-file requires a path' >&2; exit 2; }
      LOG_FILE="$2"
      shift 2
      ;;
    --strict-logs)
      STRICT_LOGS=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

printf 'Raohane runtime smoke validation\n\n'

if ! have qs; then
  bad 'qs is unavailable'
  printf '\nRuntime smoke validation: FAIL (%d failure(s), %d warning(s))\n' "$failures" "$warnings"
  exit 1
fi
if ! have python3; then
  bad 'python3 is unavailable'
  printf '\nRuntime smoke validation: FAIL (%d failure(s), %d warning(s))\n' "$failures" "$warnings"
  exit 1
fi

printf 'Live runtime\n'
payload="$(qs -c "$QS_CONFIG" ipc call runtime phase4 2>/dev/null || true)"
if [[ -z "$payload" ]]; then
  bad "runtime IPC unavailable for config '$QS_CONFIG'"
else
  if printf '%s' "$payload" | python3 -c '
import json, sys
raw = sys.stdin.read().strip()
try:
    data = json.loads(raw)
    if isinstance(data, str):
        data = json.loads(data)
except Exception:
    raise SystemExit(1)
required = ("ready", "monitors", "bar", "lock", "settings", "chrome", "capture")
raise SystemExit(0 if isinstance(data, dict) and all(key in data for key in required) and data.get("monitors") else 1)
'; then
    ok 'runtime IPC returned a complete Phase 4 snapshot'
  else
    bad 'runtime IPC returned invalid/incomplete Phase 4 JSON'
  fi
fi

printf '\nRuntime log source\n'
log_tmp="$(mktemp /tmp/raohane-runtime-smoke.XXXXXX.log)"
log_source=""

if [[ -n "$LOG_FILE" ]]; then
  if [[ -r "$LOG_FILE" ]]; then
    cat -- "$LOG_FILE" >"$log_tmp"
    log_source="file:$LOG_FILE"
    ok "using explicit log file: $LOG_FILE"
  else
    bad "explicit log file is not readable: $LOG_FILE"
  fi
elif have systemctl && have journalctl && systemctl --user --quiet is-active "$SERVICE" 2>/dev/null; then
  if [[ -z "$SINCE" ]]; then
    SINCE="$(systemctl --user show "$SERVICE" -p ActiveEnterTimestamp --value 2>/dev/null || true)"
  fi
  if [[ -z "$SINCE" ]]; then
    SINCE='-5 minutes'
    warn 'service start timestamp unavailable; using the last 5 minutes'
  fi
  if journalctl --user -u "$SERVICE" --since "$SINCE" --no-pager -o cat >"$log_tmp" 2>/dev/null; then
    log_source="journal:$SERVICE"
    ok "using current service journal since $SINCE"
  else
    bad "could not read journal for $SERVICE"
  fi
else
  if ((STRICT_LOGS)); then
    bad 'no trustworthy runtime log source; use --log-file for foreground raohane run'
  else
    warn 'no service journal available; use --log-file FILE for foreground raohane run'
  fi
fi

if [[ -n "$log_source" ]]; then
  printf '\nQML / Qt runtime diagnostics\n'

  # Deliberately narrow high-signal patterns. Do not fail on every Qt warning:
  # desktop environments routinely emit harmless backend/theme warnings.
  fatal_pattern='QQmlApplicationEngine failed to load|is not a type|ReferenceError:|TypeError:|Unable to assign|Cannot assign|Cannot anchor|Detected anchors on an item that is managed by a layout|Binding loop detected|Cannot read property|Cannot call method|module .* is not installed|module .* plugin .* not found|Singleton.*(not creatable|pragma Singleton|qmldir)'

  if matches="$(grep -EinE "$fatal_pattern" "$log_tmp" 2>/dev/null || true)" && [[ -n "$matches" ]]; then
    bad 'high-signal QML/Qt runtime failures found'
    printf '%s\n' "$matches" | tail -n 24 | sed 's/^/    /'
  else
    ok 'no high-signal QML/Qt runtime failures found'
  fi

  if grep -Eqi 'QML.*(warning|error)|qml:.*(warning|error)' "$log_tmp" 2>/dev/null; then
    warn 'additional QML warning/error text exists outside the fatal signature set'
  fi
fi

printf '\nRuntime smoke validation: '
if ((failures > 0)); then
  printf 'FAIL (%d failure(s), %d warning(s))\n' "$failures" "$warnings"
  exit 1
fi
if ((warnings > 0)); then
  printf 'PASS WITH WARNINGS (%d warning(s))\n' "$warnings"
else
  printf 'PASS\n'
fi
