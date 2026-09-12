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
idle_content='modules/raohane/RaohaneLauncherIdleContent.qml'
results_view='modules/raohane/RaohaneLauncherResultsView.qml'
footer='modules/raohane/RaohaneLauncherFooter.qml'

for file in "$launcher" "$search_bar" "$mode_bar" "$idle_content" "$results_view" "$footer"; do
  [[ -f "$file" ]] || fail "missing Launcher boundary file: $file"
done

# Launcher owns search/service state and execution. Extracted pieces only render
# presentation and emit user intent back to the coordinator.
for component in \
  RaohaneLauncherSearchBar \
  RaohaneLauncherModeBar \
  RaohaneLauncherIdleContent \
  RaohaneLauncherResultsView \
  RaohaneLauncherFooter; do
  grep -Eq "${component}[[:space:]]*\\{" "$launcher" \
    || fail "Launcher lost extracted component: $component"
done

if grep -Eq '^[[:space:]]*(component[[:space:]]+(ModeChip|PinnedApp):|TextInput[[:space:]]*\{|id:[[:space:]]*(idleAction|resultRow))' "$launcher"; then
  fail 'Launcher regained inline search/mode/content presentation'
fi
if grep -Eq 'No results|Quick access|Dock apps' "$launcher"; then
  fail 'Launcher coordinator regained idle/results copy that belongs to presentation components'
fi

for presentation in "$search_bar" "$mode_bar" "$idle_content" "$results_view" "$footer"; do
  if grep -Eq '^import qs\.modules\.raohane\.(services|config|models)' "$presentation"; then
    fail "$presentation imported services/config/models instead of remaining presentation-only"
  fi
  if grep -Eq 'Raohane(Search|State|Config)\.' "$presentation"; then
    fail "$presentation bypasses Launcher coordinator ownership"
  fi
done

# Presentation components must never become a second execution path.
if grep -Eq '\.execute\(' "$idle_content" "$results_view" "$footer"; then
  fail 'Launcher content presentation executes actions directly instead of emitting intent'
fi

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
  'property var pinnedApps: \[\]' \
  'property var idleActions: \[\]' \
  'signal pinnedRequested\(var entry\)' \
  'signal actionRequested\(var action\)' \
  'component PinnedApp: RaohaneSurface' \
  'component QuickAction: RaohaneSurface' \
  'activeFocusOnTab: true'; do
  grep -Eq "$contract" "$idle_content" \
    || fail "Launcher IdleContent lost contract: $contract"
done

for contract in \
  'property var results: \[\]' \
  'property int selectedIndex: -1' \
  'signal selectionHovered\(int index\)' \
  'signal activateRequested\(int index\)' \
  'component ResultRow: RaohaneSurface' \
  'text: qsTr\("No results"\)' \
  'activeFocusOnTab: true'; do
  grep -Eq "$contract" "$results_view" \
    || fail "Launcher ResultsView lost contract: $contract"
done

for contract in \
  'text: "RAOHANE"' \
  '↑↓ navigate' \
  'RaohaneTheme\.borderFaint'; do
  grep -Eq "$contract" "$footer" \
    || fail "Launcher Footer lost contract: $contract"
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
  'searchBar\.focusSearch\(\)' \
  'pinnedApps: root\.pinnedApps' \
  'idleActions: root\.idleActions' \
  'onPinnedRequested: entry => root\.executePinned\(entry\)' \
  'onActionRequested: action => root\.executeAction\(action\)' \
  'results: root\.results' \
  'selectedIndex: selection\.currentIndex' \
  'onSelectionHovered: index => selection\.select\(index\)'; do
  grep -Eq "$contract" "$launcher" \
    || fail "Launcher coordinator lost wiring contract: $contract"
done

# Search execution and mode-prefix semantics remain owned by the coordinator.
for contract in \
  'RaohaneSearch\.results\.slice\(0, 8\)' \
  'RaohaneSearch\.actionResults\(""\)\.slice\(0, 6\)' \
  'function stripMode\(value\): string' \
  'value\.startsWith\("/"\)' \
  'value\.startsWith\(">"\)' \
  'value\.startsWith\(":"\)' \
  'value\.startsWith\("="\)' \
  'function executeSelected\(\): void' \
  'function executePinned\(entry\): void' \
  'function executeAction\(action\): void' \
  'result\.execute\(\)' \
  'action\.execute\(\)' \
  'RaohaneSearch\.executeApplication\(entry\)'; do
  grep -Eq "$contract" "$launcher" \
    || fail "Launcher lost coordinator/search execution contract: $contract"
done

printf 'launcher-boundary-audit: extracted SearchBar/ModeBar/IdleContent/ResultsView/Footer remain presentation-only while query, selection and execution stay coordinator-owned\n'
