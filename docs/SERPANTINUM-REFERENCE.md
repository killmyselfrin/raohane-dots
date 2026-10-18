# Serpantinum reference study — Raohane widget roadmap

> Research snapshot: 2026-10-18. This is a design and implementation study, not a claim that the new features are shipped or runtime-tested.

## Sources and boundaries

- Reference: [ilyamiro/serpantinum](https://github.com/ilyamiro/serpantinum), specifically `src/quickshell/Shell.qml`, `widgets/WidgetRegistry.qml`, `widgets/Widget.qml`, `widgets/WidgetLoader.qml`, `widgets/WidgetRedactor.qml`, `bar/Bar.qml`, `syspanel/SystemPanel.qml`, and `popouts/SideMusicPopout.qml`.
- Raohane baseline: `docs/ARCHITECTURE.md`, `docs/ROADMAP.md`, `modules/raohane/RaohaneDesktopWidgetRegistry.qml`, `RaohaneDesktopWidgets.qml`, `RaohaneDesktopWidgetLayoutStudio.qml`, `RaohaneWidgetStudio.qml`, `RaohaneBarModuleRegistry.qml`, `RaohaneMediaStudio.qml`, `RaohaneControlCenter.qml`, and `RaohaneMotion.qml`.
- Serpantinum's upstream code is AGPL-3.0; Raohane is GPL-3.0. This document describes product behavior and architecture, **not a license to paste upstream QML or assets**. Design and implement independently; assess licensing and attribution before any deliberate reuse.

## Verified functional comparison

| Area | Serpantinum implementation | Raohane baseline | Action |
| --- | --- | --- | --- |
| Widget catalog | `WidgetRegistry.qml` declares 12 types: visualizer, time, music, weather, image, user, CPU, RAM, temperature, disk, battery, GitHub. Several have multiple variants. | Four native types: clock, context, system, motto. | Extend catalog with individually testable native widgets and variants; retain existing IDs. |
| Layout | `WidgetLoader.qml` maintains independent widget records per monitor: ID, type, variant, X/Y, width/height, opacity, rotation, image path, stretch and custom props. | Two ordered rails (`primary`, `secondary`), three layout presets (`balanced`, `left`, `right`). | Add an *optional* free-layout mode; preserve rail mode and migrate without data loss. |
| Editor | `WidgetRedactor.qml` supports selection, add/remove, geometry, custom properties and grid snapping, synchronized with the loader. | `RaohaneDesktopWidgetLayoutStudio.qml` reorders and moves widgets between rails; `RaohaneWidgetStudio.qml` exposes global toggles. | Build a dedicated canvas editor with drag/resize handles, alignment guides, keyboard nudges, inspector and undo/reset. |
| Music | Four desktop music faces (`full`, `round`, `lyrics`, `simpleLyrics`), a side MPRIS music popout and visualizer. | Native MPRIS/media overlay, Media Studio, HUD, desktop context widget and lyrics. | Reuse RaohaneMedia as one service; add multiple faces instead of a second playback backend. |
| Bar | Distinct `modular`, `solid`, `fill` render modes, plus module/group layout and transitions. | Horizontal/vertical Bar and Bar Studio, composable module registry. | Add visual presets and live previews to current Bar Studio; do not introduce a second Bar. |
| System panel | Composed from `SystemPanelSliders`, `SystemPanelQuickActions`, `SystemPanelPowerActions`, with staggered open/close behavior. | Modular Control Center, Quick Controls and shared Motion tokens. | Improve composition and transition choreography without adding duplicate controls. |
| Runtime gating | `Shell.qml` conditionally loads desktop widgets, wallpaper engine and floating actions when performance mode permits. | Existing `RaohaneMotion`/Game Mode and native services. | Use lazy instantiation and visibility-gated effects; keep polling off for hidden widgets. |

## Raohane implementation proposal

### Phase 0 — stability before scope growth

1. Preserve a single Quickshell runtime and service instance. Fix QML warnings, missing panels on fullscreen exit, focus issues and stale Bluetooth/network/audio state before broad widget expansion.
2. Exercise idle, music, game/fullscreen, monitor hotplug, Settings and Control Center reopen flows using `raohane doctor performance`, `raohane validate smoke`, and real Hyprland logs.
3. Respect reduced-motion, Game Mode and low-power policy. No always-running visualizers or expensive full-screen blur/shaders.

### Phase 1 — native widget schema and compositor

1. Keep current `desktopWidgetComposition` (rail mode) intact. Introduce an opt-in `free` layout rather than silently migrating the current desktop.
2. Extend the **Raohane-owned** schema with stable instance IDs, widget type, variant, monitor identity, normalized logical position, dimensions, opacity, order and type-specific settings. Treat unrecognized types and missing monitors safely.
3. Keep configuration writes mediated by `RaohaneConfig`; debounce and write atomically. Preserve older schema values and supply explicit import/export/reset paths.
4. Use a single shared widget registry to define metadata, variants, bounds, allowed properties and live components. Host each instance through a bounded loader; maintain one data subscription per service.
5. Constrain interactive widget hit regions so the desktop remains usable; define explicit behavior over fullscreen windows and in edit mode.

### Phase 2 — Widget Studio canvas

1. Add a full-screen or windowed editor with widget library, live canvas, grid/snapping, drag/resize, bounded rotation/opacity, layering and an inspector. Support Esc/cancel and reversible reset.
2. Per-monitor layout selection and change handling; account for fractional scaling, monitor rename/disconnect and smaller 1080p viewports.
3. Keyboard-first actions: select, move by arrows, duplicate, remove and undo; high-contrast focus state and reduced-motion support.
4. Shipping acceptance: edits survive restart; widgets do not jump on fractional scaling or block window input; no stale QML binding loops.

### Phase 3 — widget faces in priority order

1. **Clock**: existing Raohane clock plus minimal, analog and typography-focused variants.
2. **Music**: card/compact/cover/lyrics faces connected to `RaohaneMedia`; pause visualizations when hidden or stopped.
3. **System**: compact vs circular CPU/RAM/disk/battery indicators with bounded refresh, capability checks and no fabricated GPU or temperature metrics.
4. **Weather**: opt-in location, explicit data freshness and offline fallback; disabled unless configured.
5. **Image**: local image card with square/rounded/circle options, validation and safe path handling.
6. **Audio visualizer**: opt-in only, stopped when not visible, with measured CPU/GPU use on older NVIDIA hardware.
7. Consider **GitHub activity** later only if there is a clearly maintained backend, authorization/privacy model and user demand.

### Phase 4 — integrated Serpantinum-inspired visual language

- Nocturne stays recognizably Raohane: charcoal/graphite, subtle lavender accents, floating islands, no Japanese text or upstream branding.
- Optional tinted-glass surfaces with a clean solid fallback. Shaders and scene-graph effects must honor performance and reduced-motion policies.
- Unified spacing, edge radii and animation cadence through `RaohaneTheme` / `RaohaneMotion`, not literal timings scattered through widget faces.
- Configure Bar appearance and Control Center through their **existing** settings ownership; do not repeat audio, microphone, Wi-Fi or Bluetooth controls in two locations.

## Architecture decisions and anti-patterns

- **Do not** transplant `WidgetRedactor.qml` as a 2,000+ line monolith; split model/schema, canvas, handles, inspector and face controls.
- **Do not** spawn standalone Quickshell processes per widget, add a second notification server, or maintain two MPRIS/audio stacks.
- **Do not** write monitor-specific JSON from arbitrary QML via shell string interpolation; use existing Raohane paths/config serialization and atomic persistence.
- **Do not** silently change current rails, launcher shortcuts or media behavior for existing users.
- Keep the project neutral-branded and do not introduce Japanese assets, text or labels.

## Validation gates before merge / release

- Static: QML formatting and import checks where available, Raohane source/runtime audit, schema/migration tests, license/attribution review.
- Runtime: fresh and upgraded configs, save/load/rollback, two monitor layouts and fractional scale, full-screen game transitions, locked session, MPRIS player start/stop, device reconnect, latency and CPU/RSS across extended uptime.
- Visual: real screenshots at Full HD and a smaller screen; verify drag handles, focus, typography, glass fallback and border contrasts.
- Do not claim a stable release on GitHub Actions alone. Follow [`RELEASE-VALIDATION.md`](RELEASE-VALIDATION.md).

## Initial implementation queue

1. Finalize P0 session/performance diagnostics from [`ROADMAP.md`](ROADMAP.md).
2. Implement additive free-layout data model, serializer/migration and tests behind a disabled-by-default feature flag.
3. Create editable widget canvas and monitor routing, while retaining existing rail-based Widget Studio.
4. Ship Clock + Music face variants first, then System + Image; add optional extras only after profiling.
5. Polish Control Center transitions and bar face presets using current shared design tokens.

**Status (2026-10-18):** an initial source-level, opt-in free-layout MVP is implemented on `main` with per-monitor placement, preview dragging and resizing; see [validation and rollback](WIDGET-STUDIO-2-VALIDATION.md). It is **not yet live-validated on Hyprland**, and the larger widget catalog, rich face variants and P0 stability gates remain unfinished.
