#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() { printf 'welcome-boundary-audit: %s\n' "$*" >&2; exit 1; }

welcome='modules/raohane/RaohaneWelcome.qml'
state='modules/raohane/RaohaneOnboardingState.qml'
mascot='assets/images/welcome-mascot.svg'
credit='assets/images/WELCOME-MASCOT.md'
translations='translations/raohane/ru_RU_welcome_mascot.json'

for path in "$welcome" "$state" "$mascot" "$credit" "$translations"; do
  [[ -s "$path" ]] || fail "missing Welcome file: $path"
done

for expected in \
  'Quickshell.shellPath("assets/images/welcome-mascot.svg")' \
  'activeFocusOnTab: true' \
  'if (!panelWindow.visible || !RaohaneState.welcomeOpen)' \
  'if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter)' \
  'RaohaneOnboardingState.start()' \
  'onTriggered: root.skipWelcome()' \
  'root.compactLayout'; do
  rg -Fq "$expected" "$welcome" || fail "Welcome lost contract: $expected"
done
if rg -n 'id: shellPreview|component PreviewTile:|component PreviewPod:|Qt.formatTime\(new Date\(\)' "$welcome"; then
  fail 'Welcome still displays a fake dashboard or abandoned preview components'
fi
rg -Fq 'if (!root.ready || root.completed || root.active || RaohaneState.screenLocked)' "$state" \
  || fail 'Welcome launch does not re-check completion/locked state inside deferred callback'
rg -Fq 'RaohaneState.setPrimaryOpen("welcome", true)' "$state" \
  || fail 'Welcome open route was lost'
rg -Fq 'assets "$runtime/"' scripts/runtime-payload-audit.sh \
  || fail 'mascot might be omitted from installed shell payload'

# The mascot remains a small static SVG with no remote dependencies or script.
if rg -ni '<script\b|<foreignObject\b|<image\b|(?:xlink:)?href=["\x27]https?://' "$mascot"; then
  fail 'mascot SVG embeds executable or remote content'
fi
rg -Fq 'CC0' "$credit" || fail 'missing licence attribution'
python3 - "$translations" <<'PY'
import json, sys
path = sys.argv[1]
d = json.load(open(path, encoding="utf-8"))
for key in (
    "A quieter place to create",
    "Everything you need, beautifully within reach. Take a short tour or make Raohane your own.",
    "Ready when you are",
    "Made for Hyprland",
    "Make yourself at home",
    "Your desktop, your atmosphere",
):
    assert d.get(key), f"Missing translation for {key}"
PY

printf 'welcome-boundary-audit: mascot, launch lifetime, compact layout, keyboard actions, provenance and translation contracts valid\n'
