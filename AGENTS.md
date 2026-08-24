# Raohane

Raohane is a Hyprland + Quickshell desktop shell.

## Architecture

- Hyprland only.
- Quickshell/QML UI.
- Primary UI lives under modules/raohane.
- Do not introduce Niri support.
- Do not add new iNiR UI dependencies.
- Legacy backend should gradually be replaced.

## Design

Visual direction:
- Japanese minimalism
- dark glass UI
- floating surfaces
- subtle purple accents
- Context Island as the centerpiece
- smooth organic animations

Reference:
- end4-pC for architectural ideas only.
- Do not clone its UI.
- Raohane must have its own visual identity.

## Primary surfaces

- RaohaneBar
- ContextIsland
- RaohaneControlCenter
- RaohaneSettings
- RaohaneLauncher
- GameMediaOverlay

## Before finishing

Run:

./scripts/raohane-audit.sh

Do not leave broken QML imports.
Do not reintroduce iNiR/Niri/Waffle/Ricelin into primary UI.
