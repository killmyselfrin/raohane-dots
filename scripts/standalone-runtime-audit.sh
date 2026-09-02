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
  VERSION
  assets
  translations
  install-raohane.sh
  install/arch/required.txt
  install/arch/features.txt
  panelFamilies/RaohaneFamily.qml
  modules/raohane
  modules/raohane/config
  modules/raohane/services
  modules/raohane/RaohaneTaskManager.qml
  modules/raohane/RaohaneOverlay.qml
  modules/raohane/services/RaohaneProcesses.qml
  modules/raohane/services/RaohaneLyrics.qml
  scripts/raohane
  scripts/prune-runtime.sh
  scripts/lyrics-resolve.py
  scripts/product-live-check.sh
  scripts/phase4-live-check.sh
  scripts/release-live-check.sh
  scripts/validate-runtime-payload.sh
  scripts/runtime-payload-audit.sh
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

# Fresh installation must stage an explicit standalone payload. Never copy the
# source checkout wholesale into ~/.config/quickshell/raohane and prune it later.
if rg -n 'cp[[:space:]]+-a[[:space:]]+"\$ROOT"/\.[[:space:]]+"\$RUNTIME"/?' install-raohane.sh; then
  fail 'installer regressed to copying the whole source checkout into runtime'
fi

staged_contracts=(
  'cp -a "\$ROOT/shell\.qml" "\$ROOT/qmldir" "\$ROOT/VERSION" "\$RUNTIME/"'
  'cp -a "\$ROOT/modules/raohane" "\$RUNTIME/modules/"'
  'cp -a "\$ROOT/panelFamilies/RaohaneFamily\.qml" "\$RUNTIME/panelFamilies/"'
  'cp -a "\$ROOT/defaults/native\.json" "\$RUNTIME/defaults/"'
  'cp -a "\$ROOT/install/arch" "\$RUNTIME/install/"'
  'cp -a "\$ROOT/assets" "\$RUNTIME/"'
  'cp -a "\$ROOT/translations" "\$RUNTIME/"'
  'cp -a "\$ROOT/scripts" "\$RUNTIME/"'
)
for contract in "${staged_contracts[@]}"; do
  rg -q "$contract" install-raohane.sh || fail "installer lost explicit runtime staging contract: $contract"
done

for source_only in docs patches .github AGENTS.md ARCHITECTURE.md INDEPENDENCE-PLAN.md; do
  if rg -n "cp[[:space:]]+-a.*\\\$ROOT/${source_only}([[:space:]]|\\\")" install-raohane.sh; then
    fail "installer stages source-only path into runtime: $source_only"
  fi
done

rg -q '"scripts/prune-runtime\.sh"' install-raohane.sh || fail 'installer does not require the runtime pruner'
rg -q 'bash "\$ROOT/scripts/prune-runtime\.sh" "\$RUNTIME"' install-raohane.sh || fail 'installer does not prune/normalize the staged runtime before startup'
rg -q 'bash "\$ROOT/scripts/validate-runtime-payload\.sh" "\$RUNTIME"' install-raohane.sh || fail 'installer does not validate the final staged runtime before startup'
rg -q '^prune_runtime_if_needed\(\)' scripts/raohane || fail 'Raohane CLI does not define installed-runtime pruning'
rg -q '^[[:space:]]*prune_runtime_if_needed$' scripts/raohane || fail 'raohane run does not maintain runtime before qs starts'
rg -q 'bash "\$pruner" "\$RUNTIME"' scripts/raohane || fail 'Raohane CLI does not route pruning through the dedicated script'

rg -q 'doctor \[[^]]*runtime[^]]*\]' scripts/raohane || fail 'CLI usage does not expose doctor runtime'
rg -q '^print_runtime_integrity\(\)' scripts/raohane || fail 'CLI lost installed-runtime integrity diagnostics'
rg -q '^[[:space:]]*runtime\)' scripts/raohane || fail 'doctor runtime route is missing'
rg -q 'native\.json.*schema v12|schemaVersion.*12' scripts/raohane || fail 'doctor runtime no longer validates native config schema v12'
rg -q '^find_runtime_payload_validator\(\)' scripts/raohane || fail 'doctor runtime no longer resolves the strict runtime payload validator'
rg -q '\$RUNTIME/scripts/validate-runtime-payload\.sh' scripts/raohane || fail 'doctor runtime does not prefer the validator installed with the runtime'
rg -q 'bash "\$payload_validator" "\$RUNTIME"' scripts/raohane || fail 'doctor runtime does not execute strict payload validation against the installed runtime'

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
cp \
  scripts/install-deps.sh \
  scripts/prune-runtime.sh \
  scripts/autostart.sh \
  scripts/lyrics-resolve.py \
  scripts/product-live-check.sh \
  scripts/phase4-live-check.sh \
  scripts/release-live-check.sh \
  "$tmp_runtime/scripts/"
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
assert data["schemaVersion"] == 12
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
  "$tmp_runtime/modules/raohane/RaohaneTaskManager.qml" \
  "$tmp_runtime/modules/raohane/RaohaneOverlay.qml" \
  "$tmp_runtime/modules/raohane/services/RaohaneProcesses.qml" \
  "$tmp_runtime/modules/raohane/services/RaohaneLyrics.qml" \
  "$tmp_runtime/shell.qml" \
  "$tmp_runtime/panelFamilies/RaohaneFamily.qml" \
  "$tmp_runtime/defaults/native.json" \
  "$tmp_runtime/scripts/install-deps.sh" \
  "$tmp_runtime/scripts/prune-runtime.sh" \
  "$tmp_runtime/scripts/autostart.sh" \
  "$tmp_runtime/scripts/lyrics-resolve.py" \
  "$tmp_runtime/scripts/product-live-check.sh" \
  "$tmp_runtime/scripts/phase4-live-check.sh" \
  "$tmp_runtime/scripts/release-live-check.sh"; do
  [[ -e "$preserved" ]] || fail "pruner removed required native path: $preserved"
done

[[ "$(tr -d '\r\n' < "$tmp_runtime/qmldir")" == 'module qs' ]] || fail 'pruner damaged root qmldir'
root_qml_count="$(find "$tmp_runtime" -mindepth 1 -maxdepth 1 -type f -name '*.qml' -printf '.' | wc -c)"
[[ "$root_qml_count" -eq 1 ]] || fail "pruned runtime still has $root_qml_count root QML files"

bash scripts/runtime-payload-audit.sh

printf 'standalone-runtime-audit: source/runtime are native-only, current Task/Lyrics/product validators survive clean staging, doctor reuses strict payload validation and older settings upgrade safely to schema v12\n'
