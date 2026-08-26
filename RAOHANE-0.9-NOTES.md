# Raohane 0.9 — Context Foundation

Raohane 0.9 starts moving the shell from static widget rows toward context-aware Raohane-owned surfaces while preserving the mature end4-pC / illogical-impulse system foundation underneath.

## Raohane-native UI

- `RaohaneContext.qml` selects context by priority: recording/privacy event state, transient events, live media, then active window/idle.
- `RaohaneContextIsland.qml` renders that state as the signature adaptive island.
- `RaohaneControlCenter.qml` provides the Raohane control-center presentation while reusing mature quick-toggle, notification and system providers.
- `RaohaneSettings.qml` provides the Raohane Settings shell while the settings content is still being migrated.
- `RaohaneMediaOverlay.qml` provides the gaming/app media overlay backed by the shared MPRIS controller and toggled with `SUPER + SHIFT + M`.

## Compatibility UI still in production

The launcher/overview, production bar, popup notifications/OSD, wallpaper system and several supporting panels still use mature foundation components. Experimental Raohane replacements are not promoted until they reach feature parity in a real Hyprland session.

## Identity boundary

New product-facing UI and Raohane-specific runtime state live in `modules/raohane/`. Mature backend/service code remains in place where removing it would regress hardware or system integration. `GlobalStates.qml` remains foundation-owned because the upstream synchronizer refreshes it; Raohane-only state belongs in `RaohaneState.qml`.

## Validation

Run:

```bash
~/.config/quickshell/raohane/scripts/raohane-audit.sh
```

The audit validates shell scripts, `qmldir` targets, local QML imports, required primary files and product-identity boundaries. A real Quickshell/Hyprland runtime test is still required after installation for overlay placement, fullscreen behavior, MPRIS controls and hardware/system integrations.
