#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'source-lineage-audit: %s\n' "$*" >&2
  exit 1
}

for path in LICENSE NOTICE-UPSTREAM.md modules/raohane panelFamilies/RaohaneFamily.qml shell.qml install-raohane.sh; do
  [[ -e "$path" ]] || fail "required provenance/runtime path is missing: $path"
done

rg -q 'GNU GENERAL PUBLIC LICENSE' LICENSE || fail 'root LICENSE is not the GNU GPL text'
rg -q 'Version 3' LICENSE || fail 'root LICENSE does not identify GPL version 3'

for marker in \
  'pctrade/end4-pC' \
  'end-4/dots-hyprland' \
  'snowarch/iNiR' \
  'ilyamiro/serpantinum' \
  'retained data' \
  'assets' \
  'translations' \
  'defaults'; do
  rg -q -F "$marker" NOTICE-UPSTREAM.md || fail "NOTICE-UPSTREAM.md is missing lineage marker: $marker"
done

# These migration/source trees must never return to the repository-level active graph.
for retired in \
  modules/ii \
  modules/common \
  services \
  upstream \
  migration \
  panelFamilies/IllogicalImpulseFamily.qml; do
  [[ ! -e "$retired" ]] || fail "retired migration tree returned: $retired"
done

# Runtime source may retain GPL lineage, but it must not resolve an upstream shell namespace.
if rg -n \
  '^import qs\.modules\.ii(\.|$)|^import qs\.modules\.common(\.|$)|^import qs\.services(\.|$)|\bIllogicalImpulseFamily\b|\bRaohaneLegacyBridge\b' \
  shell.qml panelFamilies/RaohaneFamily.qml modules/raohane; then
  fail 'active runtime source resolves a retired upstream namespace'
fi

# Installation/update paths must stay self-contained. Historical provenance text is allowed
# in documentation, but executable install/runtime paths may not fetch another shell.
if rg -n \
  'git[[:space:]]+clone.*(end4|illogical|iNiR)|sync-end4-foundation|install-foundation-deps' \
  install-raohane.sh scripts/raohane scripts/install-deps.sh; then
  fail 'normal install/runtime path can fetch or execute an upstream shell'
fi

# Font binaries are deliberately package-managed. This is both a release-size boundary and
# avoids silently redistributing font files with separate licensing requirements.
if find . -path './.git' -prune -o -type f \
  \( -iname '*.ttf' -o -iname '*.otf' -o -iname '*.woff' -o -iname '*.woff2' -o -iname '*.eot' \) \
  -print -quit | grep -q .; then
  fail 'vendored font binary detected'
fi

# Asset symlinks are part of the source distribution; broken links would make the release
# incomplete and can accidentally obscure the real retained source file.
if find assets -xtype l -print -quit | grep -q .; then
  find assets -xtype l -print >&2
  fail 'broken asset symlink detected'
fi

printf 'source-lineage-audit: GPL notice, retained-data provenance, standalone runtime boundary and asset/font release constraints are valid\n'
