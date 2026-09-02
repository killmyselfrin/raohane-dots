#!/usr/bin/env bash
set -u

sound_dir="${1:-}"
kind="${2:-tap}"
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

[[ -n "$sound_dir" ]] || exit 2
case "$kind" in
  navigate) sound_file="$sound_dir/ui-navigate.wav" ;;
  confirm) sound_file="$sound_dir/ui-confirm.wav" ;;
  *) sound_file="$sound_dir/ui-tap.wav" ;;
esac

# ~/.cache may be cleared at any time and the initial Quickshell generator can
# race the audio session. Rebuild the tiny Raohane-owned WAV set on demand so a
# click can recover without restarting the shell.
if [[ ! -s "$sound_file" ]]; then
  if command -v python3 >/dev/null 2>&1 && [[ -f "$script_dir/generate-ui-sounds.py" ]]; then
    python3 "$script_dir/generate-ui-sounds.py" "$sound_dir" >/dev/null 2>&1 || true
  fi
fi

[[ -s "$sound_file" ]] || exit 3

# Prefer PipeWire, then PulseAudio/ALSA compatibility tools. pw-play is normally
# supplied by the Raohane PipeWire dependency set on Arch.
if command -v pw-play >/dev/null 2>&1; then
  pw-play "$sound_file" >/dev/null 2>&1 && exit 0
fi
if command -v paplay >/dev/null 2>&1; then
  paplay "$sound_file" >/dev/null 2>&1 && exit 0
fi
if command -v aplay >/dev/null 2>&1; then
  aplay -q "$sound_file" >/dev/null 2>&1 && exit 0
fi

exit 127
