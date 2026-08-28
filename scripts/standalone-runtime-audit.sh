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

# The launcher must enforce pruning before handing control to Quickshell. This
# lets an upgraded CLI clean an older installed runtime on its first launch.
rg -q '^prune_runtime_if_needed\(\)' scripts/raohane \
  || fail 'Raohane CLI does not define installed-runtime pruning'
rg -q '^[[:space:]]*prune_runtime_if_needed$' scripts/raohane \
  || fail 'raohane run does not prune before qs starts'
rg -q 'bash "\$pruner" "\$RUNTIME"' scripts/raohane \
  || fail 'Raohane CLI does not route pruning through the dedicated script'

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
  "$tmp_runtime/defaults/config.json" \
  "$tmp_runtime/panelFamilies/IllogicalImpulseFamily.qml" \
  "$tmp_runtime/panelFamilies/ReferenceFamily.qml"; do
  [[ ! -e "$retired" ]] || fail "pruner left retired installed path: $retired"
done

[[ -d "$tmp_runtime/modules/raohane" ]] || fail 'pruner removed native modules/raohane'
[[ -f "$tmp_runtime/panelFamilies/RaohaneFamily.qml" ]] || fail 'pruner removed RaohaneFamily'
[[ "$(tr -d '\r\n' < "$tmp_runtime/qmldir")" == 'module qs' ]] || fail 'pruner damaged root qmldir'

printf 'standalone-runtime-audit: native QML is legacy-independent and installed-runtime pruning is valid\n'
