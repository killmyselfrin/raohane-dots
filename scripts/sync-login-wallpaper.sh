#!/usr/bin/env bash
set -euo pipefail

SOURCE="${1:-}"
CACHE_DIR="${RAOHANE_LOGIN_CACHE_DIR:-/var/cache/raohane-login}"
TARGET="$CACHE_DIR/wallpaper"

[[ -n "$SOURCE" ]] || exit 0
SOURCE="${SOURCE#file://}"
[[ -r "$SOURCE" && -f "$SOURCE" ]] || exit 0
[[ -d "$CACHE_DIR" && -w "$CACHE_DIR" ]] || exit 0

lower="${SOURCE,,}"
tmp="$CACHE_DIR/.wallpaper.$$"
trap 'rm -f -- "$tmp"' EXIT

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
trap - EXIT
