#!/usr/bin/env bash
set -euo pipefail

notify() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "$@" >/dev/null 2>&1 || true
  fi
}

for command in slurp grim wl-copy xdg-open; do
  if ! command -v "$command" >/dev/null 2>&1; then
    notify 'Raohane Image Search' "Missing command: $command" -a 'Raohane Capture'
    exit 0
  fi
done

tmp="$(mktemp --suffix=.png /tmp/raohane-search-XXXXXX)"
trap 'rm -f "$tmp"' EXIT

geometry="$(slurp 2>/dev/null || true)"
if [[ -z "$geometry" ]]; then
  exit 0
fi

if ! grim -g "$geometry" "$tmp" >/dev/null 2>&1; then
  notify 'Raohane Image Search' 'Could not capture the selected region.' -a 'Raohane Capture'
  exit 0
fi

wl-copy --type image/png < "$tmp"
xdg-open 'https://lens.google.com/' >/dev/null 2>&1 || true
notify 'Image ready for search' 'The selected image is in the clipboard. Paste or upload it in Google Lens.' -a 'Raohane Capture' -i image-x-generic
