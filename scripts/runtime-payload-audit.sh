#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'runtime-payload-audit: %s\n' "$*" >&2
  exit 1
}

for path in \
  shell.qml qmldir VERSION assets translations \
  modules/raohane panelFamilies/RaohaneFamily.qml defaults/native.json \
  install/arch scripts scripts/prune-runtime.sh scripts/validate-runtime-payload.sh \
  scripts/lyrics-resolve.py scripts/product-live-check.sh \
  scripts/phase4-live-check.sh scripts/release-live-check.sh; do
  [[ -e "$path" ]] || fail "missing source path required for staging: $path"
done

tmp_root="$(mktemp -d /tmp/raohane-runtime-payload.XXXXXX)"
runtime="$tmp_root/runtime"
config_home="$tmp_root/config"
cleanup() { rm -rf -- "$tmp_root"; }
trap cleanup EXIT

mkdir -p \
  "$runtime/modules" \
  "$runtime/panelFamilies" \
  "$runtime/defaults" \
  "$runtime/install" \
  "$config_home/raohane"

# Mirror install-raohane.sh's explicit payload staging. This must stay verbose on
# purpose: changing the release payload should require updating both contracts.
cp -a shell.qml qmldir VERSION "$runtime/"
cp -a modules/raohane "$runtime/modules/"
cp -a panelFamilies/RaohaneFamily.qml "$runtime/panelFamilies/"
cp -a defaults/native.json "$runtime/defaults/"
cp -a install/arch "$runtime/install/"
cp -a assets "$runtime/"
cp -a translations "$runtime/"
cp -a scripts "$runtime/"
cp -a defaults/native.json "$config_home/raohane/native.json"

XDG_CONFIG_HOME="$config_home" bash scripts/prune-runtime.sh "$runtime" >/dev/null
bash scripts/validate-runtime-payload.sh "$runtime" >/dev/null

# Prove common source-only paths never enter a clean staged runtime even before
# an actual Hyprland session is involved.
for path in \
  .git .github docs patches AGENTS.md ARCHITECTURE.md INDEPENDENCE-PLAN.md \
  README.md install-raohane.sh modules/common modules/ii services; do
  [[ ! -e "$runtime/$path" ]] || fail "source-only path entered staged runtime: $path"
done

[[ -f "$runtime/VERSION" ]] || fail 'VERSION was lost from staged runtime'
[[ -d "$runtime/assets" ]] || fail 'assets were lost from staged runtime'
[[ -d "$runtime/translations" ]] || fail 'translations were lost from staged runtime'
[[ -f "$runtime/install/arch/required.txt" ]] || fail 'required package manifest was lost'
[[ -f "$runtime/install/arch/features.txt" ]] || fail 'feature package manifest was lost'
[[ -f "$runtime/modules/raohane/RaohaneTaskManager.qml" ]] || fail 'native Task Manager was lost'
[[ -f "$runtime/modules/raohane/RaohaneOverlay.qml" ]] || fail 'Command Deck was lost'
[[ -f "$runtime/modules/raohane/services/RaohaneProcesses.qml" ]] || fail 'native process service was lost'
[[ -f "$runtime/modules/raohane/services/RaohaneLyrics.qml" ]] || fail 'native lyrics service was lost'
[[ -f "$runtime/scripts/lyrics-resolve.py" ]] || fail 'lyrics resolver was lost'
[[ -f "$runtime/scripts/product-live-check.sh" ]] || fail 'current product live validator was lost'
[[ -f "$runtime/scripts/validate-runtime-payload.sh" ]] || fail 'runtime payload validator was lost'
[[ -f "$runtime/scripts/phase4-live-check.sh" ]] || fail 'Phase 4 live validator was lost'
[[ -f "$runtime/scripts/release-live-check.sh" ]] || fail 'release live validator was lost'

printf 'runtime-payload-audit: clean standalone staging retains current Task/Lyrics/product validators and post-prune payload validation succeeds\n'
