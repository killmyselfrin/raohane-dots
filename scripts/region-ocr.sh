#!/usr/bin/env bash
set -euo pipefail

notify() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "$@" >/dev/null 2>&1 || true
  fi
}

for command in slurp grim tesseract wl-copy; do
  if ! command -v "$command" >/dev/null 2>&1; then
    notify 'Raohane OCR' "Missing command: $command" -a 'Raohane Capture'
    exit 0
  fi
done

tmpdir="$(mktemp -d -t raohane-ocr.XXXXXX)"
trap 'rm -rf "$tmpdir"' EXIT

geometry="$(slurp 2>/dev/null || true)"
if [[ -z "$geometry" ]]; then
  exit 0
fi

image="$tmpdir/capture.png"
ocr_base="$tmpdir/ocr"
ocr_file="$ocr_base.txt"

if ! grim -g "$geometry" "$image" >/dev/null 2>&1; then
  notify 'Raohane OCR' 'Could not capture the selected region.' -a 'Raohane Capture'
  exit 0
fi

if ! tesseract "$image" "$ocr_base" -l eng+rus --psm 6 >/dev/null 2>&1; then
  notify 'Raohane OCR' 'OCR failed. Check the Tesseract language data.' -a 'Raohane Capture'
  exit 0
fi

text="$(cat "$ocr_file" 2>/dev/null || true)"
if [[ -z "${text//[[:space:]]/}" ]]; then
  notify 'Raohane OCR' 'No readable text was found in the selected region.' -a 'Raohane Capture'
  exit 0
fi

printf '%s' "$text" | wl-copy --type text/plain
notify 'Text copied' 'Recognized text is now in the clipboard.' -a 'Raohane Capture' -i edit-copy
