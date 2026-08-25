#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
LOCK_FILE="$ROOT/upstream/end4-pC.lock"
MODE="dry-run"
ALLOW_DIRTY=0

usage() {
  cat <<'EOF'
Raohane end4-pC foundation synchronizer

Usage:
  bash scripts/sync-end4-foundation.sh
  bash scripts/sync-end4-foundation.sh --apply
  bash scripts/sync-end4-foundation.sh --apply --allow-dirty

The script imports the mature end4-pC runtime while preserving Raohane-owned
identity, installer, docs, patches, modules/raohane and Raohane scripts.
EOF
}

while (($#)); do
  case "$1" in
    --apply) MODE="apply" ;;
    --allow-dirty) ALLOW_DIRTY=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

for cmd in git rsync jq mktemp cmp; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "[Raohane] Missing required command: $cmd" >&2
    exit 1
  }
done

[[ -f "$LOCK_FILE" ]] || { echo "[Raohane] Missing $LOCK_FILE" >&2; exit 1; }
# shellcheck disable=SC1090
source "$LOCK_FILE"
: "${repo:?Missing repo in lock file}"
: "${ref:?Missing ref in lock file}"

if [[ "$MODE" == "apply" && "$ALLOW_DIRTY" -ne 1 ]]; then
  if [[ -n "$(git -C "$ROOT" status --porcelain)" ]]; then
    echo "[Raohane] Refusing to modify a dirty working tree." >&2
    echo "Commit/stash changes first, or pass --allow-dirty intentionally." >&2
    exit 1
  fi
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
UPSTREAM="$TMP/end4-pC"
PREVIEW="$TMP/preview"
mkdir -p "$PREVIEW"

echo "[Raohane] Fetching end4-pC @ $ref"
git clone --filter=blob:none --no-checkout "$repo" "$UPSTREAM" >/dev/null 2>&1
git -C "$UPSTREAM" checkout --detach "$ref" >/dev/null 2>&1

actual_ref="$(git -C "$UPSTREAM" rev-parse HEAD)"
[[ "$actual_ref" == "$ref" ]] || {
  echo "[Raohane] Upstream lock mismatch: expected $ref, got $actual_ref" >&2
  exit 1
}

RSYNC=(-a --human-readable)
if [[ "$MODE" == "dry-run" ]]; then
  RSYNC+=(--dry-run --itemize-changes)
fi

sync_dir() {
  local name="$1"; shift
  local dest="$ROOT/$name"
  [[ -d "$UPSTREAM/$name" ]] || return 0

  if [[ "$MODE" == "dry-run" && ! -d "$dest" ]]; then
    echo "would create directory: $name/"
    mkdir -p "$PREVIEW/$name"
    dest="$PREVIEW/$name"
  elif [[ "$MODE" == "apply" ]]; then
    mkdir -p "$dest"
  fi

  rsync "${RSYNC[@]}" "$@" "$UPSTREAM/$name/" "$dest/"
}

copy_root_file() {
  local name="$1"
  [[ -f "$UPSTREAM/$name" ]] || return 0
  if [[ "$MODE" == "dry-run" ]]; then
    if ! cmp -s "$UPSTREAM/$name" "$ROOT/$name" 2>/dev/null; then
      echo "would update root file: $name"
    fi
  else
    cp -a "$UPSTREAM/$name" "$ROOT/$name"
  fi
}

echo "[Raohane] Sync mode: $MODE"

# Runtime assets. Fonts are intentionally not vendored; install them as packages.
sync_dir assets --exclude='fonts/'

# Import any upstream defaults. Some end4-pC revisions intentionally do not
# ship defaults/config.json because modules/common/Config.qml contains the
# JsonAdapter defaults. If an upstream config file exists, merge it with the
# Raohane file; otherwise preserve the Raohane config and normalize only the
# foundation-critical panelFamily below.
if [[ -f "$UPSTREAM/defaults/config.json" ]]; then
  sync_dir defaults --exclude='config.json'
  if [[ "$MODE" == "dry-run" ]]; then
    echo "would merge defaults/config.json (upstream base + Raohane overrides)"
  else
    if [[ -f "$ROOT/defaults/config.json" ]]; then
      jq -s '.[0] * .[1]' "$UPSTREAM/defaults/config.json" "$ROOT/defaults/config.json" > "$TMP/config-merged.json"
      mv "$TMP/config-merged.json" "$ROOT/defaults/config.json"
    else
      cp -a "$UPSTREAM/defaults/config.json" "$ROOT/defaults/config.json"
    fi
  fi
else
  sync_dir defaults
fi

# The pinned foundation shell currently registers the `ii` panel family.
# Force it even when the pinned upstream has no defaults/config.json.
# Raohane-native panels are reintroduced progressively after runtime parity.
if [[ -f "$ROOT/defaults/config.json" ]]; then
  if [[ "$MODE" == "dry-run" ]]; then
    current_panel_family="$(jq -r '.panelFamily // "<unset>"' "$ROOT/defaults/config.json")"
    if [[ "$current_panel_family" != "ii" ]]; then
      echo "would force defaults/config.json panelFamily: $current_panel_family -> ii"
    fi
  else
    jq '.panelFamily = "ii"' "$ROOT/defaults/config.json" > "$TMP/config-final.json"
    mv "$TMP/config-final.json" "$ROOT/defaults/config.json"
  fi
fi

# Import the complete mature shell graph while keeping Raohane-native surfaces.
sync_dir modules --exclude='raohane/'
sync_dir services
sync_dir panelFamilies
sync_dir translations

# Bring upstream helpers, but never overwrite Raohane-owned scripts.
sync_dir scripts \
  --exclude='raohane' \
  --exclude='raohane-audit.sh' \
  --exclude='sync-end4-foundation.sh' \
  --exclude='install-foundation-deps.sh'

# Core runtime entry points come from the pinned foundation in this phase.
for file in .qmlformat.ini GlobalStates.qml ReloadPopup.qml killDialog.qml shell.qml welcome.qml; do
  copy_root_file "$file"
done

# Guardrails.
if [[ -d "$ROOT/assets/fonts" ]]; then
  echo "[Raohane] Refusing vendored fonts under assets/fonts." >&2
  if [[ "$MODE" == "apply" ]]; then
    rm -rf "$ROOT/assets/fonts"
  fi
fi

if [[ "$MODE" == "dry-run" ]]; then
  cat <<'EOF'

[Raohane] Preview complete. Repository files were not changed.
Run again with --apply to import the pinned foundation.
EOF
  exit 0
fi

bash -n "$ROOT/scripts/sync-end4-foundation.sh"
[[ -f "$ROOT/scripts/raohane" ]] && bash -n "$ROOT/scripts/raohane"
[[ -f "$ROOT/scripts/install-foundation-deps.sh" ]] && bash -n "$ROOT/scripts/install-foundation-deps.sh"
[[ -f "$ROOT/install-raohane.sh" ]] && bash -n "$ROOT/install-raohane.sh"

echo
printf '[Raohane] Foundation synchronized from %s\n' "$ref"
printf '[Raohane] Review with: git -C %q status --short\n' "$ROOT"
echo '[Raohane] Runtime test target:'
echo '  qs -c raohane'
echo '  then verify Settings, launcher/overview, OSD, notifications, media, audio, network and Bluetooth.'
