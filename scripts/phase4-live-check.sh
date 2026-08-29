#!/usr/bin/env bash
set -euo pipefail

QS_CONFIG="${RAOHANE_QS_CONFIG:-raohane}"
SERVICE="${RAOHANE_SERVICE:-raohane.service}"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
RUNTIME="${RAOHANE_RUNTIME:-$CONFIG_HOME/quickshell/$QS_CONFIG}"
NATIVE_CONFIG="$CONFIG_HOME/raohane/native.json"

failures=0
exercise=0
vertical_cycle=0
lock_cycle=0
capture_cycle=0
translate_cycle=0
restore_vertical_needed=0
original_vertical=""
monitor_tmp=""

usage() {
  cat <<'EOF'
Raohane Phase 4 live validator

Usage:
  phase4-live-check.sh [--exercise] [--vertical] [--lock] [--capture] [--translate] [--full]

Default mode is non-destructive and validates the live Hyprland/Quickshell
runtime, native source tree, IPC probe, monitor state and feature backends.

Optional runtime exercises:
  --exercise   open/close Settings, OSK, Overlay, SidebarLeft, DropShelf and Translator
  --vertical   temporarily enable the vertical bar, verify its real IPC runtime, then restore config
  --lock       perform a real lock/unlock cycle; you must unlock normally
  --capture    perform a real region screenshot and verify clipboard image data
  --translate  start a real region OCR/translation cycle and verify result UI opens
  --full       run exercise + vertical + capture + translate + lock (interactive)
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

wait_for_bar_mode() {
  local expected="$1"
  local timeout_seconds="${2:-15}"
  local i mode

  for ((i = 0; i < timeout_seconds; i++)); do
    mode="$(ipc bar mode 2>/dev/null || true)"
    if [[ "$mode" == *"$expected"* ]]; then
      return 0
    fi
    sleep 1
  done
  return 1
}

read_config_vertical() {
  python3 - "$NATIVE_CONFIG" <<'PY'
import json, pathlib, sys
path = pathlib.Path(sys.argv[1])
data = json.loads(path.read_text(encoding="utf-8"))
print("true" if bool(data.get("bar", {}).get("vertical", False)) else "false")
PY
}

set_config_vertical() {
  local value="$1"
  python3 - "$NATIVE_CONFIG" "$value" <<'PY'
import json, os, pathlib, sys, tempfile
path = pathlib.Path(sys.argv[1])
value = sys.argv[2].lower() == "true"
data = json.loads(path.read_text(encoding="utf-8"))
data.setdefault("bar", {})["vertical"] = value
path.parent.mkdir(parents=True, exist_ok=True)
fd, tmp_name = tempfile.mkstemp(prefix=path.name + ".phase4-", dir=path.parent)
try:
    with os.fdopen(fd, "w", encoding="utf-8") as handle:
        json.dump(data, handle, indent=2, ensure_ascii=False)
        handle.write("\n")
        handle.flush()
        os.fsync(handle.fileno())
    os.replace(tmp_name, path)
finally:
    if os.path.exists(tmp_name):
        os.unlink(tmp_name)
PY
}

restore_vertical_config() {
  if ((restore_vertical_needed)) && [[ -n "$original_vertical" && -f "$NATIVE_CONFIG" ]]; then
    set_config_vertical "$original_vertical" >/dev/null 2>&1 || true
    restore_vertical_needed=0
  fi
}

cleanup() {
  [[ -z "$monitor_tmp" ]] || rm -f -- "$monitor_tmp"
  restore_vertical_config
}
trap cleanup EXIT

clipboard_image_hash() {
  if ! have wl-paste; then
    return 1
  fi
  wl-paste --type image/png 2>/dev/null | sha256sum 2>/dev/null | awk '{print $1}'
}

for arg in "$@"; do
  case "$arg" in
    --exercise) exercise=1 ;;
    --vertical) vertical_cycle=1 ;;
    --lock) lock_cycle=1 ;;
    --capture) capture_cycle=1 ;;
    --translate) translate_cycle=1 ;;
    --full)
      exercise=1
      vertical_cycle=1
      capture_cycle=1
      translate_cycle=1
      lock_cycle=1
      ;;
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
  ok 'HYPRLAND_INSTANCE_SIGNATURE is set'
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
monitor_tmp="$(mktemp /tmp/raohane-phase4-monitors.XXXXXX.json)"
if have hyprctl && hyprctl -j monitors >"$monitor_tmp" 2>/dev/null; then
  if python3 - "$monitor_tmp" <<'PY'
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

expected_bar_mode="horizontal"
if [[ "$(printf '%s' "$payload" | json_value bar.vertical 2>/dev/null || true)" == "true" ]]; then
  expected_bar_mode="vertical"
fi
if wait_for_bar_mode "$expected_bar_mode" 5; then
  ok "active bar IPC is owned by the ${expected_bar_mode} component"
else
  bad "active bar component does not report expected mode: ${expected_bar_mode}"
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

  if ipc settings page interface:frameEnabled >/dev/null 2>&1 && wait_for_json_value settings.open true 5; then
    ok 'Settings opened and accepted exact native control routing'
  else
    bad 'Settings did not open through exact native page/control IPC'
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

  if ipc sidebarLeft open >/dev/null 2>&1 && wait_for_json_value chrome.sidebarLeftOpen true 5; then
    ok 'left sidebar opened through live IPC'
  else
    bad 'left sidebar did not open through live IPC'
  fi
  ipc sidebarLeft close >/dev/null 2>&1 || true

  if ipc dropShelf open >/dev/null 2>&1 && wait_for_json_value chrome.dropShelfOpen true 5; then
    ok 'DropShelf opened through live IPC'
  else
    bad 'DropShelf did not open through live IPC'
  fi
  ipc dropShelf close >/dev/null 2>&1 || true

  if ipc screenTranslator open >/dev/null 2>&1 && wait_for_json_value capture.screenTranslatorOpen true 5; then
    ok 'Screen Translator opened through live IPC'
  else
    bad 'Screen Translator did not open through live IPC'
  fi
  ipc screenTranslator close >/dev/null 2>&1 || true
fi

if ((vertical_cycle)); then
  echo
echo 'Vertical bar product exercise'
  if [[ ! -f "$NATIVE_CONFIG" ]]; then
    bad "native config missing: $NATIVE_CONFIG"
  else
    original_vertical="$(read_config_vertical 2>/dev/null || true)"
    if [[ "$original_vertical" != "true" && "$original_vertical" != "false" ]]; then
      bad 'could not read current bar.vertical value'
    else
      if [[ "$original_vertical" != "true" ]]; then
        restore_vertical_needed=1
        if set_config_vertical true && wait_for_json_value bar.vertical true 10; then
          ok 'temporarily enabled vertical bar through native config reload'
        else
          bad 'native config did not switch into vertical mode'
        fi
      fi

      if wait_for_bar_mode vertical 10; then
        ok 'vertical RaohaneBar component owns live bar IPC'
      else
        bad 'vertical bar component did not become the live bar IPC owner'
      fi

      if ipc bar close >/dev/null 2>&1 && wait_for_json_value bar.open false 5; then
        ok 'vertical bar close IPC updates native state'
      else
        bad 'vertical bar close IPC failed'
      fi
      if ipc bar open >/dev/null 2>&1 && wait_for_json_value bar.open true 5; then
        ok 'vertical bar open IPC updates native state'
      else
        bad 'vertical bar open IPC failed'
      fi

      if [[ "$original_vertical" == "false" ]]; then
        if set_config_vertical false && wait_for_json_value bar.vertical false 10 && wait_for_bar_mode horizontal 10; then
          ok 'restored horizontal bar and original native config'
          restore_vertical_needed=0
        else
          bad 'failed to restore horizontal bar after vertical exercise'
        fi
      fi
    fi
  fi
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
