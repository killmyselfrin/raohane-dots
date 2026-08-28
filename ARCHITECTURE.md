# Raohane architecture

Raohane is a Hyprland + Quickshell shell with a Raohane-owned production runtime. Historical end4-pC / illogical-impulse code may still remain in the source checkout as temporary rollback/reference material, but it is not part of the installed QML graph.

## Production graph

```text
Hyprland / Wayland / D-Bus / PipeWire / MPRIS / PAM / Polkit
                         ↓
                modules/raohane/services
                         ↓
          RaohaneConfig + RaohaneState + paths
                         ↓
                 modules/raohane UI
                         ↓
             panelFamilies/RaohaneFamily.qml
                         ↓
                    shell.qml
```

Production code must not import `modules/common`, `modules/ii`, root `services/`, `GlobalStates`, inherited `Config`, or another shell namespace.

## Bootstrap and module boundary

`shell.qml` is intentionally small. It imports the native Raohane config module, waits for `RaohaneConfig.ready`, then instantiates only `RaohaneFamily`.

The root `qmldir` exports only:

```text
module qs
```

`modules/raohane/qmldir` contains Raohane UI/state types. `modules/raohane/services/qmldir` contains native service singletons. `modules/raohane/config/qmldir` owns paths and persistent configuration.

## Persistent state

Raohane owns schema v10 in:

```text
~/.config/raohane/native.json
```

`RaohaneConfig.qml` owns serialization, reload and validation boundaries. The installer seeds `defaults/native.json` and can migrate the directly supported subset of an older configuration through `scripts/migrate-legacy-config.py`.

Ephemeral UI state belongs to `RaohaneState.qml` and is never stored in the old `GlobalStates.qml` runtime.

User autostart commands live in:

```text
~/.config/raohane/autostart.conf
```

`RaohaneAutostart` runs them once per Hyprland session, not on every shell restart.

## Native product surfaces

The active family currently owns:

- background and desktop canvas;
- horizontal and vertical bars, workspaces, tray, system state and clock;
- dock and overview;
- launcher and control center;
- Settings and native Settings pages;
- media overlay;
- OSD and notifications;
- wallpaper selector and thumbnail generation;
- desktop context menu;
- session/power screen;
- WlSessionLock + PAM/fingerprint lock UI;
- Polkit agent UI;
- region capture, OCR, image-search handoff and recording;
- screen translator;
- on-screen keyboard;
- left sidebar, overlay, DropShelf and screen frame/corners.

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
- `RaohaneEasyEffects` — EasyEffects integration;
- `RaohaneYdotool` — OSK input backend;
- `RaohaneDropShelf` — clipboard/file transfer;
- `RaohaneAutostart` — once-per-session startup commands;
- `RaohaneSystemInfo` and `RaohaneSearch` — system metadata and desktop entries.

Privacy state is derived directly from the PipeWire graph in `RaohanePrivacy.qml`.

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

It does not clone end4-pC or illogical-impulse. The retired upstream synchronizer, inherited dependency bootstrap and upstream source lock files have been removed.

The installer copies the checkout to the Quickshell runtime and immediately runs `scripts/prune-runtime.sh`. The installed QML graph therefore excludes source-only rollback/reference trees such as `modules/common`, `modules/ii`, root `services`, old root QML and non-Raohane panel families.

`raohane run` repeats this integrity guard before starting Quickshell so an older installed copy can self-heal after an upgrade.

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
```

`raohane doctor runtime` is the live boundary check for the user's installed copy. It is distinct from CI and verifies that the installed tree is native-only and that `native.json` is schema v10.

## Source cleanup boundary

The installed runtime is already pruned to the standalone graph. Some historical inherited source trees remain in Git only as temporary rollback/reference material until the current native runtime passes another complete live validation cycle.

After that validation, the remaining source copies of `modules/common`, `modules/ii`, old root `services`, inherited root QML and obsolete panel families can be removed physically. Required copyright/license notices remain where derivative code or assets still require them.

## Runtime verification boundary

Static CI verifies shell syntax, native QML parsing, registrations, package contracts, persistence boundaries, installed-runtime pruning and regression guards. It cannot prove compositor/device behavior.

Release-level validation still requires a real Hyprland + Quickshell session for startup, multi-monitor behavior, fullscreen/game overlay behavior, focus/input, launcher execution, notifications, audio/display controls, networking/Bluetooth, media, Settings, wallpapers/thumbnails, capture/OCR/translation, OSK/ydotool, lock/PAM/fingerprint, Polkit, session actions and NVIDIA/AMD/Intel hardware paths.

See `NOTICE-UPSTREAM.md` for provenance/licensing notes and `INDEPENDENCE-PLAN.md` for the remaining source-removal/release gates.
