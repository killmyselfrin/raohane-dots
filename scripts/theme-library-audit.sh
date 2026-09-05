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
  modules/raohane/RaohaneThemePresetManager.qml \
  modules/raohane/RaohaneThemeStudio.qml \
  modules/raohane/services/RaohaneThemePresets.qml \
  docs/THEMES.md \
  scripts/theme-catalog.py; do
  [[ -f "$path" ]] || fail "missing native theme-library path: $path"
done

python3 - defaults/themes/serpantinum.json scripts/theme-catalog.py <<'PY' || fail 'catalog schema, IDs or Python importer are invalid'
import json
import pathlib
import subprocess
import sys
import tempfile

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

# Smoke-test the exact write paths used by Settings. Use a real bundled preset
# as the token source, but mark it as user-owned and operate in a temp catalog.
preset = dict(presets[0])
preset.update({"id": "user-audit-theme", "name": "Audit Theme", "source": "user"})
payload = json.dumps(preset, ensure_ascii=False)
with tempfile.TemporaryDirectory(prefix="raohane-theme-audit-") as temporary:
    directory = pathlib.Path(temporary)
    user_catalog = directory / "themes.json"
    exported = directory / "audit-theme.json"
    subprocess.run(
        [sys.executable, str(tool_path), "--catalog", str(user_catalog), "upsert-json", payload],
        check=True,
        stdout=subprocess.PIPE,
        text=True,
    )
    saved = json.loads(user_catalog.read_text(encoding="utf-8"))
    assert saved.get("schemaVersion") == 1
    assert [item["id"] for item in saved.get("presets", [])] == ["user-audit-theme"]
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
  || fail 'RaohaneTheme does not merge the native catalog'
rg -q 'RaohanePaths\.themeCatalogFile' modules/raohane/RaohaneThemeLibrary.qml \
  || fail 'user theme catalog is not Raohane-path owned'
rg -q 'themeQuery' modules/raohane/RaohaneThemeCatalog.qml \
  || fail 'large theme catalog lost its search control'
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
rg -q 'theme \[list\|import FILE\|import-serpantinum PATH' scripts/raohane \
  || fail 'CLI usage does not expose native theme management'

printf 'theme-library-audit: native loader, searchable UI, user preset write paths, CLI and converted Serpantinum catalog are valid\n'
