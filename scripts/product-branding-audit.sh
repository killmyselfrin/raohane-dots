#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'product-branding-audit: %s\n' "$*" >&2
  exit 1
}

# Build the retired upstream token without spelling it in source. The legal
# provenance notice is the sole allowed location; product/runtime/install/docs
# must contain only Raohane identity.
legacy_token="$(printf '%s%s' 'i' 'nir')"

if rg -n -i --hidden \
  --glob '!.git/**' \
  --glob '!NOTICE-UPSTREAM.md' \
  -- "$legacy_token" .; then
  fail 'retired upstream identity is present outside the legal provenance notice'
fi

while IFS= read -r path; do
  [[ -z "$path" ]] && continue
  fail "retired upstream identity is present in a repository path: $path"
done < <(find . -path './.git' -prune -o -iname "*${legacy_token}*" -print)

printf 'product-branding-audit: Raohane product tree contains no retired upstream identity\n'
