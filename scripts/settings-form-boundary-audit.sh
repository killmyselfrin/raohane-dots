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
  'height:[[:space:]]*root\.numberRow \? 80 : root\.textRow \? 70 : 62' \
  'RaohaneSlider[[:space:]]*\{' \
  'Controls\.ComboBox[[:space:]]*\{' \
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

printf 'settings-form-boundary-audit: responsive form geometry, accurate deep-link scrolling, shared dividers and keyboard-operable numeric/choice controls are valid\n'
