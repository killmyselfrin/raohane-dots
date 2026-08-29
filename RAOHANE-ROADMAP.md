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

## Implementation boundary

Do not build this on top of retired `modules/common`, `modules/ii`, old media-control aliases, or upstream shell services. New work belongs under `modules/raohane` and should reuse the native RaohaneMedia/RaohaneAudio/RaohaneEasyEffects services where appropriate.

Before considering the feature complete, validate:

- normal desktop playback;
- fullscreen/game overlay behavior;
- NVIDIA fullscreen performance;
- multi-monitor placement;
- player switching;
- synchronized and unsynchronized lyrics;
- specific-window streaming;
- full-monitor streaming with each private-lyrics policy;
- capture behavior through xdg-desktop-portal-hyprland/PipeWire.
