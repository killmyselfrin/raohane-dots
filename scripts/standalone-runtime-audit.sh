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

# Everything copied into the standalone product graph must resolve without the
# inherited common/ii/service namespaces. This intentionally scans every native
# QML file, not only the top-level family surfaces.
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

# Installation and launch both enforce pruning. Installer coverage makes
# --no-start native-only; launcher coverage self-heals older installed copies.
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

# Live validation needs a deterministic way to distinguish source/CI state from
# what is actually installed on the user's machine.
rg -q 'doctor \[all\|graphics\|deps\|services\|runtime\]' scripts/raohane \
  || fail 'CLI usage does not expose doctor runtime'
rg -q '^print_runtime_integrity\(\)' scripts/raohane \
  || fail 'CLI lost installed-runtime integrity diagnostics'
rg -q '^[[:space:]]*runtime\)' scripts/raohane \
  || fail 'doctor runtime route is missing'
rg -q 'native\.json.*schema v10|schemaVersion.*10' scripts/raohane \
  || fail 'doctor runtime no longer validates native config schema v10'

# Exercise the pruner against a disposable runtime graph. This proves the
# source checkout can keep rollback/reference trees while installed Raohane
# contains only the native QML graph.
tmp_runtime="$(mktemp -d /tmp/raohane-standalone-audit.XXXXXX)"
cleanup() { rm -rf -- "$tmp_runtime"; }
trap cleanup EXIT

mkdir -p \
  "$tmp_runtime/modules" \
  "$tmp_runtime/panelFamilies" \
  "$tmp_runtime/defaults" \
  "$tmp_runtime/services"
cp shell.qml qmldir "$tmp_runtime/"
cp -a modules/raohane "$tmp_runtime/modules/"
cp panelFamilies/RaohaneFamily.qml "$tmp_runtime/panelFamilies/"
mkdir -p "$tmp_runtime/modules/common" "$tmp_runtime/modules/ii"
touch \
  "$tmp_runtime/GlobalStates.qml" \
  "$tmp_runtime/ReloadPopup.qml" \
  "$tmp_runtime/AnotherInheritedRoot.qml" \
  "$tmp_runtime/defaults/config.json" \
  "$tmp_runtime/panelFamilies/IllogicalImpulseFamily.qml" \
  "$tmp_runtime/panelFamilies/ReferenceFamily.qml" \
  "$tmp_runtime/services/Idle.qml"

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
  "$tmp_runtime/panelFamilies/ReferenceFamily.qml"; do
  [[ ! -e "$retired" ]] || fail "pruner left retired installed path: $retired"
done

[[ -d "$tmp_runtime/modules/raohane" ]] || fail 'pruner removed native modules/raohane'
[[ -f "$tmp_runtime/shell.qml" ]] || fail 'pruner removed shell.qml'
[[ -f "$tmp_runtime/panelFamilies/RaohaneFamily.qml" ]] || fail 'pruner removed RaohaneFamily'
[[ "$(tr -d '\r\n' < "$tmp_runtime/qmldir")" == 'module qs' ]] || fail 'pruner damaged root qmldir'
root_qml_count="$(find "$tmp_runtime" -mindepth 1 -maxdepth 1 -type f -name '*.qml' -printf '.' | wc -c)"
[[ "$root_qml_count" -eq 1 ]] || fail "pruned runtime still has $root_qml_count root QML files"

printf 'standalone-runtime-audit: native QML is legacy-independent; upstream sync/bootstrap is retired and install/launch pruning is enforced\n'
