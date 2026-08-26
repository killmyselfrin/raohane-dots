# Raohane

**Raohane** is a Hyprland + Quickshell desktop shell built on a pinned end4-pC technical foundation and progressively replacing its visible surfaces with Raohane-native UI.

> Current development line: **full foundation → Raohane surface migration**

## Foundation strategy

The complete pinned `pctrade/end4-pC` runtime graph is committed in this repository: services, settings, widgets, notifications, OSD, media, networking, Bluetooth and the supporting Quickshell modules are available as the compatibility foundation.

Raohane keeps a separate product layer on top:

- `panelFamilies/RaohaneFamily.qml` is the composition point for Raohane surfaces.
- `modules/raohane/` contains Raohane-owned components and product state.
- Runtime settings live under `~/.config/raohane` rather than the upstream namespace.
- `ii-upstream` remains an explicit fallback panel family for diagnostics.
- Upstream revisions are pinned under `upstream/`; updates are deliberate instead of following a floating branch.

The active migration branch now has Raohane-native horizontal bar, launcher, Context Island, Control Center shell, Settings shell, game/media overlay, OSD and notification popup while keeping mature providers underneath.

## Install

On Arch-based systems the normal full bootstrap is:

```bash
chmod +x install-raohane.sh
./install-raohane.sh --deps
hyprctl reload
raohane restart
```

`--deps` runs the pinned illogical-impulse/end4 foundation dependency installer before installing Raohane. If the system already has the required foundation packages, use:

```bash
./install-raohane.sh
```

To install without immediately starting the user service:

```bash
./install-raohane.sh --no-start
```

The installer keeps persistent settings in `~/.config/raohane/config.json`. On the first install, if an older `~/.config/illogical-impulse/config.json` exists, Raohane copies it into its own namespace and selects the `raohane` panel family without discarding the rest of the JSON.

GPU drivers are not silently selected or replaced by the dependency installer. Upstream font binaries are not vendored in this repository; fonts remain package-managed.

## Batch test workflow

The development strategy intentionally allows several surfaces to move together and then collects runtime failures in one Hyprland test pass.

Start with diagnostics:

```bash
raohane doctor all
raohane doctor deps
raohane doctor services
raohane doctor graphics
```

Then exercise the main surfaces:

```bash
raohane launcher
raohane control
raohane settings
raohane media
raohane wifi status
raohane audio status
```

For direct terminal debugging:

```bash
raohane stop
raohane run
```

When reporting a batch failure, include `raohane doctor all` plus relevant output from `raohane run` or `raohane logs`. Verify bar/multi-monitor behavior, launcher focus, notifications, OSD, MPRIS/media, Settings, Control Center, audio, Wi-Fi/network, Bluetooth, brightness and capture before treating a build as release-ready.

## Developer upstream refresh

Normal users do **not** need to run the foundation synchronizer. It is only for intentionally refreshing the pinned end4-pC source graph:

```bash
# Preview only; repository remains unchanged.
bash scripts/sync-end4-foundation.sh

# Developer action: apply the pinned upstream refresh.
bash scripts/sync-end4-foundation.sh --apply
```

The synchronizer preserves Raohane-owned `shell.qml`, `modules/common/Directories.qml`, `modules/raohane/`, installer and CLI while refreshing the upstream technical foundation around them.

## Runtime paths

- Shell: `~/.config/quickshell/raohane`
- Settings: `~/.config/raohane/config.json`
- Hyprland integration: `~/.config/hypr/raohane.conf`
- User service: `raohane.service`

## Migration model

Raohane replaces visible shell surfaces in batches while mature system providers remain operational underneath. A native surface is only considered complete after a real Hyprland + Quickshell runtime pass; static CI is a structural gate, not a compositor test.

See `ARCHITECTURE.md`, `NOTICE-UPSTREAM.md`, `AGENTS.md` and `RAOHANE-CHANGELOG.md` for project and upstream notes.
