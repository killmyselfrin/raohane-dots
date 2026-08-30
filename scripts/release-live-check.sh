#!/usr/bin/env bash
set -euo pipefail

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
QS_CONFIG="${RAOHANE_QS_CONFIG:-raohane}"
RUNTIME="${RAOHANE_RUNTIME:-$CONFIG_HOME/quickshell/$QS_CONFIG}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

run_phase4=0
full=0
report=""

usage() {
  cat <<'EOF'
Raohane live release validator

Usage:
  release-live-check.sh [--phase4] [--full] [--report PATH]

Modes:
  default     Collect non-destructive live environment/runtime evidence.
  --phase4    Also run the safe Phase 4 live probe.
  --full      Run `phase4-live-check.sh --full` and ask for the remaining
              release/hardware confirmations that CI cannot establish.

The full mode can enter the real WlSessionLock/PAM path and interactive
capture/translation flows through the existing Phase 4 validator.
EOF
}

while (($#)); do
  case "$1" in
    --phase4)
      run_phase4=1
      ;;
    --full)
      run_phase4=1
      full=1
      ;;
    --report)
      shift
      [[ $# -gt 0 ]] || { echo 'release-live-check: --report requires a path' >&2; exit 2; }
      report="$1"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "release-live-check: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

if [[ -z "$report" ]]; then
  report_dir="$STATE_HOME/raohane/reports"
  mkdir -p "$report_dir"
  report="$report_dir/release-validation-$(date +%Y%m%d-%H%M%S).txt"
else
  mkdir -p "$(dirname -- "$report")"
fi

exec > >(tee "$report") 2>&1

failures=0
partial=0
phase4_status='not-run'
monitor_count=0

section() {
  printf '\n== %s ==\n' "$1"
}

ok() {
  printf '[ok] %s\n' "$*"
}

warn() {
  printf '[--] %s\n' "$*"
  partial=$((partial + 1))
}

fail() {
  printf '[!!] %s\n' "$*"
  failures=$((failures + 1))
}

command_line() {
  local name="$1"
  if command -v "$name" >/dev/null 2>&1; then
    printf '[ok] %-18s %s\n' "$name" "$(command -v "$name")"
  else
    printf '[!!] %-18s missing\n' "$name"
    failures=$((failures + 1))
  fi
}

find_phase4_validator() {
  local candidate
  for candidate in \
    "$RUNTIME/scripts/phase4-live-check.sh" \
    "$SCRIPT_DIR/phase4-live-check.sh"; do
    if [[ -f "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

ask_gate() {
  local key="$1"
  local question="$2"
  local answer=""

  if [[ ! -t 0 ]]; then
    printf '[--] %s: interactive confirmation unavailable (non-TTY)\n' "$key"
    partial=$((partial + 1))
    return 0
  fi

  while true; do
    printf '%s [y/n/s]: ' "$question"
    IFS= read -r answer || answer=s
    case "${answer,,}" in
      y|yes)
        printf '[ok] %s: confirmed\n' "$key"
        return 0
        ;;
      n|no)
        printf '[!!] %s: failed/not acceptable\n' "$key"
        failures=$((failures + 1))
        return 0
        ;;
      s|skip|'')
        printf '[--] %s: not validated in this run\n' "$key"
        partial=$((partial + 1))
        return 0
        ;;
      *)
        echo 'Please answer y, n or s.'
        ;;
    esac
  done
}

printf 'Raohane live release validation\n'
printf 'timestamp: %s\n' "$(date --iso-8601=seconds)"
printf 'report:    %s\n' "$report"
printf 'runtime:   %s\n' "$RUNTIME"

section 'Session boundary'
if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
  ok "WAYLAND_DISPLAY=$WAYLAND_DISPLAY"
else
  fail 'WAYLAND_DISPLAY is unset; this is not a usable Wayland validation session'
fi

if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
  ok "HYPRLAND_INSTANCE_SIGNATURE=$HYPRLAND_INSTANCE_SIGNATURE"
else
  fail 'HYPRLAND_INSTANCE_SIGNATURE is unset; a live Hyprland instance is required'
fi
printf 'XDG_CURRENT_DESKTOP=%s\n' "${XDG_CURRENT_DESKTOP:-<unset>}"
printf 'XDG_SESSION_TYPE=%s\n' "${XDG_SESSION_TYPE:-<unset>}"

section 'Required commands'
command_line qs
command_line hyprctl
command_line python3
command_line systemctl
command_line journalctl

section 'Installed runtime'
for path in \
  "$RUNTIME/shell.qml" \
  "$RUNTIME/qmldir" \
  "$RUNTIME/modules/raohane" \
  "$RUNTIME/panelFamilies/RaohaneFamily.qml" \
  "$RUNTIME/scripts/phase4-live-check.sh" \
  "$RUNTIME/scripts/validate-runtime-payload.sh"; do
  if [[ -e "$path" ]]; then
    ok "${path#$RUNTIME/}"
  else
    fail "missing ${path#$RUNTIME/}"
  fi
done

if [[ -f "$RUNTIME/scripts/validate-runtime-payload.sh" ]]; then
  if bash "$RUNTIME/scripts/validate-runtime-payload.sh" "$RUNTIME"; then
    ok 'strict installed-runtime payload validation passed'
  else
    fail 'strict installed-runtime payload validation failed'
  fi
fi

section 'Shell service'
if systemctl --user --quiet is-active raohane.service 2>/dev/null; then
  ok 'raohane.service active'
else
  warn 'raohane.service is not active; a foreground qs -c raohane process may still be valid'
  pgrep -a -u "$(id -u)" qs 2>/dev/null || true
fi

section 'Graphics'
if command -v lspci >/dev/null 2>&1; then
  lspci -nnk | grep -EA3 'VGA|3D|Display' || warn 'no VGA/3D/Display controller matched lspci output'
else
  warn 'lspci unavailable (package: pciutils); GPU vendor evidence not collected'
fi
if command -v nvidia-smi >/dev/null 2>&1; then
  nvidia-smi --query-gpu=name,driver_version --format=csv,noheader || warn 'nvidia-smi query failed'
fi

section 'Hyprland monitors'
if command -v hyprctl >/dev/null 2>&1 && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
  if monitors_json="$(hyprctl -j monitors 2>/dev/null)"; then
    printf '%s\n' "$monitors_json"
    if command -v python3 >/dev/null 2>&1; then
      monitor_count="$(python3 -c 'import json,sys; data=json.load(sys.stdin); print(len(data) if isinstance(data,list) else 0)' <<<"$monitors_json" 2>/dev/null || printf '0')"
    fi
    if ((monitor_count > 0)); then
      ok "Hyprland reported $monitor_count monitor(s)"
    else
      fail 'Hyprland monitor list was empty or unreadable'
    fi
  else
    fail 'hyprctl -j monitors failed'
  fi
else
  fail 'Hyprland monitor query unavailable'
fi

section 'Active window / fullscreen evidence'
if command -v hyprctl >/dev/null 2>&1 && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
  hyprctl -j activewindow 2>/dev/null || warn 'active-window JSON unavailable'
fi

if ((run_phase4)); then
  section 'Phase 4 live validator'
  if validator="$(find_phase4_validator)"; then
    if ((full)); then
      if bash "$validator" --full; then
        phase4_status='pass-full'
        ok 'Phase 4 full live validator passed'
      else
        phase4_status='failed-full'
        fail 'Phase 4 full live validator failed'
      fi
    else
      if bash "$validator"; then
        phase4_status='pass-probe'
        ok 'Phase 4 safe live probe passed'
      else
        phase4_status='failed-probe'
        fail 'Phase 4 safe live probe failed'
      fi
    fi
  else
    phase4_status='missing'
    fail 'phase4-live-check.sh could not be found'
  fi
fi

if ((full)); then
  section 'Release gates that require human observation'
  ask_gate fresh-install 'Is this validation running on a fresh/clean Arch + Hyprland installation or an intentionally tested clean reinstall?'
  ask_gate graphics-session 'Did the desktop complete this run without visible GPU/render corruption, repeated shell crashes or unacceptable GPU behavior?'

  if ((monitor_count >= 2)); then
    ask_gate multi-monitor 'With all detected monitors connected, did Raohane placement, focus and input behavior work correctly?'
  else
    warn 'multi-monitor: fewer than two monitors detected; multi-monitor release gate remains unvalidated'
  fi

  ask_gate fullscreen-game 'Did fullscreen/game behavior and the Raohane media/overlay path work correctly in a real fullscreen application?'
fi

section 'Result'
printf 'phase4:   %s\n' "$phase4_status"
printf 'failures: %d\n' "$failures"
printf 'partial:  %d\n' "$partial"
printf 'report:   %s\n' "$report"

if ((failures > 0)); then
  echo 'RELEASE VALIDATION: FAIL'
  exit 1
fi
if ((partial > 0)); then
  echo 'RELEASE VALIDATION: PARTIAL — no hard failure, but one or more live gates remain unvalidated'
  exit 3
fi

echo 'RELEASE VALIDATION: PASS for the gates exercised in this run'
