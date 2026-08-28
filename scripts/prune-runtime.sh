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

# Retired upstream helper families are not part of the native product runtime.
# Native Raohane uses its own capture/translation/autostart/thumbnail scripts.
rm -rf -- \
  "$TARGET/scripts/ai" \
  "$TARGET/scripts/cava" \
  "$TARGET/scripts/colors" \
  "$TARGET/scripts/hyprland" \
  "$TARGET/scripts/images" \
  "$TARGET/scripts/keyring" \
  "$TARGET/scripts/kvantum" \
  "$TARGET/scripts/lyrics"

rm -f -- "$TARGET/defaults/config.json"

# shell.qml is the complete root bootstrap. Any other root-level QML file comes
# from the inherited source tree and must not be discoverable in the installed
# qs module (for example GlobalStates.qml or ReloadPopup.qml).
find "$TARGET" -mindepth 1 -maxdepth 1 -type f -name '*.qml' \
  ! -name 'shell.qml' -delete

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
[[ -f "$TARGET/shell.qml" ]] || {
  echo 'Pruning removed shell.qml unexpectedly.' >&2
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
  "$TARGET/ReloadPopup.qml" \
  "$TARGET/panelFamilies/IllogicalImpulseFamily.qml" \
  "$TARGET/scripts/ai" \
  "$TARGET/scripts/cava" \
  "$TARGET/scripts/colors" \
  "$TARGET/scripts/hyprland" \
  "$TARGET/scripts/images" \
  "$TARGET/scripts/keyring" \
  "$TARGET/scripts/kvantum" \
  "$TARGET/scripts/lyrics"; do
  [[ ! -e "$retired" ]] || {
    echo "Legacy runtime path survived pruning: $retired" >&2
    exit 1
  }
done

root_qml_count="$(find "$TARGET" -mindepth 1 -maxdepth 1 -type f -name '*.qml' -printf '.' | wc -c)"
[[ "$root_qml_count" -eq 1 ]] || {
  echo "Installed runtime has unexpected root QML files: $root_qml_count" >&2
  exit 1
}

printf 'Raohane installed runtime pruned to native QML/script graph: %s\n' "$TARGET"
