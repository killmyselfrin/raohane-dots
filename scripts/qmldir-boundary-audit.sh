#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'qmldir-boundary-audit: %s\n' "$*" >&2
  exit 1
}

module_dir='modules/raohane'
qmldir_file="$module_dir/qmldir"

[[ -f "$qmldir_file" ]] || fail 'missing modules/raohane/qmldir'
rg -q '^module qs\.modules\.raohane$' "$qmldir_file" \
  || fail 'qmldir lost the Raohane module declaration'

# qmlformat validates file syntax but does not guarantee that Quickshell can
# resolve the file as a type from the qs.modules.raohane module. Keep every
# top-level component registered so runtime loads cannot fail with "is not a type".
while IFS= read -r file; do
  name="$(basename "$file")"
  if ! awk -v target="$name" '
    $1 == "singleton" && $4 == target { found = 1 }
    $1 != "singleton" && $3 == target { found = 1 }
    END { exit(found ? 0 : 1) }
  ' "$qmldir_file"; then
    fail "top-level QML file is not registered in qmldir: $name"
  fi
done < <(find "$module_dir" -maxdepth 1 -type f -name '*.qml' -print | sort)

# Also reject stale registrations that point to files no longer present.
awk '
  $1 == "singleton" { print $4 }
  $1 != "module" && $1 != "singleton" && NF >= 3 { print $3 }
' "$qmldir_file" | while IFS= read -r target; do
  [[ -n "$target" ]] || continue
  [[ -f "$module_dir/$target" ]] || fail "qmldir references missing QML file: $target"
done

printf 'qmldir-boundary-audit: all top-level Raohane QML types are registered and resolve to existing files\n'
