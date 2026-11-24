# Capsule Bar — validation and behavior

Capsule is an **opt-in vertical preset** in Settings → Bar Studio → Presets. It is a composition of the existing native vertical Bar, not a second panel or background process.

## Composition

- **Workspace rail:** the active Hyprland workspace indicator stretches from a small dot into a vertical pill. Workspace identity and occupancy continue to come from the existing compositor model.
- **Media stack:** the existing Context action remains available, followed by previous, play/pause and next controls when an MPRIS player is present. All transport actions call the shared `RaohaneMedia` service.
- **Clock:** vertical hour/minute readout, accent-colored minutes, optional seconds and a compact date divider.
- **System area:** the existing StatusNotifier tray is arranged vertically, followed by Network, Bluetooth, Audio, Control Center and Session controls. Tile emphasis uses shared theme colors and live service state.

The preset saves its orientation and module composition through the existing Bar Studio configuration. Switching to another preset does not delete or replace the user's saved module definitions.

## Appearance and motion

Capsule uses the shared theme material, rounded glass rail and accent surfaces. It works with the default Raohane theme, **Sage Glass**, and Wallpaper Studio's optional adaptive palette. The preset does not silently change the user's global theme.

Workspace morphing follows `RaohaneMotion.transformMotionEnabled`; the shell's reduced-motion policy therefore disables the spring transform. The existing Game Mode policy and bar visibility/fullscreen handling remain authoritative.

## Validation

From the repository checkout:

```bash
bash scripts/bar-boundary-audit.sh
bash scripts/multimonitor-boundary-audit.sh
bash scripts/fullscreen-boundary-audit.sh
bash scripts/runtime-payload-audit.sh
```

Then validate in a real Hyprland + Quickshell session:

1. Open Settings → Bar Studio → Presets → Capsule.
2. Switch workspaces repeatedly; confirm the active pill follows the actual Hyprland workspace and settles without clipping.
3. Start an MPRIS player and test previous, play/pause, next and Context overlay access. Stop the player and confirm transport buttons disappear cleanly.
4. Open and activate StatusNotifier tray menus. Check vertical placement near both screen edges.
5. Toggle Wi-Fi, Bluetooth and audio states; confirm tile emphasis tracks service state. Open Control Center and Session.
6. Test Reduced Motion, Game Mode, auto-hide, fullscreen, display scaling and multiple monitors.
7. Switch to Halo or Floating and confirm the horizontal preset and module layout remain intact.

## Scope note

There is no native weather service in the current Raohane service graph, so Capsule does not display fabricated weather data or introduce a third-party polling client. A weather module can be added later as a separately permissioned native service.
