#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-}"

if [[ -z "$TARGET" ]]; then
  echo 'Usage: validate-runtime-payload.sh <installed-raohane-runtime>' >&2
  exit 2
fi

TARGET="$(realpath -m -- "$TARGET")"
case "$TARGET" in
  /|/home|/usr|/etc|/var|/opt|/tmp)
    echo "Refusing unsafe runtime target: $TARGET" >&2
    exit 2
    ;;
esac

fail() {
  printf '[Raohane] Runtime payload invalid: %s\n' "$*" >&2
  exit 1
}

required=(
  shell.qml
  qmldir
  VERSION
  assets
  translations
  defaults/native.json
  install/arch/required.txt
  install/arch/features.txt
  modules/raohane
  modules/raohane/qmldir
  panelFamilies/RaohaneFamily.qml
  scripts/autostart.sh
  scripts/install-deps.sh
  scripts/prune-runtime.sh
  scripts/phase4-live-check.sh
  scripts/region-ocr.sh
  scripts/region-search.sh
  scripts/screen-translate.sh
  scripts/thumbnails/thumbgen.sh
  scripts/thumbnails/thumbgen.py
  scripts/thumbnails/generate-thumbnails-magick.sh
  scripts/videos/record.sh
)

for path in "${required[@]}"; do
  [[ -e "$TARGET/$path" ]] || fail "missing $path"
done

[[ "$(tr -d '\r\n' < "$TARGET/qmldir")" == 'module qs' ]] \
  || fail 'root qmldir must contain only module qs'
[[ -s "$TARGET/VERSION" ]] || fail 'VERSION is empty'

python3 - "$TARGET/defaults/native.json" <<'PY' || fail 'defaults/native.json is not valid schema v10'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
try:
    data = json.loads(path.read_text(encoding="utf-8"))
except (OSError, json.JSONDecodeError):
    raise SystemExit(1)
raise SystemExit(0 if data.get("schemaVersion") == 10 else 1)
PY

source_only=(
  .git
  .github
  docs
  patches
  AGENTS.md
  ARCHITECTURE.md
  CONTRIBUTING.md
  INDEPENDENCE-PLAN.md
  README.md
  install-raohane.sh
  modules/common
  modules/ii
  services
  GlobalStates.qml
  ReloadPopup.qml
  settings.qml
  welcome.qml
)
for path in "${source_only[@]}"; do
  [[ ! -e "$TARGET/$path" ]] || fail "source-only path present: $path"
done

root_qml_count="$(find "$TARGET" -mindepth 1 -maxdepth 1 -type f -name '*.qml' -printf '.' | wc -c)"
[[ "$root_qml_count" -eq 1 ]] || fail "expected one root QML file, found $root_qml_count"

family_qml_count="$(find "$TARGET/panelFamilies" -mindepth 1 -maxdepth 1 -type f -name '*.qml' -printf '.' | wc -c)"
[[ "$family_qml_count" -eq 1 ]] || fail "expected one panel family, found $family_qml_count"

module_dir_count="$(find "$TARGET/modules" -mindepth 1 -maxdepth 1 -type d -printf '.' | wc -c)"
[[ "$module_dir_count" -eq 1 && -d "$TARGET/modules/raohane" ]] \
  || fail 'modules/ must contain only the native raohane module'

if find "$TARGET/scripts" -mindepth 1 -maxdepth 1 -type f -name '*-audit.sh' -print -quit | grep -q .; then
  fail 'source-only audit script present'
fi

if find "$TARGET" -path "$TARGET/.git" -prune -o -type f \
  \( -iname '*.ttf' -o -iname '*.otf' -o -iname '*.woff' -o -iname '*.woff2' -o -iname '*.eot' \) \
  -print -quit | grep -q .; then
  fail 'vendored font binary present'
fi

printf '[Raohane] Runtime payload valid: %s\n' "$TARGET"
