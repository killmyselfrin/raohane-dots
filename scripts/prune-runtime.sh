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

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
NATIVE_CONFIG="$CONFIG_HOME/raohane/native.json"
NATIVE_DEFAULTS="$TARGET/defaults/native.json"

# Normalize an existing native document before the shell starts. Native schema
# upgrades are additive: defaults provide new keys while every existing user
# value (and unknown forward-compatible key) is preserved. This makes upgrades
# deterministic and avoids waiting for an asynchronous QML save before doctor.
if [[ -f "$NATIVE_CONFIG" && -f "$NATIVE_DEFAULTS" ]]; then
  python3 - "$NATIVE_CONFIG" "$NATIVE_DEFAULTS" <<'PY'
import json
import pathlib
import sys

config_path = pathlib.Path(sys.argv[1])
defaults_path = pathlib.Path(sys.argv[2])

try:
    current = json.loads(config_path.read_text(encoding="utf-8"))
    defaults = json.loads(defaults_path.read_text(encoding="utf-8"))
except (OSError, json.JSONDecodeError):
    raise SystemExit(0)

if not isinstance(current, dict) or not isinstance(defaults, dict):
    raise SystemExit(0)

target_schema = defaults.get("schemaVersion")
current_schema = current.get("schemaVersion")
if not isinstance(target_schema, int) or current_schema == target_schema:
    raise SystemExit(0)


def merge(base, override):
    if isinstance(base, dict) and isinstance(override, dict):
        result = {key: merge(value, override[key]) if key in override else value
                  for key, value in base.items()}
        for key, value in override.items():
            if key not in result:
                result[key] = value
        return result
    return override

upgraded = merge(defaults, current)
upgraded["schemaVersion"] = target_schema
config_path.parent.mkdir(parents=True, exist_ok=True)
temporary = config_path.with_suffix(config_path.suffix + ".tmp")
temporary.write_text(json.dumps(upgraded, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
temporary.replace(config_path)
print(f"[Raohane] Upgraded native config schema v{current_schema} -> v{target_schema}.")
PY
fi

# Retired runtime trees from pre-standalone installs.
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
  "$TARGET/scripts/lyrics" \
  "$TARGET/scripts/musicRecognition" \
  "$TARGET/scripts/theming"

rm -f -- \
  "$TARGET/defaults/config.json" \
  "$TARGET/scripts/presets.sh" \
  "$TARGET/scripts/migrate-legacy-config.py" \
  "$TARGET/scripts/raohane" \
  "$TARGET/scripts/raohane-audit.sh"

# Static source/CI audits do not belong in the installed product runtime. The
# interactive phase4-live-check.sh intentionally does not match this pattern
# and remains available to `raohane doctor/validate phase4`.
find "$TARGET/scripts" -mindepth 1 -maxdepth 1 -type f -name '*-audit.sh' -delete

# shell.qml is the complete root bootstrap. Any other root-level QML file comes
# from an older source tree and must not be discoverable in the installed qs
# module (for example GlobalStates.qml or ReloadPopup.qml).
find "$TARGET" -mindepth 1 -maxdepth 1 -type f -name '*.qml' \
  ! -name 'shell.qml' -delete

# Directory imports discover every QML file in panelFamilies. Keep the installed
# directory intentionally single-family.
if [[ -d "$TARGET/panelFamilies" ]]; then
  find "$TARGET/panelFamilies" -mindepth 1 -maxdepth 1 -type f \
    ! -name 'RaohaneFamily.qml' -delete
fi

# A standalone installed runtime must retain its root module, native family and
# product-side maintenance/validation helpers.
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
[[ -f "$TARGET/scripts/install-deps.sh" ]] || {
  echo 'Pruning removed runtime dependency diagnostics unexpectedly.' >&2
  exit 1
}
[[ -f "$TARGET/scripts/prune-runtime.sh" ]] || {
  echo 'Pruning removed the self-healing runtime pruner unexpectedly.' >&2
  exit 1
}
[[ -f "$TARGET/scripts/autostart.sh" ]] || {
  echo 'Pruning removed native autostart backend unexpectedly.' >&2
  exit 1
}
[[ -f "$TARGET/scripts/phase4-live-check.sh" ]] || {
  echo 'Pruning removed the Phase 4 live validator unexpectedly.' >&2
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
  "$TARGET/scripts/lyrics" \
  "$TARGET/scripts/musicRecognition" \
  "$TARGET/scripts/theming" \
  "$TARGET/scripts/presets.sh" \
  "$TARGET/scripts/migrate-legacy-config.py" \
  "$TARGET/scripts/raohane" \
  "$TARGET/scripts/raohane-audit.sh"; do
  [[ ! -e "$retired" ]] || {
    echo "Legacy/source-only runtime path survived pruning: $retired" >&2
    exit 1
  }
done

if find "$TARGET/scripts" -mindepth 1 -maxdepth 1 -type f -name '*-audit.sh' -print -quit | grep -q .; then
  echo 'Source-only audit survived installed-runtime pruning.' >&2
  exit 1
fi

root_qml_count="$(find "$TARGET" -mindepth 1 -maxdepth 1 -type f -name '*.qml' -printf '.' | wc -c)"
[[ "$root_qml_count" -eq 1 ]] || {
  echo "Installed runtime has unexpected root QML files: $root_qml_count" >&2
  exit 1
}

printf 'Raohane installed runtime pruned to native QML/backend graph: %s\n' "$TARGET"
