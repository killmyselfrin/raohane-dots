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
  modules/raohane/RaohaneDesktopWidgets.qml
  modules/raohane/RaohaneDesktopEditGrid.qml
  modules/raohane/RaohaneTaskManager.qml
  modules/raohane/RaohaneOverlay.qml
  modules/raohane/RaohaneSettingsGraphics.qml
  modules/raohane/RaohaneSettingsScenes.qml
  modules/raohane/services/RaohaneProcesses.qml
  modules/raohane/services/RaohaneLyrics.qml
  modules/raohane/services/RaohaneCoverAccent.qml
  modules/raohane/services/RaohaneUpdater.qml
  modules/raohane/services/RaohaneGraphics.qml
  modules/raohane/services/RaohaneScenes.qml
  modules/raohane/services/RaohaneRecorder.qml
  panelFamilies/RaohaneFamily.qml
  scripts/autostart.sh
  scripts/install-deps.sh
  scripts/prune-runtime.sh
  scripts/validate-runtime-payload.sh
  scripts/runtime-smoke-check.sh
  scripts/phase4-live-check.sh
  scripts/product-live-check.sh
  scripts/release-live-check.sh
  scripts/screen-share.sh
  scripts/process-snapshot.py
  scripts/lyrics-resolve.py
  scripts/cover-accent.py
  scripts/update-raohane.py
  scripts/theme-catalog.py
  scripts/graphics-driver-check.py
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
grep -Fxq 'RaohaneDesktopEditGrid 1.0 RaohaneDesktopEditGrid.qml' "$TARGET/modules/raohane/qmldir" \
  || fail 'desktop edit grid type is missing from installed qmldir'

# The edit grid is optional at boot, but must be shipped and registered so
# users don't enter a non-functional editor after an incomplete upgrade.
grep -Fxq 'RaohaneDesktopEditGrid 1.0 RaohaneDesktopEditGrid.qml' \
  "$TARGET/modules/raohane/qmldir" \
  || fail 'desktop edit grid is absent from qmldir'
grep -Fq 'Qt.resolvedUrl("RaohaneDesktopEditGrid.qml")' \
  "$TARGET/modules/raohane/RaohaneDesktopWidgets.qml" \
  || fail 'desktop edit grid is not loaded lazily by the renderer'


# Compare the staged defaults with the staged QML config schema instead
# of hard-coding a version here. This validator runs for every OTA update.
python3 - "$TARGET/defaults/native.json" "$TARGET/modules/raohane/config/RaohaneConfig.qml" <<'PY' || fail 'defaults/native.json schemaVersion does not match the Raohane runtime config'
import json
import pathlib
import re
import sys

try:
    defaults = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
    qml = pathlib.Path(sys.argv[2]).read_text(encoding="utf-8")
except (OSError, json.JSONDecodeError):
    raise SystemExit(1)

match = re.search(r"^\s*readonly property int schemaVersion:\s*(\d+)\s*$", qml, re.MULTILINE)
valid = (
    isinstance(defaults, dict)
    and match is not None
    and type(defaults.get("schemaVersion")) is int
    and defaults["schemaVersion"] == int(match.group(1))
)
raise SystemExit(0 if valid else 1)
PY

python3 - "$TARGET/scripts/process-snapshot.py" "$TARGET/scripts/lyrics-resolve.py" "$TARGET/scripts/cover-accent.py" "$TARGET/scripts/update-raohane.py" "$TARGET/scripts/theme-catalog.py" "$TARGET/scripts/graphics-driver-check.py" <<'PY' || fail 'native Python runtime helper is invalid'
import pathlib
import sys
for raw in sys.argv[1:]:
    path = pathlib.Path(raw)
    compile(path.read_text(encoding="utf-8"), str(path), "exec")
PY

bash -n "$TARGET/scripts/runtime-smoke-check.sh" || fail 'runtime-smoke-check.sh has invalid shell syntax'
bash -n "$TARGET/scripts/phase4-live-check.sh" || fail 'phase4-live-check.sh has invalid shell syntax'
bash -n "$TARGET/scripts/product-live-check.sh" || fail 'product-live-check.sh has invalid shell syntax'
bash -n "$TARGET/scripts/release-live-check.sh" || fail 'release-live-check.sh has invalid shell syntax'
bash -n "$TARGET/scripts/screen-share.sh" || fail 'screen-share.sh has invalid shell syntax'

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
