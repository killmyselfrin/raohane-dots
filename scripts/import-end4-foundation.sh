#!/usr/bin/env bash
set -euo pipefail

UPSTREAM_REPO="https://github.com/pctrade/end4-pC.git"
UPSTREAM_SHA="369554b62de8d659875de828c779b83b28ae9ada"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
MODE="dry-run"

usage() {
  cat <<'EOF'
Usage: ./scripts/import-end4-foundation.sh [--apply]

Without --apply the script only fetches/inspects the pinned upstream and prints
what would happen. --apply synchronizes the pinned end4-pC snapshot into the
current Raohane repository after an explicit confirmation.
EOF
}

case "${1:-}" in
  "") ;;
  --apply) MODE="apply" ;;
  -h|--help) usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
esac

[[ -n "$ROOT" && -d "$ROOT/.git" ]] || {
  echo "[FAIL] Run this inside the Raohane git repository." >&2
  exit 1
}
cd "$ROOT"

for cmd in git rsync find grep mktemp; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "[FAIL] Required command missing: $cmd" >&2
    exit 1
  }
done

if [[ -n "$(git status --porcelain)" ]]; then
  echo "[FAIL] Working tree is dirty. Commit/stash local changes before a foundation reset." >&2
  exit 1
fi

work="$(mktemp -d -t raohane-end4-import.XXXXXX)"
trap 'rm -rf "$work"' EXIT
upstream="$work/end4-pC"
preserve="$work/legacy-raohane"
mkdir -p "$upstream" "$preserve"

printf '[INFO] Upstream: %s\n' "$UPSTREAM_REPO"
printf '[INFO] Pinned commit: %s\n' "$UPSTREAM_SHA"
printf '[INFO] Mode: %s\n' "$MODE"

# Fetch only the pinned snapshot; never silently migrate from a moving main.
git -C "$upstream" init -q
git -C "$upstream" remote add origin "$UPSTREAM_REPO"
git -C "$upstream" fetch -q --depth=1 origin "$UPSTREAM_SHA"
git -C "$upstream" checkout -q --detach FETCH_HEAD
actual_sha="$(git -C "$upstream" rev-parse HEAD)"
[[ "$actual_sha" == "$UPSTREAM_SHA" ]] || {
  echo "[FAIL] Upstream SHA mismatch: expected $UPSTREAM_SHA, got $actual_sha" >&2
  exit 1
}

[[ -f "$upstream/LICENSE" ]] || {
  echo "[FAIL] Upstream LICENSE is missing." >&2
  exit 1
}
grep -q 'GNU GENERAL PUBLIC LICENSE' "$upstream/LICENSE" || {
  echo "[FAIL] Upstream license does not look like the expected GPL license." >&2
  exit 1
}

font_list="$work/fonts.txt"
find "$upstream" -type f \( -iname '*.ttf' -o -iname '*.otf' -o -iname '*.woff' -o -iname '*.woff2' -o -iname '*.eot' \) -print > "$font_list"
if [[ -s "$font_list" ]]; then
  echo '[WARN] Upstream contains font files. They will NOT be imported:'
  sed 's/^/  - /' "$font_list"
fi

required=(
  shell.qml
  modules
  modules/ii/bar
  modules/ii/background
  modules/ii/settings
  modules/ii/mediaControls
  modules/ii/notificationPopup
  modules/ii/onScreenDisplay
  services
  scripts
  translations
  panelFamilies
  LICENSE
)
for path in "${required[@]}"; do
  [[ -e "$upstream/$path" ]] || {
    echo "[FAIL] Required upstream foundation path missing: $path" >&2
    exit 1
  }
done

printf '\n[PASS] Pinned upstream snapshot fetched and validated.\n'
printf '[INFO] Top-level upstream entries:\n'
find "$upstream" -mindepth 1 -maxdepth 1 -printf '  %f\n' | sort

if [[ "$MODE" != "apply" ]]; then
  cat <<'EOF'

[DRY-RUN] No repository files changed.

--apply will:
  1. snapshot selected current Raohane prototype files under migration/legacy-raohane/;
  2. synchronize the complete pinned end4-pC source tree into the repository root;
  3. preserve Raohane migration/legal control files;
  4. exclude font binaries from the import;
  5. leave the result uncommitted for review/audit.
EOF
  exit 0
fi

printf '\nThis is a foundation reset of the working tree to pinned end4-pC.\n'
printf 'Current branch: %s\n' "$(git branch --show-current)"
read -r -p 'Type IMPORT-END4 to continue: ' confirmation
[[ "$confirmation" == 'IMPORT-END4' ]] || {
  echo '[INFO] Cancelled without changes.'
  exit 0
}

# Keep selected old Raohane work as migration reference, not as active runtime.
preserve_paths=(
  modules/raohane
  manifests/raohane-dependencies.tsv
  scripts/raohane
  scripts/raohane-deps
  scripts/raohane-display
  scripts/raohane-net
  scripts/raohane-audio
  scripts/raohane-audit.sh
  install-raohane.sh
  RAOHANE-CHANGELOG.md
)
for path in "${preserve_paths[@]}"; do
  if [[ -e "$ROOT/$path" ]]; then
    mkdir -p "$preserve/$(dirname "$path")"
    cp -a "$ROOT/$path" "$preserve/$path"
  fi
done

# These files define the migration itself and must survive the upstream sync.
rsync -a --delete \
  --exclude='.git/' \
  --exclude='AGENTS.md' \
  --exclude='NOTICE-UPSTREAM.md' \
  --exclude='UPSTREAM-BASE.md' \
  --exclude='migration/' \
  --exclude='scripts/import-end4-foundation.sh' \
  --exclude='scripts/audit-foundation.sh' \
  --exclude='docs/foundation-migration-plan.md' \
  --exclude='*.ttf' \
  --exclude='*.otf' \
  --exclude='*.woff' \
  --exclude='*.woff2' \
  --exclude='*.eot' \
  "$upstream/" "$ROOT/"

mkdir -p "$ROOT/migration/legacy-raohane"
if find "$preserve" -mindepth 1 -print -quit | grep -q .; then
  rsync -a "$preserve/" "$ROOT/migration/legacy-raohane/"
fi

cat > "$ROOT/migration/legacy-raohane/README.md" <<EOF
# Pre-foundation Raohane migration snapshot

This directory contains selected Raohane prototype/system files captured immediately
before importing the pinned end4-pC foundation.

They are migration references only and are not automatically loaded by the active
Quickshell graph.

Imported upstream commit: \`$UPSTREAM_SHA\`
EOF

printf '\n[PASS] Foundation synchronized into working tree.\n'
printf '[NEXT] Review: git status --short\n'
printf '[NEXT] Audit: ./scripts/audit-foundation.sh\n'
printf '[NEXT] Do not mass-rename end4/ii identifiers until the imported baseline launches.\n'
