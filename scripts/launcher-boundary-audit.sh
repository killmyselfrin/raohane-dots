#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'launcher-boundary-audit: %s\n' "$*" >&2
  exit 1
}

launcher='modules/raohane/RaohaneLauncher.qml'
search_bar='modules/raohane/RaohaneLauncherSearchBar.qml'
mode_bar='modules/raohane/RaohaneLauncherModeBar.qml'

for file in "$launcher" "$search_bar" "$mode_bar"; do
  [[ -f "$file" ]] || fail "missing Launcher boundary file: $file"
done

# The Launcher owns search/service state and execution; extracted pieces only
# render controls and emit user intent back to the coordinator.
for component in RaohaneLauncherSearchBar RaohaneLauncherModeBar; do
  grep -Eq "${component}[[:space:]]*\\{" "$launcher" \
    || fail "Launcher lost extracted component: $component"
done

if grep -Eq '^[[:space:]]*(component[[:space:]]+ModeChip:|TextInput[[:space:]]*\{)' "$launcher"; then
  fail 'Launcher regained inline search/mode presentation'
fi

for presentation in "$search_bar" "$mode_bar"; do
  if grep -Eq '^import qs\.modules\.raohane\.(services|config)' "$presentation"; then
    fail "$presentation imported services/config instead of remaining presentation-only"
  fi
  if grep -Eq 'Raohane(Search|State|Config)\.' "$presentation"; then
    fail "$presentation bypasses Launcher coordinator ownership"
  fi
done

for contract in \
  'property string queryText: ""' \
  'signal queryEdited\(string text\)' \
  'signal clearRequested\(\)' \
  'signal settingsRequested\(\)' \
  'signal escapeRequested\(\)' \
  'signal selectionMoveRequested\(int delta\)' \
  'signal submitRequested\(\)' \
  'function focusSearch\(\): void' \
  'Qt\.Key_Escape' \
  'Qt\.Key_Down' \
  'Qt\.Key_Up' \
  'Qt\.Key_Return'; do
  grep -Eq "$contract" "$search_bar" \
    || fail "Launcher SearchBar lost contract: $contract"
done

for contract in \
  'required property string currentMode' \
  'signal modeRequested\(string prefix\)' \
  'root\.currentMode === "app"' \
  'root\.currentMode === "action"' \
  'root\.currentMode === "command"' \
  'root\.currentMode === "calculator"' \
  'root\.currentMode === "clipboard"'; do
  grep -Eq "$contract" "$mode_bar" \
    || fail "Launcher ModeBar lost contract: $contract"
done

for contract in \
  'queryText: RaohaneSearch\.query' \
  'RaohaneSearch\.query = text' \
  'onClearRequested: root\.reset\(\)' \
  'RaohaneState\.setPrimaryOpen\("settings", true\)' \
  'onEscapeRequested: root\.close\(\)' \
  'selection\.move\(delta\)' \
  'onSubmitRequested: root\.executeSelected\(\)' \
  'onModeRequested: prefix => root\.setMode\(prefix\)' \
  'searchBar\.focusSearch\(\)'; do
  grep -Eq "$contract" "$launcher" \
    || fail "Launcher coordinator lost wiring contract: $contract"
done

# Search execution and mode-prefix semantics remain owned by the coordinator.
for contract in \
  'RaohaneSearch\.results\.slice\(0, 8\)' \
  'function stripMode\(value\): string' \
  'value\.startsWith\("/"\)' \
  'value\.startsWith\(">"\)' \
  'value\.startsWith\(":"\)' \
  'value\.startsWith\("="\)' \
  'function executeSelected\(\): void' \
  'result\.execute\(\)' \
  'RaohaneSearch\.executeApplication\(entry\)'; do
  grep -Eq "$contract" "$launcher" \
    || fail "Launcher lost coordinator/search contract: $contract"
done

printf 'launcher-boundary-audit: presentation-only SearchBar/ModeBar and coordinator-owned query, keyboard, mode and execute paths are valid\n'
