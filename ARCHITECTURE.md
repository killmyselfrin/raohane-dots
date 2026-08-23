# Raohane architecture

Raohane is a Hyprland + Quickshell shell. The product-facing layer lives in `modules/raohane/`; shared system integrations live in `services/` and `modules/common/` while migration away from inherited backend code continues.

## Primary surfaces

- `RaohaneBar.qml` — three-zone floating bar.
- `RaohaneContextIsland.qml` — context state machine.
- `RaohaneLauncher.qml` — application launcher.
- `RaohaneControlCenter.qml` — quick controls, media and notifications.
- `RaohaneSettings.qml` — Settings Control Deck.
- `RaohaneMediaOverlay.qml` — floating media overlay for games/apps.

## Runtime

`shell.qml` is the root Quickshell configuration. `GlobalStates.qml` holds cross-surface runtime state. Persistent Raohane product options are stored below `Config.options.raohane` and serialized into `~/.config/raohane/config.json`.

## Integration

The shell targets Hyprland. The installer writes an isolated `~/.config/hypr/raohane.conf` and exposes the `raohane` CLI. The user systemd service is `raohane.service`.

See `NOTICE-UPSTREAM.md` for retained backend provenance and licensing notes.
