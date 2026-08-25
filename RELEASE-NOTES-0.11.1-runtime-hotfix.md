# Raohane 0.11.1 Runtime Hotfix

This checkpoint fixes first-run/runtime-path issues discovered on a real CachyOS + Hyprland test after Raohane 0.11.0 Foundation successfully loaded.

## Fixed

- Seed a valid first-run Material theme file before Quickshell starts, avoiding the missing `colors.json` warning on a fresh install.
- Seed empty generated translation overlays for bundled locales, avoiding harmless `~/.config/raohane/translations/<locale>.json` FileView warnings.
- Move active color/theme helpers from the inherited `ii` Quickshell config namespace to `raohane`.
- Isolate generated color/theme state under `~/.local/state/quickshell/raohane`.
- Isolate related cache paths under `~/.cache/quickshell/raohane`.
- Move persistent Raohane state (`states.json`) to the Raohane-owned state directory.
- Update screen-recording state handling to the same Raohane state file.
- Fix Kvantum/material and random-wallpaper helpers to use the Raohane runtime paths.
- Strengthen the runtime-path audit so stale `ii` or shared pre-Raohane paths fail CI.
- Ensure `raohane-graphics` is executable in the installed runtime.

## Still transitional

The visual foundation still contains upstream `modules/ii` internals and upstream UI identity in some implementation-level places. Those are migration debt, not the final Raohane design. This release focuses on making the imported foundation internally consistent and testable before the visual rebuild.
