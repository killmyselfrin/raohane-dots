#!/usr/bin/env bash
set -euo pipefail

SOURCE="${1:-}"
CACHE_DIR="${RAOHANE_LOGIN_CACHE_DIR:-/var/cache/raohane-login}"
TARGET="$CACHE_DIR/wallpaper"
STATE="$CACHE_DIR/wallpaper.source-state"

[[ -n "$SOURCE" ]] || exit 0
SOURCE="${SOURCE#file://}"
[[ -r "$SOURCE" && -f "$SOURCE" ]] || exit 0
[[ -d "$CACHE_DIR" && -w "$CACHE_DIR" ]] || exit 0

# This helper is invoked as a lightweight repair pass when the shell starts and
# whenever the configured wallpaper changes. Avoid copying the same image—or,
# more importantly, decoding the same video frame with ffmpeg—on every shell
# restart. Path + device/inode + size + mtime is enough to invalidate the cache
# without hashing or reading the full source file first.
stat_signature="$(stat -Lc '%d:%i:%s:%Y' -- "$SOURCE" 2>/dev/null || true)"
[[ -n "$stat_signature" ]] || exit 0
source_signature="${SOURCE}"$'\n'"${stat_signature}"

if [[ -f "$TARGET" && -r "$STATE" ]]; then
  previous_signature="$(<"$STATE")"
  if [[ "$previous_signature" == "$source_signature" ]]; then
    exit 0
  fi
fi

lower="${SOURCE,,}"
tmp="$CACHE_DIR/.wallpaper.$$"
state_tmp="$CACHE_DIR/.wallpaper-source-state.$$"
trap 'rm -f -- "$tmp" "$state_tmp"' EXIT

case "$lower" in
  *.jpg|*.jpeg|*.png|*.webp|*.avif|*.bmp|*.svg)
    cp -- "$SOURCE" "$tmp"
    ;;
  *.mp4|*.webm|*.mkv|*.mov|*.avi)
    if ! command -v ffmpeg >/dev/null 2>&1; then
      exit 0
    fi
    ffmpeg -hide_banner -loglevel error -y -ss 1 -i "$SOURCE" -frames:v 1 -f image2 -vcodec png "$tmp"
    ;;
  *)
    exit 0
    ;;
esac

chmod 0644 "$tmp"
mv -f -- "$tmp" "$TARGET"

printf '%s\n' "$source_signature" > "$state_tmp"
chmod 0644 "$state_tmp"
mv -f -- "$state_tmp" "$STATE"
trap - EXIT
