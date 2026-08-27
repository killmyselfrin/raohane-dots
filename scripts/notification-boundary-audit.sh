#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'notification-boundary-audit: %s\n' "$*" >&2
  exit 1
}

card='modules/raohane/RaohaneNotificationCard.qml'
center='modules/raohane/RaohaneNotificationCenter.qml'
popup='modules/raohane/RaohaneNotificationPopup.qml'

for file in "$card" "$center" "$popup"; do
  [[ -f "$file" ]] || fail "missing notification surface: $file"
  rg -q 'RaohaneNotifications\.' "$file" \
    || fail "$file does not consume RaohaneNotifications"
done

for file in "$card" "$center"; do
  rg -q 'RaohaneIcon[[:space:]]*\{' "$file" \
    || fail "$file does not use RaohaneIcon"
done

for symbol in 'RaohaneState\.controlCenterOpen' 'RaohaneConfig\.barBottom'; do
  rg -q "$symbol" "$popup" || fail "notification popup lost native state/config: $symbol"
done

if rg -n '^import qs$|^import qs\.services$|^import qs\.modules\.common|\bMaterialSymbol[[:space:]]*\{|\bGlobalStates\.|\bConfig\.' "$card" "$center" "$popup"; then
  fail 'notification UI regressed to inherited common/config/state/services'
fi

printf 'notification-boundary-audit: card, center and popup framework dependencies are Raohane-owned\n'
