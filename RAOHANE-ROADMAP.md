# Raohane Roadmap

This file tracks product-level work that should survive beyond the current standalone/release cleanup.

## Expanded media player

Goal: turn the current media overlay into a full Raohane media surface that can be opened from a compositor shortcut without leaving a fullscreen/game workflow.

Planned capabilities:

- Dedicated global shortcut and IPC target for the expanded player.
- Large album-art view with smooth enter/exit, track-change and progress animations.
- MPRIS-backed transport controls: previous, play/pause, next, seek and player selection.
- Volume/output controls without duplicating the system audio service.
- Raohane-owned equalizer UI, initially targeting an 8-band layout.
- Equalizer backend through PipeWire/EasyEffects rather than shell-specific legacy services.
- Presets, reset/bypass and per-band gain feedback.
- Optional audio-reactive visualization, implemented so it can be disabled completely for fullscreen/game performance.
- Compact mode and expanded mode should share one media service/state model.

## Lyrics

The expanded player should expose a small lyrics affordance near an edge/corner instead of forcing lyrics into the main layout.

Planned behavior:

- Lyrics button opens a dedicated lyrics layer/panel.
- Support synchronized lyrics when timing data exists and plain lyrics as a fallback.
- Current line emphasis and smooth line-to-line motion.
- Manual offset correction for badly synchronized tracks.
- Lyrics panel can be pinned, click-through, moved to another monitor, or hidden independently of the expanded player.
- Lyrics lookup/cache must be separate from playback state so loss of network access does not break the player.

## Private lyrics while streaming

Desired user experience: lyrics remain visible locally while a stream/screen-share does not expose them.

Hyprland currently provides `no_screen_share` for both regular windows and layer-shell namespaces. Raohane can therefore give the lyrics overlay its own namespace and apply a capture-protection layer rule.

Important capture behavior:

- When a specific game/application window is shared, a separate Raohane lyrics layer is not part of that window capture. This is the preferred private-lyrics mode because viewers see the original application without a lyrics overlay.
- When the entire monitor/output is shared, Hyprland's `no_screen_share` protection intentionally replaces the protected layer area in the capture instead of revealing the pixels underneath it. This protects the text, but can appear as a black protected region to viewers.
- For full-monitor sharing Raohane should therefore offer policies such as: `protected`, `auto-hide`, or `move-to-private-monitor` when a second display exists.
- The player itself and the lyrics layer must use different namespaces so only lyrics can be protected while the media controls remain shareable if desired.

## Theme engine

Theme switching is a required product feature, but Raohane should not stop at a generic preset picker. The theme system should keep the Japanese/living Raohane identity while supporting deep customization.

Planned capabilities:

- Native Settings page for live theme switching with no shell restart.
- Light, dark and auto modes.
- Raohane-owned presets plus user-defined presets.
- Wallpaper palette extraction as an optional source, not the only source of truth.
- Independent accent, surface, text, border, glow and danger colors.
- Blur/transparency intensity, corner radius, border treatment and animation personality as theme-level tokens.
- Per-surface overrides for bar, dock, launcher, control center, settings, media and overlays.
- Theme import/export using a documented Raohane JSON schema.
- Preview mode that can be cancelled without permanently writing config.
- Optional external-app theming must remain modular and opt-in rather than silently rewriting unrelated application configs.

### Living themes

A Raohane-specific extension should allow a theme to evolve without looking random or distracting:

- Optional time-of-day variants such as dawn/day/evening/night.
- Optional album-art accent while the expanded media player is active.
- Optional workspace-specific accent identity.
- Smooth palette transitions instead of instant global color jumps.
- A strict low-motion/game mode that freezes dynamic theme work while fullscreen applications are active.

## Raohane Task Manager

Goal: build a native application/resource control surface rather than a QML clone of a terminal process list.

Planned capabilities:

- Group Linux processes into recognizable applications where possible instead of showing only raw PIDs.
- Search and sort by application, CPU, RAM, GPU, VRAM and network activity.
- Expand an application into its process tree.
- CPU/RAM history sparklines with bounded sampling so the shell does not become the resource problem it is measuring.
- NVIDIA GPU/VRAM metrics through supported runtime probes, with AMD/Intel paths kept separate and optional.
- Per-application network throughput when a reliable lightweight source is available.
- Actions: graceful terminate, force kill, freeze/resume, change process priority and open application details.
- Clear warnings before destructive actions; never silently kill system-critical processes.
- Highlight runaway applications and unexpected background resource use.
- Compact system HUD mode for games, with the full manager opened only on demand.
- No privileged daemon should be required for normal read-only monitoring.

### Resource intelligence

Raohane can differentiate the task manager with higher-level summaries:

- Explain which application is currently responsible for the largest CPU/RAM/GPU load.
- Detect sudden sustained spikes rather than reacting to one sample.
- Show a lightweight `game pressure` indicator combining GPU, VRAM, CPU and memory pressure.
- Optional recommendations such as closing a heavy background application, without automatically killing anything.

## Signature Raohane features

These are candidate features that should make the shell feel like a coherent product instead of a collection of common Hyprland widgets.

### Raohane Scenes

A Scene is a user-selectable or context-triggered desktop state. One action can coordinate theme, wallpaper, bar/dock behavior, audio profile, equalizer preset, notification policy, privacy overlays and performance behavior.

Initial scene ideas:

- `Normal` — everyday desktop behavior.
- `Game` — low-motion UI, suppressed persistent panels, lightweight HUD and game-friendly media overlay.
- `Stream` — capture-aware notifications/lyrics/translator/private layers and safe overlay policies.
- `Focus` — minimal shell, reduced notifications and selected workspace layout.
- `Night` — warmer display, quieter theme and reduced visual intensity.

Scenes should be manually selectable first. Automatic activation can later use fullscreen application, active workspace, screen sharing or user-defined application rules.

### Private UI plane

Extend the private-lyrics concept into a Raohane-wide privacy layer:

- Lyrics, private notes, clipboard previews, translations and selected notifications can opt into capture protection.
- Surfaces must show an explicit local indicator when protection is active.
- Stream mode can hide or relocate private surfaces depending on whether a window, monitor or another output is being captured.
- Privacy behavior should be driven by RaohanePrivacy/PipeWire state and compositor rules, not by per-application hacks.

### Fullscreen command deck

Build one game-safe command deck that is intentionally useful while another fullscreen application owns the desktop:

- Media and equalizer.
- Volume/output/microphone controls.
- Performance HUD and Task Manager shortcut.
- Screen translator/OCR.
- Private lyrics and notes.
- Quick scene switching.
- Recording controls.

The deck must avoid keyboard focus unless explicitly requested and should have a minimal click-through/peek mode.

### Workspace memory

Let workspaces carry identity instead of being anonymous numbers:

- Optional names/icons/colors for workspaces.
- Remember a workspace's preferred Scene and visual accent.
- Later, optionally restore a user-defined application/workspace arrangement without pretending arbitrary application state can always be reconstructed perfectly.

### Context Island evolution

Keep Context Island as a Raohane signature surface rather than a generic status pill. It should surface only short-lived context that benefits from immediate attention, for example:

- media track transition;
- microphone/camera/screen-share privacy state;
- recording state;
- device connect/disconnect;
- scene changes;
- copy/translation completion;
- temporary resource warning.

It should not become a second notification center.

## Product differentiation rule

Before adding a large feature, classify it as one of:

1. **Foundation** — expected desktop-shell functionality such as settings, themes, task management, notifications and wallpaper controls.
2. **Raohane signature** — functionality whose behavior is meaningfully different because it integrates multiple Raohane systems, such as Scenes, private UI, fullscreen command deck or context-aware overlays.

Foundation features should be polished and complete, but product identity should come from signature features rather than adding more copies of common widgets.

## Implementation boundary

Do not build this on top of retired `modules/common`, `modules/ii`, old media-control aliases, or upstream shell services. New work belongs under `modules/raohane` and should reuse the native RaohaneMedia/RaohaneAudio/RaohaneEasyEffects services where appropriate.

Before considering the expanded media/private-lyrics feature complete, validate:

- normal desktop playback;
- fullscreen/game overlay behavior;
- NVIDIA fullscreen performance;
- multi-monitor placement;
- player switching;
- synchronized and unsynchronized lyrics;
- specific-window streaming;
- full-monitor streaming with each private-lyrics policy;
- capture behavior through xdg-desktop-portal-hyprland/PipeWire.

Before considering Theme Engine or Task Manager complete, validate:

- clean-install defaults and schema migration;
- no restart required for ordinary theme changes;
- bounded idle CPU/memory overhead;
- multi-monitor behavior;
- NVIDIA/AMD/Intel graceful capability detection;
- safe process-control UX;
- fullscreen/game performance with monitoring surfaces hidden;
- failure behavior when an optional backend is unavailable.
