#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

VERSION="$(tr -d '[:space:]' < VERSION)"
[[ -n "$VERSION" ]] || { echo 'FAIL  VERSION is empty' >&2; exit 1; }
NAME="Raohane-$VERSION"
DIST="$ROOT/dist"
ZIP="$DIST/$NAME.zip"
SHA_FILE="$DIST/$NAME.sha256"

for cmd in bash python3 rsync zip unzip sha256sum; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "FAIL  required packaging command missing: $cmd" >&2; exit 1; }
done

printf 'Packaging %s\n' "$NAME"

# Release gates.
bash -n install-raohane-foundation.sh
bash -n scripts/raohane
bash -n scripts/raohane-deps
bash -n scripts/raohane-doctor
bash -n scripts/raohane-graphics
bash -n scripts/audit-foundation.sh
bash -n scripts/audit-runtime-paths.sh
python3 -m py_compile scripts/generate-upstream-package-baseline.py scripts/migrate-runtime-identity.py

cp manifests/upstream-package-baseline.tsv /tmp/raohane-baseline.tsv
cp manifests/upstream-package-baseline.md /tmp/raohane-baseline.md
python3 scripts/generate-upstream-package-baseline.py
diff -u /tmp/raohane-baseline.tsv manifests/upstream-package-baseline.tsv
diff -u /tmp/raohane-baseline.md manifests/upstream-package-baseline.md

bash scripts/audit-runtime-paths.sh
bash install-raohane-foundation.sh --check
bash scripts/audit-foundation.sh

if find . -type f \( -iname '*.ttf' -o -iname '*.otf' -o -iname '*.woff' -o -iname '*.woff2' -o -iname '*.eot' \) \
  -not -path './.git/*' -not -path './dist/*' | grep -q .; then
  echo 'FAIL  bundled font binaries detected before packaging' >&2
  exit 1
fi

rm -rf "$DIST"
mkdir -p "$DIST"
stage="$(mktemp -d)"
trap 'rm -rf "$stage" /tmp/raohane-baseline.tsv /tmp/raohane-baseline.md' EXIT
mkdir -p "$stage/$NAME"

# Keep everything required for source-level testing and full dependency installation,
# including the pinned dist-arch package source. Exclude CI/dev-only and old prototype data.
rsync -a \
  --exclude='.git/' \
  --exclude='.github/' \
  --exclude='dist/' \
  --exclude='migration/' \
  --exclude='__pycache__/' \
  --exclude='*.pyc' \
  --exclude='*.pkg.tar.*' \
  --exclude='cache/' \
  "$ROOT/" "$stage/$NAME/"

# Re-check the exact staged payload, not only the repository.
if find "$stage/$NAME" -type f \( -iname '*.ttf' -o -iname '*.otf' -o -iname '*.woff' -o -iname '*.woff2' -o -iname '*.eot' \) | grep -q .; then
  echo 'FAIL  font binary entered staged release payload' >&2
  exit 1
fi

(
  cd "$stage"
  zip -q -r -y "$ZIP" "$NAME"
)

unzip -tq "$ZIP" >/dev/null
if unzip -Z1 "$ZIP" | grep -Ei '\.(ttf|otf|woff|woff2|eot)$' >/dev/null; then
  echo 'FAIL  font binary detected inside final ZIP' >&2
  exit 1
fi

sha256sum "$ZIP" | tee "$SHA_FILE"
printf 'PASS  release archive: %s\n' "$ZIP"
printf 'PASS  release checksum: %s\n' "$SHA_FILE"
