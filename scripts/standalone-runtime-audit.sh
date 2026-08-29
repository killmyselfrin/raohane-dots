#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'standalone-runtime-audit: %s\n' "$*" >&2
  exit 1
}

required=(
  shell.qml
  qmldir
  install-raohane.sh
  panelFamilies/RaohaneFamily.qml
  modules/raohane
  modules/raohane/config
  modules/raohane/services
  scripts/raohane
  scripts/prune-runtime.sh
  scripts/phase4-live-check.sh
)
for path in "${required[@]}"; do
  [[ -e "$path" ]] || fail "missing native runtime path: $path"
done

retired_source=(
  modules/common
  modules/ii
  services
  GlobalStates.qml
  ReloadPopup.qml
  killDialog.qml
  settings.qml
  welcome.qml
  panelFamilies/IllogicalImpulseFamily.qml
  panelFamilies/PanelLoader.qml
  scripts/sync-end4-foundation.sh
  scripts/install-foundation-deps.sh
  scripts/ai
  scripts/cava
  scripts/colors
  scripts/hyprland
  scripts/images
  scripts/keyring
  scripts/kvantum
  scripts/lyrics
  scripts/musicRecognition
  scripts/theming
  scripts/presets.sh
  defaults/config.json
  upstream/end4-pC.lock
  upstream/illogical-impulse.lock
)
for path in "${retired_source[@]}"; do
  [[ ! -e "$path" ]] || fail "retired inherited source path returned: $path"
done

retired_script_dirs=(ai cava colors hyprland images keyring kvantum lyrics musicRecognition theming)
for name in "${retired_script_dirs[@]}"; do
  if rg -n "scripts/${name}(/|\\\")" shell.qml panelFamilies/RaohaneFamily.qml modules/raohane; then
    fail "native runtime references retired script tree: scripts/${name}"
  fi
done
if rg -n 'scripts/presets\.sh|illogical-impulse/config\.json' shell.qml panelFamilies/RaohaneFamily.qml modules/raohane; then
  fail 'native runtime references retired preset/config tooling'
fi

mapfile -t native_qml < <(find modules/raohane -type f -name '*.qml' -print | sort)
scan_files=(shell.qml panelFamilies/RaohaneFamily.qml "${native_qml[@]}")

if rg -n \
  '^import qs\.modules\.common(\.|$)|^import qs\.modules\.ii(\.|$)|^import qs\.services(\.|$)|\bGlobalStates\.|\bConfig\.|\bAppearance\.|\bDirectories\.|\bMaterialThemeLoader\b|\bIllogicalImpulseFamily\b|\bRaohaneLegacyBridge\b' \
  "${scan_files[@]}"; then
  fail 'native runtime still contains an inherited namespace/reference'
fi

if rg -n \
  'component:[[:space:]]*(Overlay|RegionSelector|ScreenTranslator|SidebarLeft|VerticalBar|DropShelfPanel|OnScreenKeyboard|ScreenCorners|ScreenFrame|Polkit|Lock)[[:space:]]*\{' \
  shell.qml panelFamilies/RaohaneFamily.qml; then
  fail 'family composition can still instantiate an inherited presentation type'
fi

rg -q '"scripts/prune-runtime\.sh"' install-raohane.sh \
  || fail 'installer does not require the runtime pruner'
rg -q 'bash "\$ROOT/scripts/prune-runtime\.sh" "\$RUNTIME"' install-raohane.sh \
  || fail 'installer does not prune/normalize the copied runtime before startup'
rg -q '^prune_runtime_if_needed\(\)' scripts/raohane \
  || fail 'Raohane CLI does not define installed-runtime pruning'
rg -q '^[[:space:]]*prune_runtime_if_needed$' scripts/raohane \
  || fail 'raohane run does not maintain runtime before qs starts'
rg -q 'bash "\$pruner" "\$RUNTIME"' scripts/raohane \
  || fail 'Raohane CLI does not route pruning through the dedicated script'

rg -q 'doctor \[[^]]*runtime[^]]*\]' scripts/raohane \
  || fail 'CLI usage does not expose doctor runtime'
rg -q '^print_runtime_integrity\(\)' scripts/raohane \
  || fail 'CLI lost installed-runtime integrity diagnostics'
rg -q '^[[:space:]]*runtime\)' scripts/raohane \
  || fail 'doctor runtime route is missing'
rg -q 'native\.json.*schema v10|schemaVersion.*10' scripts/raohane \
  || fail 'doctor runtime no longer validates native config schema v10'

# Exercise both runtime pruning and the native schema upgrade against disposable
# state. This reproduces real upgrades from an existing v9 native.json without
# touching the CI account's own config directory.
tmp_runtime="$(mktemp -d /tmp/raohane-standalone-audit.XXXXXX)"
tmp_config="$tmp_runtime/config-home"
cleanup() { rm -rf -- "$tmp_runtime"; }
trap cleanup EXIT

mkdir -p \
  "$tmp_runtime/modules" \
  "$tmp_runtime/panelFamilies" \
  "$tmp_runtime/defaults" \
  "$tmp_runtime/services" \
  "$tmp_runtime/scripts" \
  "$tmp_config/raohane"
cp shell.qml qmldir "$tmp_runtime/"
cp -a modules/raohane "$tmp_runtime/modules/"
cp panelFamilies/RaohaneFamily.qml "$tmp_runtime/panelFamilies/"
cp defaults/native.json "$tmp_runtime/defaults/native.json"
cp scripts/install-deps.sh scripts/prune-runtime.sh scripts/autostart.sh scripts/phase4-live-check.sh "$tmp_runtime/scripts/"
mkdir -p "$tmp_runtime/modules/common" "$tmp_runtime/modules/ii"
for name in "${retired_script_dirs[@]}"; do
  mkdir -p "$tmp_runtime/scripts/$name"
  touch "$tmp_runtime/scripts/$name/legacy-helper"
done
cat > "$tmp_config/raohane/native.json" <<'JSON'
{
  "schemaVersion": 9,
  "wallpaper": {
    "path": "/tmp/keep-wallpaper.png",
    "preview": false
  },
  "dock": {
    "iconSize": 51
  },
  "customFutureSection": {
    "keepMe": true
  }
}
JSON

touch \
  "$tmp_runtime/GlobalStates.qml" \
  "$tmp_runtime/ReloadPopup.qml" \
  "$tmp_runtime/AnotherInheritedRoot.qml" \
  "$tmp_runtime/defaults/config.json" \
  "$tmp_runtime/panelFamilies/IllogicalImpulseFamily.qml" \
  "$tmp_runtime/panelFamilies/ReferenceFamily.qml" \
  "$tmp_runtime/services/Idle.qml" \
  "$tmp_runtime/scripts/presets.sh" \
  "$tmp_runtime/scripts/migrate-legacy-config.py" \
  "$tmp_runtime/scripts/raohane" \
  "$tmp_runtime/scripts/raohane-audit.sh" \
  "$tmp_runtime/scripts/standalone-runtime-audit.sh" \
  "$tmp_runtime/scripts/core-framework-audit.sh" \
  "$tmp_runtime/scripts/core-framework-phase3-audit.sh" \
  "$tmp_runtime/scripts/phase4-visible-runtime-audit.sh" \
  "$tmp_runtime/scripts/fake-boundary-audit.sh"

XDG_CONFIG_HOME="$tmp_config" bash scripts/prune-runtime.sh "$tmp_runtime" >/dev/null

python3 - "$tmp_config/raohane/native.json" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
data = json.loads(path.read_text(encoding="utf-8"))
assert data["schemaVersion"] == 10
assert data["wallpaper"]["path"] == "/tmp/keep-wallpaper.png"
assert data["wallpaper"]["preview"] is False
assert data["dock"]["iconSize"] == 51
assert data["osk"]["pinned"] is False
assert data["osk"]["layout"] == "English (US)"
assert data["customFutureSection"]["keepMe"] is True
PY

for retired in \
  "$tmp_runtime/modules/common" \
  "$tmp_runtime/modules/ii" \
  "$tmp_runtime/services" \
  "$tmp_runtime/GlobalStates.qml" \
  "$tmp_runtime/ReloadPopup.qml" \
  "$tmp_runtime/AnotherInheritedRoot.qml" \
  "$tmp_runtime/defaults/config.json" \
  "$tmp_runtime/panelFamilies/IllogicalImpulseFamily.qml" \
  "$tmp_runtime/panelFamilies/ReferenceFamily.qml" \
  "$tmp_runtime/scripts/presets.sh" \
  "$tmp_runtime/scripts/migrate-legacy-config.py" \
  "$tmp_runtime/scripts/raohane" \
  "$tmp_runtime/scripts/raohane-audit.sh" \
  "$tmp_runtime/scripts/standalone-runtime-audit.sh" \
  "$tmp_runtime/scripts/core-framework-audit.sh" \
  "$tmp_runtime/scripts/core-framework-phase3-audit.sh" \
  "$tmp_runtime/scripts/phase4-visible-runtime-audit.sh" \
  "$tmp_runtime/scripts/fake-boundary-audit.sh"; do
  [[ ! -e "$retired" ]] || fail "pruner left retired/source-only installed path: $retired"
done
for name in "${retired_script_dirs[@]}"; do
  [[ ! -e "$tmp_runtime/scripts/$name" ]] || fail "pruner left retired installed script tree: scripts/$name"
done
if find "$tmp_runtime/scripts" -mindepth 1 -maxdepth 1 -type f -name '*-audit.sh' -print -quit | grep -q .; then
  fail 'pruner left a source-only audit in the installed runtime'
fi

for preserved in \
  "$tmp_runtime/modules/raohane" \
  "$tmp_runtime/shell.qml" \
  "$tmp_runtime/panelFamilies/RaohaneFamily.qml" \
  "$tmp_runtime/defaults/native.json" \
  "$tmp_runtime/scripts/install-deps.sh" \
  "$tmp_runtime/scripts/prune-runtime.sh" \
  "$tmp_runtime/scripts/autostart.sh" \
  "$tmp_runtime/scripts/phase4-live-check.sh"; do
  [[ -e "$preserved" ]] || fail "pruner removed required native path: $preserved"
done

[[ "$(tr -d '\r\n' < "$tmp_runtime/qmldir")" == 'module qs' ]] || fail 'pruner damaged root qmldir'
root_qml_count="$(find "$tmp_runtime" -mindepth 1 -maxdepth 1 -type f -name '*.qml' -printf '.' | wc -c)"
[[ "$root_qml_count" -eq 1 ]] || fail "pruned runtime still has $root_qml_count root QML files"

printf 'standalone-runtime-audit: source/runtime are native-only, live validator is retained and v9 settings upgrade safely to schema v10\n'
