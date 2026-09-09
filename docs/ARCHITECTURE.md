# Raohane architecture

Raohane is a standalone Hyprland + Quickshell shell with a Raohane-owned production and source runtime graph. Historical end4-pC / illogical-impulse / Serpantinum code is not part of the active runtime graph; retained provenance and licensing notices document derivative history where required.

## Production graph

`shell.qml` loads `panelFamilies/RaohaneFamily.qml`, which composes the shell surfaces. UI components consume shared configuration, registries and service APIs. Services integrate with Hyprland, Wayland, D-Bus, PipeWire, MPRIS, PAM and Polkit.

Production code must not import `modules/common`, `modules/ii`, root `services/`, `GlobalStates`, inherited `Config`, or another shell namespace. Those inherited source trees have been physically removed.

## Repository layout

| Path | Contents |
| --- | --- |
| `shell.qml`, `panelFamilies/` | Entry point and shell composition |
| `modules/raohane/` | UI, configuration, services, models and helpers |
| `defaults/`, `assets/`, `translations/` | Configuration defaults and runtime resources |
| `scripts/` | CLI, backend helpers, diagnostics and checks |
| `install/arch/`, `install-raohane.sh` | Arch dependency manifests and installer |
| `nix/`, `flake.nix` | Nix package and modules |
| `display-manager/`, `login/` | Login themes and session setup |
| `patches/` | Documented dependency fixes |
| `docs/` | Architecture, themes, roadmap and validation guides |

## Bootstrap and module boundary

`shell.qml` is intentionally small. It imports the native Raohane config module, waits for `RaohaneConfig.ready`, then instantiates only `RaohaneFamily`.

The root `qmldir` exports only:

```text
module qs
```

`modules/` contains only `modules/raohane`. `panelFamilies/` contains only `RaohaneFamily.qml`.

Raohane's framework modules are split by responsibility:

```text
modules/raohane/qmldir          UI/state/common widget and registry types
modules/raohane/config/qmldir   persistent config + path API
modules/raohane/services/qmldir backend service singletons
modules/raohane/helpers/qmldir  reusable pure helpers
modules/raohane/models/qmldir   reusable product/UI models
```

Shared visual primitives include `RaohaneSurface`, `RaohaneDivider`, `RaohaneIcon`, `RaohaneIconButton`, `RaohaneSwitch` and `RaohaneSlider`. `RaohaneSelectionModel` and `RaohaneUtils` provide the model/helper layer used by active product surfaces.

## Registries and composition

Runtime composition is declarative where the product benefits from user-editable layouts:

- `RaohaneSurfaceRegistry` owns primary surface identities and lifecycle metadata;
- `RaohaneBarModuleRegistry` owns horizontal/vertical Bar modules and layout recovery;
- `RaohaneSettingsPageRegistry` owns Settings routes, page metadata and generic control schemas;
- `RaohaneSettingsSectionRegistry` owns section-specific Settings extensions;
- `RaohaneQuickControlRegistry` owns Control Center quick-tile identities;
- `RaohaneDesktopWidgetRegistry` owns native desktop widgets.

Visible hosts consume these registries instead of hard-coding product composition wherever persistence or user customization is required.

## Persistent state and product schema

Raohane owns native schema v13 in:

```text
~/.config/raohane/native.json
```

`RaohaneConfig.qml` owns runtime serialization and reload behavior. The current persisted product contract covers wallpaper/lock wallpaper, Overview, Dock, horizontal/vertical Bar composition, Quick Controls composition, desktop widgets and widget layout, Theme Library selection, screen frame/corners, hot-corner behavior, OSK, OSD, display/night-light behavior, helper application commands, profile identity and current feature flags, including normal/Gaming Media Overlay placement and Gaming auto-hide policy. Settings controls resolve into `RaohaneConfig` properties rather than writing files directly from visible UI.

The installer seeds `defaults/native.json`. During upgrades, `scripts/prune-runtime.sh` deep-merges an older native document with current defaults before Quickshell starts, preserving existing values and forward-compatible unknown keys while normalizing the document to schema v13.

The optional `scripts/migrate-legacy-config.py` exists only as an install-time importer for users explicitly migrating supported values from an older shell configuration; it is removed from the installed runtime and is not a runtime dependency.

Ephemeral UI state belongs to `RaohaneState.qml`. Settings navigation state belongs to `RaohaneSettingsRouter`, not to global product state.

User autostart commands live in:

```text
~/.config/raohane/autostart.conf
```

`RaohaneAutostart` runs them once per Hyprland session, not on every shell restart.

## Paths and directories

`RaohanePaths.qml` is the single path-resolution contract for active product code. It owns XDG config/state/cache roots, Raohane runtime directories, capture temporary data, wallpaper thumbnails, cover art, screenshots, recordings, assets, scripts, defaults and user theme storage.

Active services should consume `RaohanePaths` rather than reconstructing XDG paths locally. The retired compatibility config path is not exposed by the production path API.

## Settings architecture

Settings is one routed workspace:

`RaohaneSettingsPageRegistry` defines routes and `RaohaneSettingsRouter` selects the current page. `RaohaneSettingsContentV3` composes navigation, the header and the page loader. Generic and specialized pages use shared controls and persist changes through `RaohaneConfig`.

Keyboard & Motion, Backup & Restore and Language are normal registry-backed Settings pages. Generic section pages do not own section-specific editors; those are routed through the section extension registry.

## Native product surfaces

The active family owns:

- background and desktop canvas;
- native desktop widgets and Widget Studio;
- horizontal and vertical Bars, workspaces, tray, system state and clock;
- Context Island;
- dock and overview;
- launcher and Control Center;
- Settings and native Settings pages;
- media overlay;
- OSD and notifications;
- wallpaper selector and thumbnail generation;
- desktop context menu and hot corners;
- session/power screen;
- WlSessionLock + PAM/fingerprint lock UI;
- Polkit agent UI;
- region capture, OCR, image-search handoff and recording;
- screen translator;
- on-screen keyboard;
- left sidebar, fullscreen Command Deck, DropShelf and screen frame/corners;
- native Task Manager.

These surfaces are parsed and boundary-tested as `modules/raohane` code only.

## Native services

Current service contracts include:

- `RaohaneMedia` — Quickshell MPRIS;
- `RaohaneAudio` — PipeWire/WirePlumber via `wpctl`;
- `RaohaneNetwork` — NetworkManager via `nmcli`;
- `RaohaneBluetooth` — BlueZ via `bluetoothctl`;
- `RaohaneDisplay` — `brightnessctl`, `ddcutil`, `hyprsunset`;
- `RaohaneNotifications` — Quickshell notification service;
- `RaohaneWallpapers` — native folder model + Raohane thumbnail pipeline;
- `RaohaneSession` / `RaohaneSessionWarnings` — session and power safety;
- `RaohaneIdle` — native idle inhibitor;
- `RaohanePerformance` — compositor-facing performance/Game Mode behavior;
- `RaohaneEasyEffects` — EasyEffects integration;
- `RaohaneYdotool` — OSK input backend;
- `RaohaneDropShelf` — clipboard/file transfer;
- `RaohaneAutostart` — once-per-session startup commands;
- `RaohaneSystemInfo`, process/search and supporting service APIs — native product metadata and runtime data.

Privacy state is derived directly from the PipeWire graph in `RaohanePrivacy.qml`.

Visible QML should consume these service APIs rather than directly shelling out to compositor/network/audio commands.

## Capture and translation

Raohane-owned scripts provide:

- screenshots and region selection with `grim` / `slurp`;
- region OCR with Tesseract (`eng+rus`) and clipboard output;
- image-search handoff through PNG clipboard + Google Lens;
- recording with `wf-recorder`;
- screen translation with Tesseract + `translate-shell`;
- wallpaper thumbnails with system Python/Pillow, ffmpeg and ImageMagick fallback.

No thumbnail virtualenv or `ILLOGICAL_IMPULSE_*` environment is part of the production design.

## Lock and authentication

The lock uses `WlSessionLock` and Quickshell PAM directly. Fingerprint discovery uses `fprintd-list`; the fingerprint PAM transaction owns its profile at:

```text
modules/raohane/pam/fprintd.conf
```

Polkit uses Quickshell's native Polkit agent API and Raohane-owned presentation.

## Installation

`install-raohane.sh` uses only this repository and the Raohane Arch manifests:

```text
install/arch/required.txt
install/arch/features.txt
```

It does not clone end4-pC, illogical-impulse or Serpantinum. The installer stages a deterministic standalone Quickshell payload, normalizes native configuration, seeds first-run user-owned files when necessary, prunes stale runtime files and validates the installed payload before startup.

The same maintenance path normalizes an existing native config to the current schema before the shell starts.

## Diagnostics

Useful commands include:

```bash
raohane launcher
raohane control
raohane settings
raohane media
raohane desktop
raohane wallpaper
raohane wallpaper random
raohane session
raohane translate

raohane doctor all
raohane doctor deps
raohane doctor services
raohane doctor graphics
raohane doctor runtime

raohane validate phase4 --full
raohane validate release --full
```

`raohane doctor runtime` is the live boundary check for the user's installed copy. It is distinct from CI and verifies that the installed tree is native-only and that `native.json` matches the current native schema contract.

## Runtime verification boundary

Static CI verifies shell syntax, native QML parsing, registrations, package contracts, persistence boundaries, native schema upgrades, installed-runtime pruning and regression guards. It cannot prove compositor/device behavior.

Release-level validation still requires a real Hyprland + Quickshell session for startup, multi-monitor behavior, fullscreen/game overlay behavior, focus/input, launcher execution, notifications, audio/display controls, networking/Bluetooth, media, Settings, wallpapers/thumbnails, capture/OCR/translation, OSK/ydotool, lock/PAM/fingerprint, Polkit, session actions and NVIDIA/AMD/Intel hardware paths.

See [provenance](../NOTICE-UPSTREAM.md), the [roadmap](ROADMAP.md) and [release validation](RELEASE-VALIDATION.md) for attribution, remaining work and live checks.
