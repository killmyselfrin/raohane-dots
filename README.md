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
- Third-party license/attribution notices remain only where code/assets still require them.

See `INDEPENDENCE-PLAN.md` for the removal milestones.

## Current migration state

The current branch still contains a compatibility graph inherited from the earlier migration approach. It is temporary. Raohane-native surfaces are replacing it in large batches while equivalent system behavior is kept operational until Raohane-owned services are ready.

Current native surfaces include the horizontal bar, launcher, Context Island, Control Center internals, Settings navigation and Control Deck, game/media overlay, OSD, notification popup/history UI, wallpaper selector, desktop context menu and session/power menu.

`panelFamilies/RaohaneFamily.qml` is currently the composition boundary, `modules/raohane/` contains Raohane-owned product components/state, and persistent settings already live under `~/.config/raohane`.

## Install

On Arch-based systems the current migration bootstrap is:

```bash
chmod +x install-raohane.sh
./install-raohane.sh --deps
hyprctl reload
raohane restart
```

**Important:** `--deps` still invokes the temporary illogical-impulse/end4 dependency bootstrap. Replacing this with a Raohane-owned package manifest is now a required independence milestone, not the final installer design.

If the required packages are already installed:

```bash
./install-raohane.sh
```

To install without immediately starting the user service:

```bash
./install-raohane.sh --no-start
```

The installer keeps persistent settings in `~/.config/raohane/config.json`. During migration it can import an older `~/.config/illogical-impulse/config.json` on first install; this compatibility path will be removed after the Raohane config schema is fully owned.

GPU drivers are not silently selected or replaced by the dependency installer. Font binaries remain package-managed.

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

Foundation Audit currently validates shell scripts, the migration graph, Raohane module ownership and IPC routes. The branch also parses `shell.qml`, `RaohaneFamily.qml` and all Raohane-owned QML files with Qt6 `qmlformat` so obvious QML syntax failures are caught before a compositor test.

As migration progresses, CI will stop validating inherited foundation code and eventually validate only the standalone Raohane graph.

This still does not replace a real Hyprland + Quickshell runtime pass: plugin imports, LayerShell behavior, focus, live service properties and compositor-specific interactions must be verified in the target session.

## Temporary upstream refresh tooling

`scripts/sync-end4-foundation.sh` is migration scaffolding only. It is not part of the target architecture and must be removed once active Raohane code no longer depends on the inherited graph.

Normal users should not need this script.

## Runtime paths

- Shell: `~/.config/quickshell/raohane`
- Settings: `~/.config/raohane/config.json`
- Hyprland integration: `~/.config/hypr/raohane.conf`
- User service: `raohane.service`

## Migration model

Raohane is not intended to remain a reskinned end4-pC installation. The migration ends only when Raohane owns its UI, services, config/common framework, dependencies and release path and no longer needs another shell repository to build, install, update or run.

See `INDEPENDENCE-PLAN.md`, `ARCHITECTURE.md`, `NOTICE-UPSTREAM.md`, `AGENTS.md` and `RAOHANE-CHANGELOG.md`.
