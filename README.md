# Raohane

**Raohane** is a Hyprland + Quickshell desktop shell being developed toward a fully standalone runtime and codebase.

> Current development line: **migration reference → standalone Raohane**

## Independence target

`end4-pC`, illogical-impulse, iNiR and Serpantinum are development references/migration sources, not permanent Raohane dependencies.

The target release architecture is explicit:

- Raohane installs without cloning or executing another shell repository.
- Raohane owns its dependency manifest, services, configuration schema, common framework and visible UI.
- Production runtime has no required `modules/ii` imports and no upstream panel-family fallback.
- Upstream synchronization scripts and lock files disappear after migration is complete.
- Third-party license/attribution notices remain where code/assets still require them.

See `INDEPENDENCE-PLAN.md` for the removal milestones.

## Independence progress

The normal installation path is now standalone: `./install-raohane.sh --deps` uses Raohane-owned Arch manifests from `install/arch/` and does not clone or execute another shell repository. CI likewise validates the local Raohane graph without fetching end4-pC.

The first Raohane-owned service adapters are also active:

- `RaohaneMedia` → direct Quickshell MPRIS
- `RaohaneBluetooth` → direct Quickshell Bluetooth
- `RaohaneAudio` → direct Quickshell PipeWire
- `RaohanePrivacy` → direct PipeWire capture state

Context Island and Media Overlay use `RaohaneMedia`; Control Center Bluetooth/audio controls use `RaohaneBluetooth` and `RaohaneAudio`; the Raohane volume OSD also uses `RaohaneAudio`.

A compatibility graph is still present for parts that have not yet been rewritten. It is migration material, not the target architecture.

## Current native surfaces

Current Raohane-owned product surfaces include the horizontal bar, launcher, Context Island, Control Center internals, Settings navigation and Control Deck, game/media overlay, OSD, notification popup/history UI, wallpaper selector, desktop context menu and session/power menu.

`panelFamilies/RaohaneFamily.qml` is currently the composition boundary, `modules/raohane/` contains Raohane-owned product components/state/services, and persistent settings already live under `~/.config/raohane`.

## Install

On Arch-based systems:

```bash
chmod +x install-raohane.sh
./install-raohane.sh --deps
hyprctl reload
raohane restart
```

`--deps` installs the Raohane-owned package manifest with `pacman`. It does not use illogical-impulse/end4 setup scripts and it never selects or replaces GPU drivers.

If the required packages are already installed:

```bash
./install-raohane.sh
```

To install without immediately starting the user service:

```bash
./install-raohane.sh --no-start
```

New installations seed `~/.config/raohane/config.json` from Raohane defaults. Importing an older illogical-impulse config is explicit and optional:

```bash
./install-raohane.sh --migrate-legacy
```

Font binaries remain package-managed rather than vendored into the repository.

## Dependency manifests

Raohane owns its current Arch dependency lists:

```text
install/arch/required.txt
install/arch/features.txt
```

Useful checks:

```bash
bash scripts/install-deps.sh --minimal --check
bash scripts/install-deps.sh --full --check
bash scripts/install-deps.sh --full --print
raohane doctor deps
```

## Main controls

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

The desktop menu is also opened by the existing desktop right-click path from the current background renderer.

## Batch test workflow

Development intentionally moves several surfaces together and collects runtime failures in one Hyprland test pass.

Start with diagnostics:

```bash
raohane doctor all
raohane doctor deps
raohane doctor services
raohane doctor graphics
```

Then exercise the main surfaces listed above plus:

```bash
raohane wifi status
raohane audio status
```

For direct terminal debugging:

```bash
raohane stop
raohane run
```

When reporting a batch failure, include `raohane doctor all` plus relevant output from `raohane run` or `raohane logs`. Verify bar/multi-monitor behavior, launcher focus, Control Center toggles/sliders, notifications, OSD, MPRIS/media, Settings page loading, wallpaper preview/apply/random, desktop menu placement, session actions, audio, Wi-Fi/network, Bluetooth, brightness and capture before treating a build as release-ready.

## Static validation

`Raohane audit` validates shell scripts, Raohane module/service ownership, IPC routes and the current migration graph. It parses `shell.qml`, `RaohaneFamily.qml` and all Raohane-owned QML files with Qt6 `qmlformat` so obvious QML syntax failures are caught before a compositor test.

`scripts/service-boundary-audit.sh` specifically prevents active Raohane surfaces from silently regressing to inherited MPRIS, Bluetooth or Audio service adapters after those boundaries have migrated.

This still does not replace a real Hyprland + Quickshell runtime pass: plugin imports, LayerShell behavior, focus, live service properties and compositor-specific interactions must be verified in the target session.

## Temporary migration tooling

`scripts/sync-end4-foundation.sh`, the old dependency bootstrap and upstream lock files are migration scaffolding only. They are no longer used by the normal installer, dependency doctor or CI and will be deleted after the remaining inherited runtime code has been replaced.

## Runtime paths

- Shell: `~/.config/quickshell/raohane`
- Settings: `~/.config/raohane/config.json`
- Hyprland integration: `~/.config/hypr/raohane.conf`
- User service: `raohane.service`

## Migration model

Raohane is not intended to remain a reskinned end4-pC installation. The migration ends only when Raohane owns its UI, services, config/common framework, dependencies and release path and no longer needs another shell repository to build, install, update or run.

See `INDEPENDENCE-PLAN.md`, `ARCHITECTURE.md`, `NOTICE-UPSTREAM.md`, `AGENTS.md` and `RAOHANE-CHANGELOG.md`.
