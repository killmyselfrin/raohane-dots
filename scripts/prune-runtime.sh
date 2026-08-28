#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-}"

if [[ -z "$TARGET" ]]; then
  echo 'Usage: prune-runtime.sh <installed-raohane-runtime>' >&2
  exit 2
fi

TARGET="$(realpath -m -- "$TARGET")"
case "$TARGET" in
  /|/home|/usr|/etc|/var|/opt|/tmp)
    echo "Refusing unsafe runtime target: $TARGET" >&2
    exit 2
    ;;
esac

[[ -f "$TARGET/shell.qml" ]] || {
  echo "Not a Raohane runtime: missing $TARGET/shell.qml" >&2
  exit 1
}
[[ -d "$TARGET/modules/raohane" ]] || {
  echo "Not a Raohane runtime: missing $TARGET/modules/raohane" >&2
  exit 1
}
[[ -f "$TARGET/panelFamilies/RaohaneFamily.qml" ]] || {
  echo "Not a Raohane runtime: missing RaohaneFamily.qml" >&2
  exit 1
}

# Retired QML/runtime trees. They may remain in the source checkout until live
# validation is complete, but they must not be present in an installed Raohane.
rm -rf -- \
  "$TARGET/modules/common" \
  "$TARGET/modules/ii" \
  "$TARGET/services" \
  "$TARGET/upstream" \
  "$TARGET/.git" \
  "$TARGET/.github"

rm -f -- \
  "$TARGET/GlobalStates.qml" \
  "$TARGET/defaults/config.json" \
  "$TARGET/panelFamilies/IllogicalImpulseFamily.qml"

# Directory imports discover every QML file in panelFamilies. Keep the installed
# directory intentionally single-family even if source/reference families still
# live in the repository during migration.
if [[ -d "$TARGET/panelFamilies" ]]; then
  find "$TARGET/panelFamilies" -mindepth 1 -maxdepth 1 -type f \
    ! -name 'RaohaneFamily.qml' -delete
fi

# A standalone installed runtime must retain its root module and native family.
[[ "$(tr -d '\r\n' < "$TARGET/qmldir")" == 'module qs' ]] || {
  echo 'Installed root qmldir is not the native qs module.' >&2
  exit 1
}
[[ -f "$TARGET/panelFamilies/RaohaneFamily.qml" ]] || {
  echo 'Pruning removed the native Raohane family unexpectedly.' >&2
  exit 1
}

for retired in \
  "$TARGET/modules/common" \
  "$TARGET/modules/ii" \
  "$TARGET/services" \
  "$TARGET/GlobalStates.qml" \
  "$TARGET/panelFamilies/IllogicalImpulseFamily.qml"; do
  [[ ! -e "$retired" ]] || {
    echo "Legacy runtime path survived pruning: $retired" >&2
    exit 1
  }
done

printf 'Raohane installed runtime pruned to native QML graph: %s\n' "$TARGET"
