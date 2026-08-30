#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

usage() {
  cat <<'EOF'
Raohane source release packager

Usage:
  scripts/package-release.sh [OUTPUT_DIR]

The archive is produced from the current committed HEAD, not from uncommitted
working-tree files. OUTPUT_DIR defaults to ./dist.
EOF
}

case "${1:-}" in
  -h|--help)
    usage
    exit 0
    ;;
esac

OUTPUT_DIR="${1:-$ROOT/dist}"

command -v git >/dev/null 2>&1 || {
  echo 'package-release: git is required' >&2
  exit 1
}
command -v sha256sum >/dev/null 2>&1 || {
  echo 'package-release: sha256sum is required' >&2
  exit 1
}

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo 'package-release: run from a Git checkout of Raohane' >&2
  exit 1
}

[[ -f VERSION ]] || {
  echo 'package-release: VERSION is missing' >&2
  exit 1
}

version="$(tr -d '\r\n' < VERSION)"
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z][0-9A-Za-z.-]*)?$ ]] || {
  echo "package-release: invalid VERSION: $version" >&2
  exit 1
}

# The archive is generated from HEAD. Refuse tracked modifications because a
# release whose on-disk VERSION/audits differ from the archived commit is ambiguous.
if ! git diff --quiet -- || ! git diff --cached --quiet --; then
  echo 'package-release: tracked working tree is dirty; commit or stash changes first' >&2
  git status --short >&2
  exit 1
fi

head_version="$(git show HEAD:VERSION 2>/dev/null | tr -d '\r\n')"
[[ "$head_version" == "$version" ]] || {
  echo "package-release: working VERSION ($version) differs from committed HEAD ($head_version)" >&2
  exit 1
}

bash scripts/source-lineage-audit.sh
bash scripts/runtime-payload-audit.sh

mkdir -p "$OUTPUT_DIR"
OUTPUT_DIR="$(realpath -m -- "$OUTPUT_DIR")"
archive="$OUTPUT_DIR/Raohane-${version}.tar.gz"
checksum="$archive.sha256"

rm -f -- "$archive" "$checksum"

git archive \
  --format=tar.gz \
  --prefix="Raohane-${version}/" \
  --output="$archive" \
  HEAD

(
  cd "$OUTPUT_DIR"
  sha256sum "$(basename -- "$archive")" > "$(basename -- "$checksum")"
)

printf 'package-release: source archive: %s\n' "$archive"
printf 'package-release: checksum:       %s\n' "$checksum"
printf 'package-release: commit:         %s\n' "$(git rev-parse HEAD)"
