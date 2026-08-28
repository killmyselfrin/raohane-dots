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
)
for path in "${required[@]}"; do
  [[ -e "$path" ]] || fail "missing native runtime path: $path"
done

retired_source=(
  scripts/sync-end4-foundation.sh
  scripts/install-foundation-deps.sh
  upstream/end4-pC.lock
  upstream/illogical-impulse.lock
)
for path in "${retired_source[@]}"; do
  [[ ! -e "$path" ]] || fail "retired upstream bootstrap/sync path returned: $path"
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
  || fail 'installer does not prune the copied runtime before startup'
rg -q '^prune_runtime_if_needed\(\)' scripts/raohane \
  || fail 'Raohane CLI does not define installed-runtime pruning'
rg -q '^[[:space:]]*prune_runtime_if_needed$' scripts/raohane \
  || fail 'raohane run does not prune before qs starts'
rg -q 'bash "\$pruner" "\$RUNTIME"' scripts/raohane \
  || fail 'Raohane CLI does not route pruning through the dedicated script'

rg -q 'doctor \[all\|graphics\|deps\|services\|runtime\]' scripts/raohane \
  || fail 'CLI usage does not expose doctor runtime'
rg -q '^print_runtime_integrity\(\)' scripts/raohane \
  || fail 'CLI lost installed-runtime integrity diagnostics'
rg -q '^[[:space:]]*runtime\)' scripts/raohane \
  || fail 'doctor runtime route is missing'
rg -q 'native\.json.*schema v10|schemaVersion.*10' scripts/raohane \
  || fail 'doctor runtime no longer validates native config schema v10'

tmp_runtime="$(mktemp -d /tmp/raohane-standalone-audit.XXXXXX)"
cleanup() { rm -rf -- "$tmp_runtime"; }
trap cleanup EXIT

mkdir -p \
  "$tmp_runtime/modules" \
  "$tmp_runtime/panelFamilies" \
  "$tmp_runtime/defaults" \
  "$tmp_runtime/services" \
  "$tmp_runtime/scripts"
cp shell.qml qmldir "$tmp_runtime/"
cp -a modules/raohane "$tmp_runtime/modules/"
cp panelFamilies/RaohaneFamily.qml "$tmp_runtime/panelFamilies/"
cp scripts/install-deps.sh scripts/prune-runtime.sh scripts/autostart.sh "$tmp_runtime/scripts/"
mkdir -p "$tmp_runtime/modules/common" "$tmp_runtime/modules/ii"
for name in "${retired_script_dirs[@]}"; do
  mkdir -p "$tmp_runtime/scripts/$name"
  touch "$tmp_runtime/scripts/$name/legacy-helper"
done
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
  "$tmp_runtime/scripts/fake-boundary-audit.sh"

bash scripts/prune-runtime.sh "$tmp_runtime" >/dev/null

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
  "$tmp_runtime/scripts/fake-boundary-audit.sh"; do
  [[ ! -e "$retired" ]] || fail "pruner left retired/source-only installed path: $retired"
done
for name in "${retired_script_dirs[@]}"; do
  [[ ! -e "$tmp_runtime/scripts/$name" ]] || fail "pruner left retired installed script tree: scripts/$name"
done

for preserved in \
  "$tmp_runtime/modules/raohane" \
  "$tmp_runtime/shell.qml" \
  "$tmp_runtime/panelFamilies/RaohaneFamily.qml" \
  "$tmp_runtime/scripts/install-deps.sh" \
  "$tmp_runtime/scripts/prune-runtime.sh" \
  "$tmp_runtime/scripts/autostart.sh"; do
  [[ -e "$preserved" ]] || fail "pruner removed required native path: $preserved"
done

[[ "$(tr -d '\r\n' < "$tmp_runtime/qmldir")" == 'module qs' ]] || fail 'pruner damaged root qmldir'
root_qml_count="$(find "$tmp_runtime" -mindepth 1 -maxdepth 1 -type f -name '*.qml' -printf '.' | wc -c)"
[[ "$root_qml_count" -eq 1 ]] || fail "pruned runtime still has $root_qml_count root QML files"

printf 'standalone-runtime-audit: installed graph keeps native backends while excluding legacy/source-only QML and tooling\n'
