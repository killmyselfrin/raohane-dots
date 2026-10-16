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
  'RaohanePaths.join(RaohanePaths.assetsPath, "images/welcome-mascot.svg")' \
  'source: root.mascotUrl' \
  'visible: root.compactLayout' \
  'function startTour(): void' \
  'RaohaneOnboardingState.skip()' \
  'z: 150' \
  'preventStealing: true' \
  'activeFocusOnTab: true' \
  'if (!panelWindow.visible || !RaohaneState.welcomeOpen)' \
  'if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter)' \
  'RaohaneOnboardingState.start()' \
  'onTriggered: root.skipWelcome()' \
  'root.compactLayout' \
  'RaohaneI18n.languageChosen' \
  '!RaohaneI18n.pickerOpen'; do
  rg -Fq "$expected" "$welcome" || fail "Welcome lost contract: $expected"
done
if rg -n 'id: shellPreview|component PreviewTile:|component PreviewPod:|Qt.formatTime\(new Date\(\)' "$welcome"; then
  fail 'Welcome still displays a fake dashboard or abandoned preview components'
fi
rg -Fq 'if (!root.ready || root.completed || root.active || RaohaneState.screenLocked)' "$state" \
  || fail 'Welcome launch does not re-check completion/locked state inside deferred callback'
rg -Fq 'RaohaneState.setPrimaryOpen("welcome", true)' "$state" \
  || fail 'Welcome open route was lost'

# The source action must finish updating state before the lazy Welcome
# component is allowed to unload. The old order dropped user clicks.
python3 - "$state" <<'PY'
import pathlib, re, sys
src = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
def body(name):
    m = re.search(r"function " + name + r"\([^)]*\): void \{([\s\S]*?)\n    \}", src)
    assert m, "Missing onboarding function " + name
    return m.group(1)
start = body("start")
assert start.index("root.active = true") < start.index("root.applyStep()"), "Tour must activate before closing Welcome"
assert 'setPrimaryOpen("welcome", false)' not in start, "Tour must not eagerly destroy its caller"
complete = body("complete")
assert complete.index("root.markCompleted()") < complete.index("root.closeTourSurfaces()"), "Completion must persist before closing Welcome"
assert "if (root.completed && !root.active)" not in complete, "Skip must also dismiss explicitly reopened Welcome"
PY
rg -Uq '"welcome":[[:space:]]*\{[^}]*deferredUnload:[[:space:]]*true' modules/raohane/RaohaneSurfaceRegistry.qml \
  || fail 'Welcome buttons can be destroyed before click callbacks finish'

rg -Fq 'assets "$runtime/"' scripts/runtime-payload-audit.sh \
  || fail 'mascot might be omitted from installed shell payload'

# The mascot remains a small static SVG with no remote dependencies or script.
if rg -ni '<script\b|<foreignObject\b|<image\b|(?:xlink:)?href=["\x27]https?://' "$mascot"; then
  fail 'mascot SVG embeds executable or remote content'
fi
# The previous asset was silently truncated mid-path, which SVG viewers
# rejected without a QML parse failure. Parse the entire SVG in CI.
python3 - "$mascot" <<'PY'
import sys
import xml.etree.ElementTree as ET

try:
    root = ET.parse(sys.argv[1]).getroot()
except ET.ParseError as error:
    raise SystemExit(f"Invalid Welcome mascot SVG: {error}")
assert root.tag == "{http://www.w3.org/2000/svg}svg", "Mascot root is not SVG"
assert root.attrib.get("viewBox"), "Mascot is missing viewBox"
paths = sum(1 for node in root.iter() if node.tag == "{http://www.w3.org/2000/svg}path")
assert paths >= 20, f"Welcome mascot appears incomplete: only {paths} paths"
PY

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
