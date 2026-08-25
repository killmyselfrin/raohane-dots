# Raohane

**Raohane** is a Hyprland + Quickshell desktop shell focused on floating glass surfaces, a central Context Island, fast system controls and a coherent dark visual language.

> Current development line: **0.9 Context Foundation → end4-pC foundation migration**

## Foundation strategy

Raohane now uses a pinned `pctrade/end4-pC` runtime foundation and the matching `end-4/dots-hyprland` dependency model. The goal is to regain the mature services, settings, widgets, notifications, OSD, media, networking and system integration first, then progressively replace the visible product with Raohane-native surfaces.

The upstream revisions are locked under `upstream/` so updates are deliberate instead of following a floating branch.

## Foundation bootstrap

On an Arch-based development machine:

```bash
# 1. Install the pinned foundation dependencies.
bash scripts/install-foundation-deps.sh

# 2. Preview the end4-pC import without changing the tree.
bash scripts/sync-end4-foundation.sh

# 3. Apply the pinned foundation import.
bash scripts/sync-end4-foundation.sh --apply
```

The synchronizer preserves Raohane-owned docs, installer, patches, `modules/raohane` and Raohane scripts. Upstream fonts are not vendored; fonts remain package-managed. GPU drivers are not silently replaced.

After syncing, test in a real Hyprland session:

```bash
qs -c raohane
```

Verify Settings, launcher/overview, Control Center/sidebar, OSD, notifications, MPRIS/media, audio, Wi-Fi/network and Bluetooth before continuing the visual migration.

## What is Raohane-native now

- Three-zone floating top bar
- Context Island with recording, privacy, MPRIS and active-window states
- Raohane theme primitives
- Raohane CLI and diagnostics
- Installer, systemd service and Hyprland integration

The existing Raohane-native QML remains under `modules/raohane/` while the complete foundation is synchronized around it.

## Install / update

```bash
cd ~/Загрузки/Raohane-Hyprland-0.9
chmod +x install-raohane.sh
./install-raohane.sh
hyprctl reload
raohane restart
```

Useful commands:

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

## Runtime paths

- Shell: `~/.config/quickshell/raohane`
- Settings: `~/.config/raohane/config.json`
- Hyprland integration: `~/.config/hypr/raohane.conf`
- User service: `raohane.service`

## Development status

The previous Raohane 0.9 prototype proved the Context Island and visual direction, but it did not contain the full backend/runtime coverage needed for a complete daily-driver shell. The current migration therefore treats end4-pC as the technical foundation rather than only a visual reference. See `NOTICE-UPSTREAM.md`, `AGENTS.md` and `RAOHANE-CHANGELOG.md`.
