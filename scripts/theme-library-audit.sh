#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'theme-library-audit: %s\n' "$*" >&2
  exit 1
}

for path in \
  modules/raohane/RaohaneThemeLibrary.qml \
  modules/raohane/RaohaneTheme.qml \
  modules/raohane/RaohaneThemeCatalog.qml \
  modules/raohane/RaohaneThemePresetManager.qml \
  modules/raohane/RaohaneThemeStudio.qml \
  modules/raohane/services/RaohaneThemePresets.qml \
  docs/THEMES.md \
  scripts/theme-catalog.py; do
  [[ -f "$path" ]] || fail "missing native theme-library path: $path"
done

python3 - scripts/theme-catalog.py <<'PY' || fail 'native catalog schema, IDs or Python importer are invalid'
import json
import pathlib
import subprocess
import sys
import tempfile

tool_path = pathlib.Path(sys.argv[1])
compile(tool_path.read_text(encoding="utf-8"), str(tool_path), "exec")

preset = {
    "id": "user-audit-theme",
    "name": "Audit Theme",
    "description": "Native theme audit fixture",
    "tone": "Custom · Dark",
    "dark": True,
    "source": "user",
    "background": "#080a14",
    "backgroundElevated": "#0d1020",
    "surface": "#dc111524",
    "surfaceRaised": "#ef171c2e",
    "surfaceDeep": "#f3070912",
    "surfaceSubtle": "#921c2237",
    "surfaceHover": "#e9232a44",
    "surfacePressed": "#ef2c3553",
    "border": "#3a59627f",
    "borderStrong": "#6a7b86aa",
    "borderFaint": "#2059627f",
    "highlight": "#40ffffff",
    "text": "#f2f1fa",
    "textMuted": "#aaa9bd",
    "textFaint": "#73758c",
    "accent": "#aa91ff",
    "accentSecondary": "#8b7bd8",
    "accentBlue": "#899dff",
    "success": "#7fd7aa",
    "warning": "#d7b26e",
    "critical": "#e5889a",
    "info": "#8eb8ff",
}
payload = json.dumps(preset, ensure_ascii=False)
with tempfile.TemporaryDirectory(prefix="raohane-theme-audit-") as temporary:
    directory = pathlib.Path(temporary)
    source = directory / "source.json"
    user_catalog = directory / "themes.json"
    exported = directory / "audit-theme.json"
    source.write_text(payload + "\n", encoding="utf-8")

    subprocess.run(
        [sys.executable, str(tool_path), "--catalog", str(user_catalog), "import", str(source)],
        check=True,
        stdout=subprocess.PIPE,
        text=True,
    )
    saved = json.loads(user_catalog.read_text(encoding="utf-8"))
    assert saved.get("schemaVersion") == 1
    assert [item["id"] for item in saved.get("presets", [])] == ["user-audit-theme"]

    subprocess.run(
        [sys.executable, str(tool_path), "--catalog", str(user_catalog), "upsert-json", payload],
        check=True,
        stdout=subprocess.PIPE,
        text=True,
    )
    subprocess.run(
        [sys.executable, str(tool_path), "--catalog", str(user_catalog), "export-json", payload, str(exported)],
        check=True,
        stdout=subprocess.PIPE,
        text=True,
    )
    exported_theme = json.loads(exported.read_text(encoding="utf-8"))
    assert exported_theme["id"] == "user-audit-theme"
PY

rg -q '^singleton RaohaneThemeLibrary .*RaohaneThemeLibrary.qml$' modules/raohane/qmldir \
  || fail 'native qmldir does not register RaohaneThemeLibrary'
rg -q '^RaohaneThemePresetManager .*RaohaneThemePresetManager.qml$' modules/raohane/qmldir \
  || fail 'native qmldir does not register RaohaneThemePresetManager'
rg -q '^RaohaneThemeStudio .*RaohaneThemeStudio.qml$' modules/raohane/qmldir \
  || fail 'native qmldir does not register RaohaneThemeStudio'
rg -q '^singleton RaohaneThemePresets .*RaohaneThemePresets.qml$' modules/raohane/services/qmldir \
  || fail 'native services qmldir does not register RaohaneThemePresets'
rg -q 'RaohaneThemeLibrary\.presets' modules/raohane/RaohaneTheme.qml \
  || fail 'RaohaneTheme does not merge the native user catalog'
rg -q 'RaohanePaths\.themeCatalogFile' modules/raohane/RaohaneThemeLibrary.qml \
  || fail 'user theme catalog is not Raohane-path owned'
rg -q 'themeQuery' modules/raohane/RaohaneThemeCatalog.qml \
  || fail 'theme catalog lost its search control'
rg -q 'source: "RaohaneThemeStudio.qml"' modules/raohane/RaohaneSettingsPageRegistry.qml \
  || fail 'Settings Themes route does not load the native Theme Studio'
rg -q 'RaohaneThemePresetManager' modules/raohane/RaohaneThemeStudio.qml \
  || fail 'Theme Studio does not compose user preset management'
rg -q 'RaohaneThemeCatalog' modules/raohane/RaohaneThemeStudio.qml \
  || fail 'Theme Studio lost the searchable theme catalog'
for contract in \
  'function importTheme' \
  'function savePreset' \
  'function exportPreset' \
  'function removePreset' \
  'upsert-json' \
  'export-json'; do
  rg -q "$contract" modules/raohane/services/RaohaneThemePresets.qml scripts/theme-catalog.py \
    || fail "native theme preset write path lost contract: $contract"
done
for contract in \
  'FileDialog' \
  'Save current' \
  'Export selected' \
  'removePreset' \
  'currentPreset'; do
  rg -q "$contract" modules/raohane/RaohaneThemePresetManager.qml \
    || fail "Theme Studio user-preset UI lost contract: $contract"
done
rg -q 'Theme presets intentionally contain colors only' docs/THEMES.md \
  || fail 'native theme format documentation lost palette/style separation'
rg -q 'theme \[list|import FILE|remove ID|export ID FILE' scripts/raohane \
  || fail 'CLI usage does not expose native theme management'

if rg -ni 'serpantinum' \
  README.md CHANGELOG.md docs/THEMES.md scripts/theme-catalog.py scripts/raohane \
  modules/raohane/RaohaneThemeLibrary.qml; then
  fail 'stable product theme path still contains retired catalog references'
fi

printf 'theme-library-audit: native loader, searchable UI, user preset write paths and CLI are valid\n'
