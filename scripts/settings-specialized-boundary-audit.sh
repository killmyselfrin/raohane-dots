#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'settings-specialized-boundary-audit: %s\n' "$*" >&2
  exit 1
}

backup='modules/raohane/RaohaneBackupSettings.qml'
language='modules/raohane/RaohaneSettingsLanguage.qml'

for file in "$backup" "$language"; do
  [[ -f "$file" ]] || fail "missing specialized Settings page: $file"
done

for contract in \
  'readonly property bool compactLayout:' \
  'FileDialog[[:space:]]*\{' \
  'RaohaneBackup\.exportBackup\(selectedFile\)' \
  'RaohaneBackup\.restoreBackup\(root\.selectedRestorePath\)' \
  'columns:[[:space:]]*root\.compactLayout \? 1 : 2' \
  'showStateRail:[[:space:]]*true' \
  'stateRailColor:[[:space:]]*root\.statusColor' \
  'RaohaneDivider[[:space:]]*\{' \
  'surfaceRadius:[[:space:]]*RaohaneTheme\.radiusLarge' \
  'surfaceRadius:[[:space:]]*RaohaneTheme\.radiusSmall'; do
  grep -Eq "$contract" "$backup" || fail "Backup Settings lost contract: $contract"
done

if grep -Eq 'surfaceRadius:[[:space:]]*[0-9]' "$backup"; then
  fail 'Backup Settings reintroduced hard-coded surface radii'
fi
if grep -Eq 'Process[[:space:]]*\{|Quickshell\.execDetached|pkexec|sudo' "$backup"; then
  fail 'Backup Settings bypasses the RaohaneBackup service boundary'
fi

for contract in \
  'readonly property bool compactLayout:' \
  'RaohaneI18n\.supportedLanguages' \
  'RaohaneI18n\.language' \
  'RaohaneI18n\.setLanguage\(languageCard\.modelData\.code\)' \
  'showStateRail:[[:space:]]*selected \|\| hovered' \
  'stateRailColor:[[:space:]]*RaohaneTheme\.accent' \
  'activeFocusOnTab:[[:space:]]*true' \
  'surfaceRadius:[[:space:]]*RaohaneTheme\.radiusLarge' \
  'surfaceRadius:[[:space:]]*RaohaneTheme\.radiusSmall'; do
  grep -Eq "$contract" "$language" || fail "Language Settings lost contract: $contract"
done

if grep -Eq 'surfaceRadius:[[:space:]]*[0-9]' "$language"; then
  fail 'Language Settings reintroduced hard-coded surface radii'
fi
if grep -Eq 'FileView|Process[[:space:]]*\{|Quickshell\.execDetached' "$language"; then
  fail 'Language Settings bypasses the RaohaneI18n ownership boundary'
fi

printf 'settings-specialized-boundary-audit: responsive Backup/Language pages use Nocturne surfaces while preserving native backup and i18n ownership\n'
