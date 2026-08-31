# Raohane roadmap

Raohane is no longer in a framework-migration phase. The active shell, services, configuration, visible runtime and release packaging are Raohane-owned.

This roadmap therefore separates **0.10 completion gates** from later product expansion. A future idea is not automatically a blocker for the first standalone release.

## 0.10.0 — standalone release target

### Source and architecture

- [x] Standalone Quickshell bootstrap and `RaohaneFamily` composition.
- [x] Raohane-owned service graph for media, audio, network, Bluetooth, display, notifications, wallpapers, session, search, privacy and system information.
- [x] Raohane-owned persisted configuration and path APIs.
- [x] Remove active `modules/ii`, `modules/common` and inherited root-service runtime dependencies.
- [x] Deterministic installed-runtime pruning and payload validation.
- [x] Source-lineage/license boundary and deterministic source packaging.

### Desktop shell

- [x] Horizontal and vertical Bar.
- [x] Context Island.
- [x] Native workspaces / Spaces overview.
- [x] Native application Dock.
- [x] Launcher with application, action, command, calculator and clipboard modes.
- [x] Control Center and Quick Controls.
- [x] Notifications, history and actions.
- [x] Wallpaper selector with image/video background path.
- [x] Desktop canvas and context menu.
- [x] OSD, screen frame and screen corners.
- [x] Session / power screen.
- [x] Native WlSessionLock + PAM + optional fingerprint flow.
- [x] Native Polkit prompt.
- [x] Native on-screen keyboard.
- [x] Screen capture, OCR, image-search handoff and recording.
- [x] Screen translator.
- [x] DropShelf and left Sidebar.

### Visual system

- [x] Shared minimalist `RaohaneTheme` token system.
- [x] `Zen Mist` default plus Paper, Sakura, Matcha, Slate, Sand, Sumi and Midnight presets.
- [x] Live Theme Library.
- [x] Persisted Style Studio controls for glass, borders, radius, density, motion and accent.
- [x] Advanced surface controls for Bar, Dock, Context Island and notifications.
- [x] Unified minimalist treatment for shell, auth/system and utility surfaces.
- [x] Visual regression audit preventing retired cyber-noir/hardcoded chrome from returning.

### Media

- [x] Native Quickshell MPRIS service.
- [x] Expanded fullscreen-friendly media surface.
- [x] Multiple-player selection.
- [x] Seek, previous/next, play/pause, replay/forward and volume controls.
- [x] Compact Context Island media interactions.
- [x] Synchronized LRC and plain-lyrics UI.
- [x] Current-line tracking and seek-on-line-click.
- [x] Raohane-owned LRCLIB resolver separated from QML networking.
- [ ] Confirm lyrics lookup/synchronization against real browser + native MPRIS players on the installed shell.
- [ ] Confirm media overlay interaction over at least one real fullscreen/game workload.

### Native Task Manager

- [x] Replace the external terminal `btop/htop/top` fallback with a Raohane-native surface.
- [x] Current-user process snapshots and application grouping.
- [x] CPU / RAM sorting, search and per-process details.
- [x] Graceful terminate and explicit two-step force-stop actions.
- [x] Poll only while the Task Manager is visible.
- [x] Integrate with Session, Launcher, IPC and the fullscreen Command Deck.
- [ ] Confirm live process refresh and TERM/KILL UX on the installed shell.

### Fullscreen Command Deck

- [x] Native overlay surface with isolated compositor namespace.
- [x] Launcher, Control Center, Media, Task Manager, Translator, OSK, Settings and Session entry points.
- [x] Audio and privacy context.
- [x] Unified minimalist Material-symbol presentation.
- [ ] Confirm focus/interaction behavior in a real fullscreen application.

### Installation and diagnostics

- [x] Raohane-owned Arch required/feature manifests.
- [x] Independent dependency installer.
- [x] No silent GPU-driver installation/replacement.
- [x] Native runtime doctor commands.
- [x] Phase-4 live validator.
- [x] Full release live validator and report output.
- [x] Release archive + SHA-256 generation in CI.

## 0.10 release gates that require real hardware

Static CI cannot truthfully close these items. A stable release requires live evidence as documented in [`RELEASE-VALIDATION.md`](RELEASE-VALIDATION.md).

- [ ] Fresh Arch + Hyprland install from the release candidate.
- [ ] Password unlock through the real WlSessionLock/PAM path.
- [ ] Fingerprint behavior on hardware with configured fingerprints.
- [ ] NVIDIA render/fullscreen validation.
- [ ] AMD or Intel render validation.
- [ ] Multi-monitor placement/focus validation on at least two active outputs.
- [ ] Horizontal and vertical Bar validation in normal and fullscreen states.
- [ ] Dock autohide/reveal and Overview focus behavior on a real compositor.
- [ ] Capture/OCR/translation/recording interactive pass.
- [ ] OSK and DropShelf interactive pass.
- [ ] Media + lyrics pass with real MPRIS players.
- [ ] Fullscreen/game Command Deck and Media Overlay pass.

Run the complete installed release sequence with:

```bash
raohane validate release --full
```

A machine that cannot exercise a capability should report it as partial/unsupported rather than marking it passed.

---

# After 0.10

The following are product-expansion ideas. They are valuable, but they do **not** prevent Raohane 0.10 from being a complete standalone desktop shell.

## 0.11 — personalization and media depth

Candidate work:

- User-defined theme presets.
- Theme import/export with a documented Raohane JSON format.
- Preview/revert transactions for theme editing.
- Optional wallpaper palette extraction.
- Light/dark/auto policy independent of preset selection.
- Per-surface theme overrides where they add real value.
- Optional lyrics offset adjustment.
- Optional detachable/private lyrics surface.
- Optional EasyEffects equalizer controls inside Media.
- Optional low-cost audio visualization that fully disables in game/low-motion mode.

## 0.12 — Scenes and private UI

### Scenes

A Scene coordinates several existing Raohane systems through one user-selected state. Possible initial scenes:

- `Normal`
- `Game`
- `Stream`
- `Focus`
- `Night`

A Scene may coordinate theme, wallpaper, bar/dock behavior, audio/equalizer profile, notification policy and performance behavior. Manual activation should come before automatic rules.

### Private UI plane

Capture-aware privacy can later expand beyond lyrics:

- private lyrics;
- notes;
- clipboard previews;
- translations;
- selected notifications.

Protection must be explicit in the local UI and driven through Raohane privacy/compositor state rather than per-application hacks.

For full-output sharing, protected surfaces may need `protected`, `auto-hide` or `move-to-private-monitor` policies because compositor capture protection can obscure the protected region rather than reveal pixels underneath it.

## 0.13 — Task Manager depth and workspace memory

The 0.10 Task Manager intentionally prioritizes safe, lightweight user-process control. Later versions may add capability-specific metrics without turning the shell into the workload it measures:

- CPU/RAM history sparklines with bounded sampling;
- application/process trees;
- NVIDIA GPU/VRAM metrics;
- separate AMD/Intel metric paths;
- optional per-application network throughput;
- freeze/resume and priority controls;
- sustained-spike detection and a lightweight game-pressure indicator.

Workspace memory may later add names/icons, Scene association and user-defined application/workspace restoration rules.

## Context Island evolution

Context Island should remain a short-lived contextual surface, not a second Notification Center. Appropriate future events include:

- media transitions;
- microphone/camera/screen-share state;
- recording state;
- device connect/disconnect;
- Scene changes;
- copy/translation completion;
- temporary resource warnings.

## Product rule

New large work should be classified before implementation:

1. **Foundation** — functionality expected from a complete desktop shell.
2. **Raohane signature** — functionality differentiated by integration between Raohane systems.

0.10 closes the standalone foundation. Later releases should deepen Raohane's identity without reopening retired compatibility architecture or treating every brainstorm as a release blocker.
