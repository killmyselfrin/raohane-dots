# Raohane changelog

## 0.10.0-dev — Foundation Migration Batch

- Complete the source/static standalone migration boundary: the active shell, services, configuration framework and visible runtime are Raohane-owned, while remaining hardware/session validation stays explicit.
- Add an automated source-lineage/license audit that distinguishes removed upstream runtime dependencies from retained GPL/data/asset provenance.
- Add reproducible source release packaging from committed `HEAD`, version consistency checks and SHA-256 verification through the release-boundary CI workflow.
- Make the Raohane product runtime explicitly Hyprland-only while keeping `ii-upstream` as a diagnostic fallback family.
- Add `RaohaneState.qml` so product-only ephemeral state survives end4 foundation refreshes.
- Add `RaohanePrivacy.qml` over Quickshell PipeWire for live microphone, camera and screen-capture context.
- Wire Context Island to live MPRIS, active-window and privacy data.
- Activate a Raohane-native horizontal bar while retaining mature workspace, tray and system providers.
- Add a dedicated Raohane launcher over `LauncherSearch` with keyboard navigation and native IPC.
- Add a fullscreen-friendly Raohane media overlay over the mature MPRIS backend.
- Replace the visible volume/brightness/gamma OSD with `RaohaneOsd.qml` while retaining Audio, Brightness and Hyprsunset providers.
- Replace the visible notification popup with `RaohaneNotificationPopup.qml` while retaining the mature notification server, persistence, timers and actions backend.
- Add a shared native notification card and notification center used by the Raohane Control Center.
- Replace compatibility right-sidebar quick controls with `RaohaneQuickControls.qml`, including Wi-Fi, Bluetooth, Night Light, Game Mode, idle inhibition, EasyEffects and native brightness/audio/microphone sliders.
- Remove the quick-control `jq` probe by parsing Hyprland JSON directly in QML.
- Replace the top-level Settings compatibility shell with `RaohaneSettingsContent.qml`, a Hyprland-only Raohane navigation layer over the mature configuration pages.
- Add `RaohaneSettingsHome.qml` as the wallpaper-backed Control Deck landing page with live context/system state.
- Replace the visible wallpaper selector with `RaohaneWallpaperSelector.qml` while retaining the mature `Wallpapers` service, preview and background transition path.
- Replace the visible desktop context menu with `RaohaneDesktopMenu.qml` while retaining background click coordinates, DropShelf and wallpaper services.
- Expand the `raohane` CLI with `media`, `desktop`, `wallpaper`, random-wallpaper control and batch diagnostics for dependencies, services and graphics.
- Add `./install-raohane.sh --deps` and `--no-start`; dependency installation stays pinned and GPU-driver mutation remains explicit.
- Expand static CI/audit coverage for native-surface registration, desktop/control/settings ownership boundaries, IPC routing, Hyprland product boundaries and upstream-refresh safety.
- Treat static validation as a structural gate only; the batch still requires a real Hyprland + Quickshell runtime pass before merge/release.

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
