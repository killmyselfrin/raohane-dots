# Raohane 0.9 — Context Foundation

Raohane 0.9 makes the shell react to context instead of treating the top bar as a static widget row.

## Primary UI

- `RaohaneContextIsland.qml` now selects its state by priority: recording, microphone/privacy, media, then active window/idle.
- `RaohaneControlCenter.qml` uses Raohane-native quick tiles, privacy state, sliders and a seekable MPRIS media card.
- `RaohaneLauncher.qml` has keyboard selection and quick actions.
- `RaohaneSettings.qml` has a wallpaper-backed Control Deck home surface.
- `RaohaneMediaOverlay.qml` provides the first real gaming media overlay, toggled with `SUPER + SHIFT + M`.

## Identity boundary

The primary UI in `modules/raohane/`, the Raohane launcher and the installer do not expose the old shell-family identity. Mature backend/service code is still being replaced incrementally where removing it in one pass would regress working hardware and system integration.

## Validation

Run:

```bash
~/.config/quickshell/raohane/scripts/raohane-audit.sh
```

The audit validates shell scripts, `qmldir` targets, local QML imports, the Raohane primary QML delimiter structure, required primary files and product-identity boundaries. A real Quickshell runtime test is still required after installation because the build environment does not contain the user's Quickshell/Hyprland runtime.
