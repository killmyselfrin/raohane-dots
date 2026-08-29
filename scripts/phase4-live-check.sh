#!/usr/bin/env bash
set -euo pipefail

QS_CONFIG="${RAOHANE_QS_CONFIG:-raohane}"
SERVICE="${RAOHANE_SERVICE:-raohane.service}"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
RUNTIME="${RAOHANE_RUNTIME:-$CONFIG_HOME/quickshell/$QS_CONFIG}"

failures=0
exercise=0
lock_cycle=0
capture_cycle=0
translate_cycle=0

usage() {
  cat <<'EOF'
Raohane Phase 4 live validator

Usage:
  phase4-live-check.sh [--exercise] [--lock] [--capture] [--translate]

Default mode is non-destructive and validates the live Hyprland/Quickshell
runtime, native source tree, IPC probe, monitor state and feature backends.

Optional runtime exercises:
  --exercise   open/close Settings, OSK, Overlay and Translator surfaces
  --lock       perform a real lock/unlock cycle; you must unlock normally
  --capture    perform a real region screenshot and verify clipboard image data
  --translate  start a real region OCR/translation cycle and verify result UI opens
EOF
}

ok() {
  printf '  [ok] %s\n' "$*"
}

warn() {
  printf '  [--] %s\n' "$*"
}

bad() {
  printf '  [!!] %s\n' "$*"
  failures=$((failures + 1))
}

have() {
  command -v "$1" >/dev/null 2>&1
}

ipc() {
  qs -c "$QS_CONFIG" ipc call "$@"
}

phase4_json() {
  ipc runtime phase4 2>/dev/null
}

json_value() {
  local expression="$1"
  python3 -c '
import json, sys
expr = sys.argv[1]
raw = sys.stdin.read().strip()
try:
    data = json.loads(raw)
    if isinstance(data, str):
        data = json.loads(data)
except Exception:
    raise SystemExit(2)
value = data
for part in expr.split("."):
    if not part:
        continue
    if isinstance(value, dict):
        value = value.get(part)
    else:
        value = None
        break
if isinstance(value, bool):
    print("true" if value else "false")
elif value is None:
    print("")
elif isinstance(value, (dict, list)):
    print(json.dumps(value, separators=(",", ":")))
else:
    print(value)
' "$expression"
}

wait_for_json_value() {
  local expression="$1"
  local expected="$2"
  local timeout_seconds="${3:-15}"
  local i payload value

  for ((i = 0; i < timeout_seconds; i++)); do
    payload="$(phase4_json || true)"
    value="$(printf '%s' "$payload" | json_value "$expression" 2>/dev/null || true)"
    if [[ "$value" == "$expected" ]]; then
      return 0
    fi
    sleep 1
  done
  return 1
}

clipboard_image_hash() {
  if ! have wl-paste; then
    return 1
  fi
  wl-paste --type image/png 2>/dev/null | sha256sum 2>/dev/null | awk '{print $1}'
}

for arg in "$@"; do
  case "$arg" in
    --exercise) exercise=1 ;;
    --lock) lock_cycle=1 ;;
    --capture) capture_cycle=1 ;;
    --translate) translate_cycle=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $arg" >&2; usage >&2; exit 2 ;;
  esac
done

echo 'Raohane Phase 4 live validation'
echo

echo 'Session context'
if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
  ok "WAYLAND_DISPLAY=${WAYLAND_DISPLAY}"
else
  bad 'WAYLAND_DISPLAY is unset'
fi
if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
  ok "HYPRLAND_INSTANCE_SIGNATURE is set"
else
  bad 'HYPRLAND_INSTANCE_SIGNATURE is unset'
fi
if [[ "${XDG_CURRENT_DESKTOP:-}" == *Hyprland* || "${XDG_CURRENT_DESKTOP:-}" == *hyprland* ]]; then
  ok "XDG_CURRENT_DESKTOP=${XDG_CURRENT_DESKTOP}"
else
  warn "XDG_CURRENT_DESKTOP=${XDG_CURRENT_DESKTOP:-<unset>}"
fi

for command_name in qs hyprctl python3; do
  if have "$command_name"; then
    ok "$command_name available"
  else
    bad "$command_name missing"
  fi
done

echo
echo 'Installed source boundary'
for path in \
  "$RUNTIME/shell.qml" \
  "$RUNTIME/modules/raohane" \
  "$RUNTIME/modules/raohane/RaohaneRuntimeProbe.qml" \
  "$RUNTIME/modules/raohane/RaohaneLock.qml" \
  "$RUNTIME/modules/raohane/RaohaneVerticalBar.qml" \
  "$RUNTIME/modules/raohane/RaohaneScreenFrame.qml" \
  "$RUNTIME/modules/raohane/RaohaneScreenCorners.qml" \
  "$RUNTIME/modules/raohane/RaohaneRegionSelector.qml" \
  "$RUNTIME/modules/raohane/RaohaneScreenTranslator.qml" \
  "$RUNTIME/modules/raohane/RaohaneSettingsSearch.qml"; do
  if [[ -e "$path" ]]; then
    ok "${path#$RUNTIME/}"
  else
    bad "missing ${path#$RUNTIME/}"
  fi
done

for path in \
  "$RUNTIME/modules/ii" \
  "$RUNTIME/modules/common" \
  "$RUNTIME/services" \
  "$RUNTIME/GlobalStates.qml"; do
  if [[ -e "$path" ]]; then
    bad "retired runtime path present: ${path#$RUNTIME/}"
  fi
done

if [[ ! -e "$RUNTIME/modules/ii" && ! -e "$RUNTIME/modules/common" && ! -e "$RUNTIME/services" ]]; then
  ok 'retired compatibility source trees are absent'
fi

echo
echo 'Compositor state'
if have hyprctl && hyprctl -j monitors >/tmp/raohane-phase4-monitors.json 2>/dev/null; then
  if python3 - /tmp/raohane-phase4-monitors.json <<'PY'
import json, pathlib, sys
path = pathlib.Path(sys.argv[1])
try:
    monitors = json.loads(path.read_text(encoding="utf-8"))
except Exception:
    raise SystemExit(1)
if not isinstance(monitors, list) or not monitors:
    raise SystemExit(1)
for monitor in monitors:
    if not monitor.get("name"):
        raise SystemExit(1)
print(f"  [ok] Hyprland reports {len(monitors)} monitor(s): " + ", ".join(m.get("name", "?") for m in monitors))
PY
  then
    :
  else
    bad 'Hyprland monitor JSON is invalid/empty'
  fi
  rm -f /tmp/raohane-phase4-monitors.json
else
  bad 'hyprctl monitors failed'
fi

echo
echo 'Raohane runtime probe'
payload="$(phase4_json || true)"
if [[ -z "$payload" ]]; then
  bad 'runtime IPC probe unavailable; Raohane is probably not running'
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
required = ["ready", "monitors", "bar", "lock", "settings", "chrome", "capture"]
raise SystemExit(0 if all(key in data for key in required) and data["monitors"] else 1)
'; then
    ok 'runtime IPC returned the complete Phase 4 snapshot'
    printf '  mode: %s bar · %s · %s monitor(s)\n' \
      "$(printf '%s' "$payload" | json_value bar.vertical | sed 's/true/vertical/;s/false/horizontal/')" \
      "$(printf '%s' "$payload" | json_value lock.locked | sed 's/true/locked/;s/false/unlocked/')" \
      "$(printf '%s' "$payload" | json_value monitors | python3 -c 'import json,sys; print(len(json.load(sys.stdin)))' 2>/dev/null || echo '?')"
  else
    bad 'runtime IPC returned invalid/incomplete Phase 4 JSON'
  fi
fi

if lock_status="$(ipc lock status 2>/dev/null)"; then
  ok "Lock IPC responds (${lock_status})"
else
  bad 'Lock IPC status failed'
fi
if settings_status="$(ipc settings status 2>/dev/null)"; then
  ok "Settings IPC responds (${settings_status})"
else
  bad 'Settings IPC status failed'
fi

echo
echo 'Phase 4 feature backends'
for command_name in grim slurp wf-recorder wl-copy wl-paste tesseract trans ydotool; do
  if have "$command_name"; then
    ok "$command_name available"
  else
    warn "$command_name unavailable; corresponding optional feature cannot be live-tested"
  fi
done

if [[ -f "$RUNTIME/modules/raohane/pam/fprintd.conf" ]]; then
  ok 'Raohane fingerprint PAM profile installed'
else
  bad 'Raohane fingerprint PAM profile missing'
fi
if have fprintd-list; then
  ok 'fprintd tools available'
else
  warn 'fprintd-list unavailable; password/PAM lock remains valid but fingerprint path cannot be exercised'
fi

if ((exercise)); then
  echo
echo 'Non-destructive surface exercises'

  if ipc settings open >/dev/null 2>&1 && wait_for_json_value settings.open true 5; then
    ok 'Settings opened through live IPC'
  else
    bad 'Settings did not open through live IPC'
  fi
  ipc settings close >/dev/null 2>&1 || true

  if ipc osk open >/dev/null 2>&1 && wait_for_json_value chrome.oskOpen true 5; then
    ok 'OSK opened through live IPC'
  else
    bad 'OSK did not open through live IPC'
  fi
  ipc osk close >/dev/null 2>&1 || true

  if ipc overlay open >/dev/null 2>&1 && wait_for_json_value chrome.overlayOpen true 5; then
    ok 'Overlay opened through live IPC'
  else
    bad 'Overlay did not open through live IPC'
  fi
  ipc overlay close >/dev/null 2>&1 || true

  if ipc screenTranslator open >/dev/null 2>&1 && wait_for_json_value capture.screenTranslatorOpen true 5; then
    ok 'Screen Translator opened through live IPC'
  else
    bad 'Screen Translator did not open through live IPC'
  fi
  ipc screenTranslator close >/dev/null 2>&1 || true
fi

if ((capture_cycle)); then
  echo
echo 'Interactive region capture exercise'
  if ! have wl-paste || ! have sha256sum; then
    bad 'wl-paste and sha256sum are required for capture verification'
  else
    before_hash="$(clipboard_image_hash || true)"
    echo '  Select a region when slurp appears.'
    if ipc region screenshot >/dev/null 2>&1; then
      changed=0
      for _ in $(seq 1 60); do
        after_hash="$(clipboard_image_hash || true)"
        if [[ -n "$after_hash" && "$after_hash" != "$before_hash" ]]; then
          changed=1
          break
        fi
        sleep 1
      done
      if ((changed)); then
        ok 'region screenshot produced new image/png clipboard data'
      else
        bad 'region screenshot did not produce new clipboard image data within 60s'
      fi
    else
      bad 'region screenshot IPC call failed'
    fi
  fi
fi

if ((translate_cycle)); then
  echo
echo 'Interactive screen translation exercise'
  echo '  Select a text region when slurp appears.'
  ipc screenTranslator close >/dev/null 2>&1 || true
  if ipc screenTranslator translate >/dev/null 2>&1; then
    if wait_for_json_value capture.screenTranslatorOpen true 90; then
      ok 'screen translation cycle returned to the native result surface'
      ipc screenTranslator close >/dev/null 2>&1 || true
    else
      bad 'screen translation result surface did not open within 90s'
    fi
  else
    bad 'screen translation IPC call failed'
  fi
fi

if ((lock_cycle)); then
  echo
echo 'Interactive Lock exercise'
  echo '  Raohane will lock now. Unlock normally with your password/fingerprint.'
  if ipc lock activate >/dev/null 2>&1; then
    seen_locked=0
    for _ in $(seq 1 10); do
      status="$(ipc lock status 2>/dev/null || true)"
      if [[ "$status" == *locked* && "$status" != *unlocked* ]]; then
        seen_locked=1
        break
      fi
      sleep 1
    done
    if ((seen_locked)); then
      ok 'native WlSessionLock entered locked state'
      unlocked=0
      for _ in $(seq 1 180); do
        status="$(ipc lock status 2>/dev/null || true)"
        if [[ "$status" == *unlocked* ]]; then
          unlocked=1
          break
        fi
        sleep 1
      done
      if ((unlocked)); then
        ok 'native Lock completed a real unlock cycle'
      else
        bad 'lock remained active after 180s'
      fi
    else
      bad 'native Lock did not report locked state'
    fi
  else
    bad 'lock activation IPC failed'
  fi
fi

echo
if ((failures == 0)); then
  echo 'Phase 4 live validation: PASS'
else
  printf 'Phase 4 live validation: FAIL (%d issue(s))\n' "$failures" >&2
  exit 1
fi
