# Raohane Widget Face Library — first release

Raohane now provides three **visual faces** for each of the existing desktop
Clock, Music / Context, and System widget slots. No extra slots, background
instances, executable workers or MPRIS sessions are created.

| Widget | Classic (default) | Minimal | Aurora |
| --- | --- | --- | --- |
| Clock | Original full-size clock card | Typographic time and compact date | Violet-accented glass clock |
| Music | Original now-playing/context surface | Slim, interactive MPRIS controls | Album-art glass player with transport buttons |
| System | Original network/audio status | Readable network, volume, CPU model and RAM snapshot | Aurora-glass status dashboard |

The music variants use the existing `RaohaneMedia` singleton and respect
`canTogglePlaying`, `canGoPrevious`, `canGoNext` capabilities. The system
cards show **live network and audio state**, plus CPU model and a memory
**snapshot** exposed by `RaohaneSystemInfo`; these are **not** CPU/GPU usage
graphs. Real GPU utilization would require a separately justified measurement
backend, and is not claimed in this release.

## Using the library

In **Settings → Desktop Widgets**, scroll to **Widget Library** and select
Classic, Minimal, or Aurora for Clock, Music, or System independently.
Changes are reflected in the existing desktop slot and survive shell restarts.
The `Style` button in **right-click desktop → Desktop widgets** edit mode
cycles Classic → Minimal → Aurora on the selected slot (disabled for Motto).
The original Motto widget is unchanged.

The setting lives under `desktopWidgets.styles` in
`~/.config/raohane/native.json`. Schema **v15** adds the keys without
discarding existing composition and per-monitor free-layout placements.
Unknown or invalid styles fall back to Classic.

## Test checklist — live Hyprland session required

1. Back up config before first upgrade. Install from an updated checkout:

   ```bash
   cd ~/raohane-dots
   git pull --ff-only
   bash scripts/desktop-widget-boundary-audit.sh
   bash scripts/runtime-payload-audit.sh
   ./install-raohane.sh --no-deps --no-login-theme --no-start
   systemctl --user reset-failed raohane.service
   systemctl --user start raohane.service
   ```

2. Verify the shell starts. Choose each of the nine clock/music/system
   combinations in Settings and check they update on the actual wallpaper.
3. With an MPRIS player running, validate album art, title, artist, progress,
   Play/Pause, Previous and Next; disabled transport buttons must remain inert.
   Pause and close the player to verify the empty-media state.
4. Change the system's volume and network connectivity; only corresponding
   live indicators should change. RAM and CPU labels must not be represented
   as periodically sampled utilization metrics.
5. Change face in direct on-desktop edit mode. Confirm the size/position are
   retained, and test switching Classic → Minimal → Aurora repeatedly.
6. Save, restart Raohane, and verify the chosen faces persist.
7. Check multi-monitor positioning, reduced motion, game/fullscreen hiding,
   and memory/CPU while the shell is idle. Hiding a widget must unload its
   face; it must not continue running active clocks or loading album art.
8. Run `raohane validate smoke`, `raohane doctor runtime`, and inspect
   `journalctl --user -u raohane.service -n 100 --no-pager` for QML errors.

## Release guardrails

`validate-runtime-payload.sh` requires all four new QML files and native
`qmldir` registrations. `runtime-payload-audit.sh` tests rejecting a
staged release missing a music variant. The new faces do **not** instantiate
`Process`, `FileView`, or extra service workers.

**Limitations:** The source has been checked statically, but full Qt/QML
runtime parsing and visual behavior still require the live tests above.
Three presentation options per existing slot are provided; independent
width/height editing and a new GPU sensor are outside this increment.
