# Welcome and desktop widget visual update

The Welcome screen now uses a centered Raohane mark, a short introduction,
and a navigation rail with direct routes to Themes and Desktop Widgets.
At smaller sizes the rail collapses, keeping the tour and skip actions visible.
Buttons size to their labels, including Russian translations.
The bundled logo replaces the optional missing Welcome PNG.

The Classic clock face combines a static analog dial with a digital time and
localized date. Both use the existing minute timer, gated by visibility.
The Classic media/context card uses larger artwork, clearer track hierarchy,
and capability-gated Previous, Play/Pause and Next controls on RaohaneMedia.
Existing widget IDs, layout data and alternative face selections are preserved.
The Raohane dark preset now uses cooler graphite surfaces with lavender focus
and selection accents through the shared theme tokens.

Visual reference: `ilyamiro/serpantinum`, master at
`89468d311f77d4bedbc53a2a4e2e13f836b04cbb`, particularly its centered guide
welcome and distinct clock/media faces. This implementation uses Raohane-owned
components, services and the existing local logo; no upstream source or assets
were transplanted.

## Checks performed

- Parsed the changed QML and the top-level shell components with Qt 6 qmlformat.
- `bash scripts/welcome-boundary-audit.sh`: passed, including keyboard action,
  deferred-unload, local logo, Settings routes and loaded translation contracts.
- `bash scripts/theme-library-audit.sh`: passed.
- `bash scripts/qmldir-boundary-audit.sh`: passed.
- `bash scripts/runtime-payload-audit.sh`: passed.
- `bash scripts/source-lineage-audit.sh`: passed.
- `bash -n scripts/welcome-boundary-audit.sh` and `git diff --check`: passed.
- Opened Welcome at 1920×1080 and 800×600, scale 1, using Quickshell 0.3.2,
  Qt 6.11.2 and a virtual Sway/pixman output with Qt software rendering.
  Captured dark and Paper theme screenshots; restored the original test preset.
- Started and skipped the existing tour through IPC and confirmed its open/closed
  state. The Welcome tour IPC route invokes the same guarded action as its button.
- A local test MPRIS player exposed title, artist, artwork and duration in the
  media card. IPC calls through the existing RaohaneMedia API delivered Pause,
  Next and Previous to that player. This checks the service path; physical
  pointer/keyboard activation still needs a real compositor session.
- The existing runtime smoke validator passed in the active diagnostic container.

The umbrella `bash scripts/raohane-audit.sh` still fails on the existing
`desktop-widget-boundary-audit.sh` assertion requiring
`source: root.definition?.source`, while the host uses registry-based face
selection. That unrelated baseline assertion was not changed to hide the failure.
GitHub PR/Actions inspection was unavailable because the API returned HTTP 403.

## Remaining live checks

Hyprland cannot initialize Aquamarine on this cloud machine without `/dev/dri`.
The virtual output verifies QML rendering and layout, not Hyprland focus,
global shortcuts, input routing, GPU effects, mixed-DPI or fullscreen behavior.
Validate those on a target Hyprland session before release. Previously observed
fresh-container RaohanePrivacy binding warnings remain a separate baseline issue.

In a target session, exercise Enter/Esc, Tab/Space activation, both Settings
shortcuts, start/skip/replay and persistence after restart. Check the media
buttons against a real player, then reopen Widget Studio and verify Classic,
Minimal and Aurora selections survive restart. Inspect logs and run
`raohane validate smoke`; do not substitute static checks for these live gates.
