#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'screen-translate-boundary-audit: %s\n' "$*" >&2
  exit 1
}

backend='scripts/screen-translate.sh'
[[ -f "$backend" ]] || fail "missing backend: $backend"
bash -n "$backend"

for contract in \
  'RAOHANE_TRANSLATE_TIMEOUT_SECONDS' \
  'subprocess.run' \
  'timeout=timeout' \
  'subprocess.TimeoutExpired' \
  'raise SystemExit(124)' \
  'Translation timed out after'; do
  grep -Fq -- "$contract" "$backend" || fail "bounded translation contract missing: $contract"
done

work="$(mktemp -d -t raohane-translate-audit.XXXXXX)"
trap 'rm -rf "$work"' EXIT
mock_bin="$work/bin"
mkdir -p "$mock_bin"

cat >"$mock_bin/slurp" <<'SH'
#!/bin/sh
printf '0,0 20x20\n'
SH

cat >"$mock_bin/grim" <<'SH'
#!/bin/sh
for last do :; done
printf 'fake-png' >"$last"
SH

cat >"$mock_bin/tesseract" <<'SH'
#!/bin/sh
printf 'hello world\n' >"$2.txt"
SH

cat >"$mock_bin/trans" <<'SH'
#!/bin/sh
sleep 10
printf 'never reached\n'
SH
chmod +x "$mock_bin/slurp" "$mock_bin/grim" "$mock_bin/tesseract" "$mock_bin/trans"

started="$(date +%s)"
output="$(PATH="$mock_bin:$PATH" RAOHANE_TRANSLATE_TIMEOUT_SECONDS=5 bash "$backend" ru)"
elapsed=$(( $(date +%s) - started ))

python3 - "$output" <<'PY' || fail 'hung translator did not return structured timeout JSON'
import json
import sys
payload = json.loads(sys.argv[1])
assert payload["ok"] is False
assert "timed out after 5s" in payload["error"]
assert payload["source"] == "hello world"
assert payload["target"] == "ru"
PY

((elapsed < 9)) || fail "hung translator escaped the 5s backend bound (${elapsed}s elapsed)"

cat >"$mock_bin/trans" <<'SH'
#!/bin/sh
printf 'привет мир\n'
SH
chmod +x "$mock_bin/trans"

output="$(PATH="$mock_bin:$PATH" RAOHANE_TRANSLATE_TIMEOUT_SECONDS=5 bash "$backend" ru)"
python3 - "$output" <<'PY' || fail 'successful translator path no longer returns result JSON'
import json
import sys
payload = json.loads(sys.argv[1])
assert payload["ok"] is True
assert payload["source"] == "hello world"
assert payload["translation"] == "привет мир"
assert payload["target"] == "ru"
PY

printf 'screen-translate-boundary-audit: translation backend is bounded and returns structured success/error results\n'
