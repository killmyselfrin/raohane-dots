#!/usr/bin/env bash
set -u

sound_file="${1:-}"
[[ -n "$sound_file" && -f "$sound_file" ]] || exit 2

# Prefer the native PipeWire client. This bypasses QtMultimedia backend/plugin
# differences while still following the user's current default audio route.
if command -v pw-play >/dev/null 2>&1; then
  exec pw-play "$sound_file" >/dev/null 2>&1
fi

# Compatibility fallbacks for installations that expose PulseAudio/ALSA tools
# but not pw-play. Fail cleanly so QML can use SoundEffect as its final fallback.
if command -v paplay >/dev/null 2>&1; then
  exec paplay "$sound_file" >/dev/null 2>&1
fi
if command -v aplay >/dev/null 2>&1; then
  exec aplay -q "$sound_file" >/dev/null 2>&1
fi

exit 127
