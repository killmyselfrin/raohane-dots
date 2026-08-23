# Raohane

**Raohane** is a Hyprland + Quickshell desktop shell focused on floating glass surfaces, a central Context Island, fast system controls and a coherent dark visual language.

> Current development line: **0.9 Context Foundation**

## What is Raohane-native now

- Three-zone floating top bar
- Context Island with recording, privacy, MPRIS and active-window states
- Application launcher with keyboard navigation
- Right-side Control Center with quick actions, sliders, media and notifications
- Settings Control Deck and native settings registry
- Game media overlay (`SUPER + SHIFT + M`)
- Hotkey Assistant
- Hyprland-native window switcher
- Native notifications and system OSD
- Native session/power surface
- Raohane CLI, systemd service, config namespace and Hyprland integration

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
raohane hotkeys
raohane media-overlay
raohane doctor
raohane logs
```

## Runtime paths

- Shell: `~/.config/quickshell/raohane`
- Settings: `~/.config/raohane/config.json`
- Hyprland integration: `~/.config/hypr/raohane.conf`
- User service: `raohane.service`

## Development status

0.9 prioritizes the visible Raohane experience and context-aware surfaces. Several mature backend services and secondary utilities still come from the GPL-3.0 upstream base while they are rewritten incrementally. See `RAOHANE-0.9-NOTES.md` and `NOTICE-UPSTREAM.md`.
