# Raohane changelog

## Phase A — dependency and system foundation


- Added a machine-readable Arch dependency manifest with capability, diagnostic,
  service, provenance, session, and hardware metadata.
- Rebuilt the bootstrap installer around check/minimal/recommended/full profiles,
  explicit package plans, confirmation, service setup, and runtime verification.
- Added the canonical `raohane` named-config launcher and subsystem doctor checks.
- Documented the coverage review, deliberate exclusions, and Phase B limitations.


## dev-0.1
- Created from Raohane base.
- Retained full Raohane settings/config architecture.
- Added Raohane compatibility launcher.
- Rebranded Settings window titles.
- Replaced sidebar media widget with a new Serpantinum-inspired MPRIS/CAVA player.
- Added initial product direction for Living Theme, Game Media Overlay, Focus Scene, Context Island, app profiles, and Japanese visual presets.

## 0.4.2-dev
- Fix HyprlandData singleton registration in services/qmldir.
- Fix Hyprland workspace/window data access under Hyprland.
- Harden Background.qml against transient missing client data.
- Fix undefined boolean binding in Raohane Island media pulse.

## 0.9.0-dev — Context Foundation

- Turn Context Island into a priority-based state surface for recording, microphone/privacy, media and active-window context.
- Add reusable Raohane quick tiles and a seekable MPRIS media card.
- Rework Control Center with Wi-Fi, Bluetooth, Focus and Night Light tiles plus privacy state.
- Add keyboard selection and quick actions to the Raohane Launcher.
- Add wallpaper-backed Settings Control Deck home surface.
- Implement a real floating game media overlay and `SUPER + SHIFT + M` Hyprland binding.
- Expand the Raohane config namespace for Context Island, Control Center and gaming behavior.
- Keep old shell identity out of primary UI, launcher and installer while backend replacement continues incrementally.
- Extend `raohane-audit.sh` to validate primary QML/import/identity boundaries.

## 0.8.0-dev — Visual Foundation

- Load Raohane Bar and Control Center directly from the root shell.
- Add native Raohane Launcher and `raohane launcher` IPC/CLI path.
- Replace SettingsPageRegistry in the visible settings UI with RaohaneSettingsRegistry.
- Add native Appearance, Bar, Control Center, Effects, Media, Hyprland and System pages.
- Convert the bar to three floating pods with Context Island as the visual center.
- Set `panelFamily=raohane` as the only shell family and remove Waffle runtime loading.
- Remove legacy bar/right-sidebar/overview/left-sidebar primary loaders.
- Move active helper/service/cache paths to the Raohane namespace.
- Add visual previews to Bar and Control Center settings.
# Phase A — dependency and system foundation

- Added a machine-readable Arch dependency manifest with capability, diagnostic,
  service, provenance, session, and hardware metadata.
- Rebuilt the bootstrap installer around check/minimal/recommended/full profiles,
  explicit package plans, confirmation, service setup, and runtime verification.
- Added the canonical `raohane` named-config launcher and subsystem doctor checks.
- Documented the coverage review, deliberate exclusions, and Phase B limitations.
