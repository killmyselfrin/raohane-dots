# Raohane architecture

Raohane is a Hyprland + Quickshell shell migrating toward a fully standalone architecture. end4-pC / illogical-impulse and other shell projects are temporary migration/reference sources, not permanent Raohane dependencies.

## Target architecture

The final production graph is intended to be Raohane-owned end to end:

```text
Hyprland / Wayland / D-Bus / PipeWire / MPRIS
                    ↓
            Raohane services/
                    ↓
        Raohane Config + runtime state
                    ↓
          Raohane common framework
                    ↓
            Raohane product UI
                    ↓
               shell.qml
```

No other shell repository should be required at runtime, install time, update time or normal development time.

See `INDEPENDENCE-PLAN.md` for the removal criteria.

## Current migration boundary

- `modules/raohane/` — Raohane-owned product UI and product-specific runtime state.
- `services/` — currently contains inherited/migration service implementations; these are scheduled to be replaced behind stable Raohane service interfaces.
- `modules/common/` — currently contains shared inherited configuration/widgets/models/utilities; this layer is also scheduled for ownership migration.
- `modules/ii/` — compatibility UI only. Production Raohane must eventually have zero active imports from this namespace.
- `panelFamilies/RaohaneFamily.qml` — current composition boundary during migration.

The current foundation synchronizer exists only as migration scaffolding. It must disappear after active Raohane code no longer relies on inherited graph updates.

## Active Raohane-native surfaces

- `RaohaneBar.qml` — active horizontal bar shell over current workspace, tray and system providers.
- `RaohaneContext.qml` / `RaohaneContextIsland.qml` — adaptive context state and center presentation backed by MPRIS, active-window and PipeWire privacy state.
- `RaohaneLauncher.qml` — active launcher over the current search provider.
- `RaohaneControlCenter.qml` — active control center using Raohane-owned quick controls and notification center.
- `RaohaneNotificationCard.qml` — shared notification presentation used by popup and notification center.
- `RaohaneSettings.qml` / `RaohaneSettingsContent.qml` — Raohane-owned Settings window/navigation shell.
- `RaohaneSettingsHome.qml` — Raohane Control Deck landing page.
- `RaohaneMediaOverlay.qml` — floating media overlay for games/apps.
- `RaohaneOsd.qml` — active volume, brightness and gamma OSD.
- `RaohaneNotificationPopup.qml` — active notification popup.
- `RaohaneWallpaperSelector.qml` — native wallpaper browser with preview, history, search, random selection and lock-screen target handling.
- `RaohaneDesktopMenu.qml` — native desktop context menu.
- `RaohaneSession.qml` — native session/power menu over current system action providers.
- `RaohanePrivacy.qml` — PipeWire capture-state provider for microphone, camera and screen capture context.
- `RaohaneState.qml` — Raohane-owned ephemeral state.

## Compatibility surfaces still active

The following still rely on inherited UI or infrastructure and are migration targets:

- vertical bar
- workspace overview/window presentation
- background renderer and desktop widget canvas
- dock and lock screen
- capture/region selector, screen translator and supporting overlay tools
- polkit, on-screen keyboard, left sidebar and supporting panels
- compatibility media controls while the native overlay is runtime-tested
- heavy Settings page implementations

The wallpaper selector, desktop context menu and session screen are no longer compatibility UI; only their current service/backend dependencies remain to be replaced.

## Service ownership rule

Raohane UI should depend on stable Raohane-facing service contracts, never directly on an upstream shell module. During migration an inherited implementation may temporarily sit behind that contract. The implementation can then be rewritten without another UI redesign.

Priority service migrations:

1. compositor/workspace/window state;
2. MPRIS/media;
3. audio/PipeWire;
4. network/Bluetooth;
5. brightness/gamma;
6. notifications;
7. wallpapers/thumbnails;
8. session/idle/system info;
9. clipboard/capture/translation and optional online services.

## Runtime

`shell.qml` is the root Quickshell configuration. Raohane's product runtime is Hyprland-only.

`GlobalStates.qml` is currently inherited cross-surface state; Raohane-only state already lives in `modules/raohane/RaohaneState.qml`. A standalone Raohane state store is a required later migration.

Persistent settings are already written under `~/.config/raohane/config.json`, but the schema/serialization implementation is still largely inherited. Raohane must eventually own the schema and migration logic itself.

## Installation and dependencies

The installer writes an isolated `~/.config/hypr/raohane.conf`, exposes the `raohane` CLI and installs the `raohane.service` user service.

The current `./install-raohane.sh --deps` path still uses the illogical-impulse dependency bootstrap. This is explicitly temporary. The target installer uses a Raohane-owned dependency manifest grouped into required, feature-specific and optional packages, with `raohane doctor deps` reporting capability gaps.

Useful product commands include:

```bash
raohane launcher
raohane control
raohane settings
raohane media
raohane desktop
raohane wallpaper
raohane wallpaper random
raohane session
```

Diagnostics are exposed through `raohane doctor all`, `raohane doctor deps`, `raohane doctor services` and `raohane doctor graphics`.

## Removal gates

A migration component can be removed only after its Raohane replacement passes a real Hyprland + Quickshell runtime test. Final standalone cleanup includes:

- no active `modules/ii` imports;
- no `ii-upstream` fallback;
- no end4 synchronization script;
- no upstream source lock files used for runtime development;
- no illogical-impulse dependency bootstrap;
- no inherited Config/common/service implementation still required by production runtime;
- CI validating only Raohane-owned graph.

## Runtime verification boundary

Static CI validates shell scripts, QML parsing, module registration/import structure and product boundaries. It cannot prove compositor behavior.

A migration batch is not runtime-complete until tested in a real Hyprland + Quickshell session for shell startup, multi-monitor behavior, focus/input, launcher execution, notification actions, OSD triggers, media/fullscreen behavior, settings, wallpaper operations, desktop menu placement, session actions and system-service regressions.

See `NOTICE-UPSTREAM.md` for retained code provenance/licensing notes and `INDEPENDENCE-PLAN.md` for the standalone migration plan.
