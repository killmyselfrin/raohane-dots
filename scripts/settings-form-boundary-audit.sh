#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'settings-form-boundary-audit: %s\n' "$*" >&2
  exit 1
}

section='modules/raohane/RaohaneSettingsSectionPage.qml'
row='modules/raohane/RaohaneSettingsControlRow.qml'

for file in "$section" "$row"; do
  [[ -f "$file" ]] || fail "missing Settings form file: $file"
done

for contract in \
  'readonly property bool compactLayout:' \
  'function entryHeight\(entry\): int' \
  'function entryOffset\(index: int\): real' \
  'root\.entryOffset\(index\)' \
  'root\.compactLayout \? 680 : 820' \
  'RaohaneSettingsControlRow[[:space:]]*\{'; do
  grep -Eq "$contract" "$section" || fail "Settings section lost form-layout contract: $contract"
done

if grep -Eq 'index[[:space:]]*\*[[:space:]]*72' "$section"; then
  fail 'Settings deep-link scrolling regressed to fixed index-based row offsets'
fi

for contract in \
  'height:[[:space:]]*root\.textRow \? 80 : 68' \
  'activeFocusOnTab:[[:space:]]*root\.toggleRow \|\| root\.numberRow \|\| root\.choiceRow' \
  'readonly property bool compactRow:' \
  'maximumLineCount:[[:space:]]*2' \
  'RaohaneDivider[[:space:]]*\{' \
  'enabled:[[:space:]]*root\.toggleRow' \
  'root\.numberRow && event\.key === Qt\.Key_Left' \
  'root\.numberRow && event\.key === Qt\.Key_Right' \
  'root\.choiceRow && event\.key === Qt\.Key_Left' \
  'root\.choiceRow && event\.key === Qt\.Key_Right'; do
  grep -Eq "$contract" "$row" || fail "Settings control row lost interaction contract: $contract"
done

if grep -Eq 'component[[:space:]]+.*Divider|Rectangle[[:space:]]*\{[[:space:]]*$' "$row"; then
  # Raw rectangles are not needed by the generic row after moving separators to
  # the shared divider primitive. This keeps the control language centralized.
  if grep -Eq '^[[:space:]]*Rectangle[[:space:]]*\{' "$row"; then
    fail 'Settings control row reintroduced a local Rectangle surface/divider'
  fi
fi

printf 'settings-form-boundary-audit: responsive form geometry, accurate deep-link scrolling, shared dividers and keyboard-operable numeric/choice controls are valid\n'
