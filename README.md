# Raohane

**Raohane** is a Hyprland + Quickshell desktop shell built on a pinned end4-pC technical foundation and progressively replacing its visible surfaces with Raohane-native UI.

> Current development line: **full foundation → Raohane surface migration**

## Foundation strategy

The complete pinned `pctrade/end4-pC` runtime graph is now committed directly in this repository: services, settings, widgets, notifications, OSD, media, networking, Bluetooth and the supporting Quickshell modules are part of `main`.

Raohane keeps a separate integration layer on top:

- `panelFamilies/RaohaneFamily.qml` is the stable composition point for Raohane surfaces.
- `modules/raohane/` contains Raohane-native components.
- Runtime settings live under `~/.config/raohane` rather than the upstream namespace.
- `ii-upstream` remains an explicit fallback panel family for diagnostics.
- Upstream revisions are pinned under `upstream/`; updates are deliberate instead of following a floating branch.

## Install

On an Arch-based machine, install the pinned foundation dependencies once and then install Raohane:

```bash
bash scripts/install-foundation-deps.sh
chmod +x install-raohane.sh
./install-raohane.sh
hyprctl reload
raohane restart
```

The installer keeps persistent settings in `~/.config/raohane/config.json`. On the first install, if an older `~/.config/illogical-impulse/config.json` exists, Raohane copies it into its own namespace and selects the `raohane` panel family without discarding the rest of the JSON.

GPU drivers are not silently selected or replaced by the dependency installer. Upstream font binaries are not vendored in this repository; fonts remain package-managed.

## Test

Useful runtime commands:

```bash
raohane launcher
raohane control
raohane settings
raohane doctor
raohane doctor graphics
raohane wifi status
raohane wifi menu
raohane audio status
raohane logs
```

For direct terminal debugging:

```bash
raohane stop
raohane run
```

Verify Settings, launcher/overview, Control Center/sidebar, OSD, notifications, MPRIS/media, audio, Wi-Fi/network and Bluetooth before treating a build as release-ready.

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

`RaohaneFamily.qml` currently composes the proven foundation panels. From here, the visible shell is replaced one subsystem at a time — bar, launcher, control center, notifications, settings, media and desktop surfaces — while the mature service graph remains operational underneath.

See `NOTICE-UPSTREAM.md`, `AGENTS.md` and `RAOHANE-CHANGELOG.md` for project and upstream notes.
