#!/usr/bin/env bash
set -euo pipefail

notify() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "$1" "${2:-}" -a 'Raohane Recorder' >/dev/null 2>&1 || true
  fi
}

recording_dir="${RAOHANE_RECORDING_DIR:-}"
if [[ -z "$recording_dir" ]]; then
  if command -v xdg-user-dir >/dev/null 2>&1; then
    recording_dir="$(xdg-user-dir VIDEOS 2>/dev/null || true)"
  fi
  recording_dir="${recording_dir:-$HOME/Videos}"
fi

# Keep paths deterministic and user-local. A relative override is interpreted
# from the user's home rather than from whichever process launched Quickshell.
if [[ "$recording_dir" != /* ]]; then
  recording_dir="$HOME/$recording_dir"
fi

focused_monitor() {
  hyprctl monitors -j | python3 -c '
import json, sys
for monitor in json.load(sys.stdin):
    if monitor.get("focused"):
        print(monitor.get("name", ""))
        break
'
}

default_monitor_source() {
  command -v pactl >/dev/null 2>&1 || return 1
  local sink
  sink="$(pactl get-default-sink 2>/dev/null || true)"
  [[ -n "$sink" ]] || return 1
  printf '%s.monitor\n' "$sink"
}

if pgrep -x wf-recorder >/dev/null 2>&1; then
  notify 'Recording stopped' 'Finishing the current capture.'
  pkill -INT -x wf-recorder || true
  exit 0
fi

command -v wf-recorder >/dev/null 2>&1 || {
  notify 'Recording unavailable' 'wf-recorder is not installed.'
  echo '[Raohane] wf-recorder is required for screen recording.' >&2
  exit 1
}
command -v hyprctl >/dev/null 2>&1 || {
  echo '[Raohane] hyprctl is required for screen recording.' >&2
  exit 1
}

sound=0
fullscreen=0
region=""

while (($#)); do
  case "$1" in
    --sound)
      sound=1
      ;;
    --fullscreen)
      fullscreen=1
      ;;
    --region)
      shift
      [[ $# -gt 0 ]] || { echo '[Raohane] --region requires geometry.' >&2; exit 2; }
      region="$1"
      ;;
    -h|--help)
      cat <<'EOF'
Raohane screen recorder

Usage:
  record.sh [--fullscreen] [--sound] [--region 'x,y WxH']

Environment:
  RAOHANE_RECORDING_DIR  Override the output directory. Relative values are
                         resolved below $HOME.

Run the command again while wf-recorder is active to stop recording cleanly.
EOF
      exit 0
      ;;
    *)
      echo "[Raohane] Unknown recorder option: $1" >&2
      exit 2
      ;;
  esac
  shift
done

mkdir -p "$recording_dir"
stamp="$(date '+%Y-%m-%d_%H.%M.%S')"
output="$recording_dir/recording_${stamp}.mp4"

args=(--pixel-format yuv420p --file "$output")

if ((fullscreen)); then
  monitor="$(focused_monitor)"
  [[ -n "$monitor" ]] || {
    notify 'Recording cancelled' 'Could not resolve the focused Hyprland monitor.'
    exit 1
  }
  args+=(--output "$monitor")
else
  if [[ -z "$region" ]]; then
    command -v slurp >/dev/null 2>&1 || {
      notify 'Recording unavailable' 'slurp is required for region selection.'
      exit 1
    }
    region="$(slurp)" || {
      notify 'Recording cancelled' 'Region selection was cancelled.'
      exit 0
    }
  fi
  args+=(--geometry "$region")
fi

if ((sound)); then
  if source_name="$(default_monitor_source)"; then
    args+=(--audio="$source_name")
  else
    args+=(--audio)
  fi
fi

notify 'Recording started' "$(basename "$output")"
echo "[Raohane] Recording to: $output"
exec wf-recorder "${args[@]}"
