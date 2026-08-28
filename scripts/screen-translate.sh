#!/usr/bin/env bash
set -euo pipefail

target="${1:-ru}"
case "$target" in
  ru|en) ;;
  *) target="ru" ;;
esac

emit_error() {
  local message="$1"
  local source_file="${2:-}"
  python3 - "$message" "$source_file" "$target" <<'PY'
import json
import pathlib
import sys

message, source_path, target = sys.argv[1:4]
source = ""
if source_path:
    try:
        source = pathlib.Path(source_path).read_text(encoding="utf-8").strip()
    except OSError:
        pass
print(json.dumps({"ok": False, "error": message, "source": source, "translation": "", "target": target}, ensure_ascii=False))
PY
}

for command in slurp grim tesseract trans python3; do
  if ! command -v "$command" >/dev/null 2>&1; then
    emit_error "Missing command: $command"
    exit 0
  fi
done

tmpdir="$(mktemp -d -t raohane-translate.XXXXXX)"
trap 'rm -rf "$tmpdir"' EXIT

region="$(slurp 2>/dev/null || true)"
if [[ -z "$region" ]]; then
  emit_error "Selection cancelled"
  exit 0
fi

image="$tmpdir/capture.png"
ocr_base="$tmpdir/ocr"
ocr_file="$ocr_base.txt"
translation_file="$tmpdir/translation.txt"

if ! grim -g "$region" "$image" >/dev/null 2>&1; then
  emit_error "Could not capture the selected region"
  exit 0
fi

if ! tesseract "$image" "$ocr_base" -l eng+rus --psm 6 >/dev/null 2>&1; then
  emit_error "OCR failed. Check the Tesseract language data."
  exit 0
fi

if [[ ! -s "$ocr_file" ]] || ! grep -q '[[:alnum:][:alpha:]]' "$ocr_file"; then
  emit_error "No readable text was found in the selected region" "$ocr_file"
  exit 0
fi

if ! trans -no-ansi -brief ":$target" "$(cat "$ocr_file")" >"$translation_file" 2>/dev/null; then
  emit_error "Translation failed. Check the network connection or translate-shell." "$ocr_file"
  exit 0
fi

python3 - "$ocr_file" "$translation_file" "$target" <<'PY'
import json
import pathlib
import sys

source_path, translation_path, target = sys.argv[1:4]
source = pathlib.Path(source_path).read_text(encoding="utf-8").strip()
translation = pathlib.Path(translation_path).read_text(encoding="utf-8").strip()
print(json.dumps({"ok": bool(translation), "error": "" if translation else "Translator returned an empty result", "source": source, "translation": translation, "target": target}, ensure_ascii=False))
PY
