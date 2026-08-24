#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'raohane-audit: %s\n' "$*" >&2
  exit 1
}

[[ -f shell.qml ]] || fail 'shell.qml is missing'
[[ -d modules/raohane ]] || fail 'modules/raohane is missing'

while IFS= read -r qmldir; do
  directory="$(dirname -- "$qmldir")"
  while read -r first second third rest; do
    [[ -z "${first:-}" || "$first" == module || "$first" == plugin || "$first" == classname || "$first" == depends || "$first" == optional || "$first" == prefer || "$first" == typeinfo || "$first" == internal ]] && continue
    if [[ "$first" == singleton ]]; then
      file="${rest:-}"
    else
      file="${third:-}"
    fi
    [[ -z "$file" || "$file" == *.so ]] && continue
    [[ -f "$directory/$file" ]] || fail "$qmldir references missing file $directory/$file"
  done < "$qmldir"
done < <(find . -name qmldir -not -path './.git/*' -print)

while IFS= read -r import_line; do
  import_path="${import_line#import }"
  module_path="${import_path#qs.}"
  module_path="${module_path//./\/}"
  [[ -d "$module_path" ]] || fail "unresolved local module $import_path"
done < <(rg -o --no-filename '^import qs\.[A-Za-z0-9_.]+$' shell.qml modules/raohane | sort -u || true)

if rg -n -i 'inir|niri|waffle|ricelin' modules/raohane shell.qml; then
  fail 'primary UI contains a forbidden legacy identity'
fi

printf 'raohane-audit: primary QML graph is structurally valid\n'
