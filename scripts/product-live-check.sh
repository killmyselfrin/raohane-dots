#!/usr/bin/env bash
set -euo pipefail

QS_CONFIG="${RAOHANE_QS_CONFIG:-raohane}"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
RUNTIME="${RAOHANE_RUNTIME:-$CONFIG_HOME/quickshell/$QS_CONFIG}"

failures=0
warnings=0

action_ok() { printf '  [ok] %s\n' "$*"; }
action_warn() { printf '  [--] %s\n' "$*"; warnings=$((warnings + 1)); }
action_bad() { printf '  [!!] %s\n' "$*"; failures=$((failures + 1)); }

ipc() {
  qs -c "$QS_CONFIG" ipc call "$@"
}

snapshot() {
  ipc runtime phase4 2>/dev/null
}

json_value() {
  local expression="$1"
  python3 -c '
import json, sys
raw = sys.stdin.read().strip()
try:
    value = json.loads(raw)
    if isinstance(value, str):
        value = json.loads(value)
except Exception:
    raise SystemExit(2)
for part in sys.argv[1].split("."):
    if not part:
        continue
    if not isinstance(value, dict):
        value = None
        break
    value = value.get(part)
if isinstance(value, bool):
    print("true" if value else "false")
elif value is None:
    print("")
elif isinstance(value, (dict, list)):
    print(json.dumps(value, ensure_ascii=False, separators=(",", ":")))
else:
    print(value)
' "$expression"
}

wait_equal() {
  local expression="$1"
  local expected="$2"
  local attempts="${3:-20}"
  local payload value
  for ((i = 0; i < attempts; i++)); do
    payload="$(snapshot || true)"
    value="$(printf '%s' "$payload" | json_value "$expression" 2>/dev/null || true)"
    [[ "$value" == "$expected" ]] && return 0
    sleep 0.25
  done
  return 1
}

wait_process_snapshot() {
  local attempts="${1:-24}"
  local payload count busy
  for ((i = 0; i < attempts; i++)); do
    payload="$(snapshot || true)"
    count="$(printf '%s' "$payload" | json_value tasks.processCount 2>/dev/null || true)"
    busy="$(printf '%s' "$payload" | json_value tasks.busy 2>/dev/null || true)"
    if [[ "$count" =~ ^[0-9]+$ ]] && ((count > 0)) && [[ "$busy" != "true" ]]; then
      return 0
    fi
    sleep 0.25
  done
  return 1
}

printf 'Raohane product live probe\n'

if ! command -v qs >/dev/null 2>&1; then
  action_bad 'qs is unavailable'
  exit 1
fi
if ! command -v python3 >/dev/null 2>&1; then
  action_bad 'python3 is unavailable'
  exit 1
fi

for path in \
  "$RUNTIME/modules/raohane/RaohaneTaskManager.qml" \
  "$RUNTIME/modules/raohane/RaohaneOverlay.qml" \
  "$RUNTIME/modules/raohane/services/RaohaneProcesses.qml" \
  "$RUNTIME/modules/raohane/services/RaohaneLyrics.qml" \
  "$RUNTIME/scripts/lyrics-resolve.py"; do
  if [[ -f "$path" ]]; then
    action_ok "${path#$RUNTIME/} installed"
  else
    action_bad "missing ${path#$RUNTIME/}"
  fi
done

payload="$(snapshot || true)"
if [[ -z "$payload" ]]; then
  action_bad 'runtime IPC snapshot unavailable'
else
  for key in tasks media lyrics; do
    if printf '%s' "$payload" | python3 -c '
import json, sys
raw=sys.stdin.read().strip()
data=json.loads(raw)
if isinstance(data,str): data=json.loads(data)
raise SystemExit(0 if sys.argv[1] in data else 1)
' "$key" 2>/dev/null; then
      action_ok "runtime snapshot exposes $key state"
    else
      action_bad "runtime snapshot missing $key state"
    fi
  done
fi

# Native Task Manager is a coordinated primary surface and its process service
# is intentionally dormant until the surface opens.
if ipc taskManager open >/dev/null 2>&1 && wait_equal tasks.open true 20; then
  action_ok 'Task Manager opened through native IPC'
  if wait_process_snapshot 28; then
    count="$(snapshot | json_value tasks.processCount 2>/dev/null || echo '?')"
    action_ok "Task Manager produced a live user-process snapshot (${count})"
  else
    action_bad 'Task Manager did not produce a process snapshot'
  fi
else
  action_bad 'Task Manager failed to open through native IPC'
fi
ipc taskManager close >/dev/null 2>&1 || true
if wait_equal tasks.open false 12; then
  action_ok 'Task Manager closed through native IPC'
else
  action_bad 'Task Manager did not close cleanly'
fi

if ipc overlay open >/dev/null 2>&1 && wait_equal chrome.overlayOpen true 20; then
  action_ok 'Fullscreen Command Deck opened through native IPC'
else
  action_bad 'Fullscreen Command Deck failed to open'
fi
ipc overlay close >/dev/null 2>&1 || true
if wait_equal chrome.overlayOpen false 12; then
  action_ok 'Fullscreen Command Deck closed cleanly'
else
  action_bad 'Fullscreen Command Deck did not close cleanly'
fi

# Lyrics are track-dependent. When a player exists, detect hard resolver/network
# failures automatically; a legitimate not-found result is reported as partial
# evidence instead of failing a release for a song that simply has no lyrics.
payload="$(snapshot || true)"
media_available="$(printf '%s' "$payload" | json_value media.available 2>/dev/null || true)"
if [[ "$media_available" == "true" ]]; then
  title="$(printf '%s' "$payload" | json_value media.title 2>/dev/null || true)"
  artist="$(printf '%s' "$payload" | json_value media.artist 2>/dev/null || true)"
  action_ok "MPRIS player available: ${artist:-?} — ${title:-?}"

  for ((i = 0; i < 60; i++)); do
    payload="$(snapshot || true)"
    loading="$(printf '%s' "$payload" | json_value lyrics.loading 2>/dev/null || true)"
    [[ "$loading" != "true" ]] && break
    sleep 0.25
  done

  status="$(printf '%s' "$payload" | json_value lyrics.status 2>/dev/null || true)"
  available="$(printf '%s' "$payload" | json_value lyrics.available 2>/dev/null || true)"
  synced="$(printf '%s' "$payload" | json_value lyrics.synced 2>/dev/null || true)"
  case "$status" in
    matched)
      action_ok "lyrics resolver matched current track (synced=${synced:-false})"
      ;;
    not-found|identity-mismatch)
      action_warn 'lyrics resolver completed but current track has no confident LRCLIB match'
      ;;
    network-error|resolver-failed|timeout|invalid-response)
      action_bad "lyrics resolver runtime failure: $status"
      ;;
    *)
      if [[ "$available" == "true" ]]; then
        action_ok "lyrics data available (status=${status:-unknown})"
      else
        action_warn "lyrics state is ${status:-idle}; use a known LRCLIB track for the release lyrics gate"
      fi
      ;;
  esac
else
  action_warn 'no MPRIS player is active; lyrics runtime could not be exercised'
fi

printf '  result: failures=%d warnings=%d\n' "$failures" "$warnings"
((failures == 0)) || exit 1
