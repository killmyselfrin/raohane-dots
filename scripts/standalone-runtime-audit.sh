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
  panelFamilies/RaohaneFamily.qml
  modules/raohane
  modules/raohane/config
  modules/raohane/services
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

# Native source may mention old component names only in negative audit scripts,
# never in the runtime composition itself.
if rg -n \
  'component:[[:space:]]*(Overlay|RegionSelector|ScreenTranslator|SidebarLeft|VerticalBar|DropShelfPanel|OnScreenKeyboard|ScreenCorners|ScreenFrame|Polkit|Lock)[[:space:]]*\{' \
  shell.qml panelFamilies/RaohaneFamily.qml; then
  fail 'family composition can still instantiate an inherited presentation type'
fi

printf 'standalone-runtime-audit: all native QML resolves without common/ii/legacy service namespaces\n'
