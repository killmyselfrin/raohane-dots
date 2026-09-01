#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'theme-library-audit: %s\n' "$*" >&2
  exit 1
}

for path in \
  defaults/themes/serpantinum.json \
  modules/raohane/RaohaneThemeLibrary.qml \
  modules/raohane/RaohaneTheme.qml \
  modules/raohane/RaohaneThemeCatalog.qml \
  scripts/theme-catalog.py; do
  [[ -f "$path" ]] || fail "missing native theme-library path: $path"
done

python3 - defaults/themes/serpantinum.json scripts/theme-catalog.py <<'PY' || fail 'catalog schema, IDs or Python importer are invalid'
import json
import pathlib
import sys

catalog_path = pathlib.Path(sys.argv[1])
tool_path = pathlib.Path(sys.argv[2])
compile(tool_path.read_text(encoding="utf-8"), str(tool_path), "exec")
catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
presets = catalog.get("presets", [])
assert catalog.get("schemaVersion") == 1
assert len(presets) >= 90
assert len({item["id"] for item in presets}) == len(presets)
assert all(item.get("source") == "ilyamiro/serpantinum" for item in presets)
required = {
    "background", "backgroundElevated", "surface", "surfaceRaised", "surfaceDeep",
    "surfaceSubtle", "surfaceHover", "surfacePressed", "border", "borderStrong",
    "borderFaint", "highlight", "text", "textMuted", "textFaint", "accent",
    "accentSecondary", "accentBlue", "success", "warning", "critical", "info",
}
assert all(required <= item.keys() for item in presets)
PY

rg -q '^singleton RaohaneThemeLibrary .*RaohaneThemeLibrary.qml$' modules/raohane/qmldir \
  || fail 'native qmldir does not register RaohaneThemeLibrary'
rg -q 'RaohaneThemeLibrary\.presets' modules/raohane/RaohaneTheme.qml \
  || fail 'RaohaneTheme does not merge the native catalog'
rg -q 'RaohanePaths\.themeCatalogFile' modules/raohane/RaohaneThemeLibrary.qml \
  || fail 'user theme catalog is not Raohane-path owned'
rg -q 'themeQuery' modules/raohane/RaohaneThemeCatalog.qml \
  || fail 'large theme catalog lost its search control'
rg -q 'theme \[list\|import FILE\|import-serpantinum PATH' scripts/raohane \
  || fail 'CLI usage does not expose native theme management'

printf 'theme-library-audit: native loader, searchable UI, CLI and converted Serpantinum catalog are valid\n'
