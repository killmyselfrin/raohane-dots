# Wallpaper Studio 2.0 — staged native implementation

Raohane extends the existing Wallpaper Picker and native.json preferences.
**No second wallpaper daemon** is installed. Old settings, the Grid view,
Cinematic mode and lock-screen wallpaper are retained. All new settings are
optional with backward-compatible defaults in native schema v15.

## Stage 0 — Existing backend stability

- Cinematic and Grid still share `RaohaneWallpapers.folderModel`.
- Videos use cached FFmpeg/Pillow posters; missing posters show a fallback icon.
- Carousel transitions and decoded previews remain asynchronous, with
  70 ms debounce, 120 ms crossfade and 145 ms card motions.
- A broken optional Cinematic QML view returns to Grid.
- The existing preview/apply workflow is reused, and selected files are now
  checked with `test -f` before changing the wallpaper.

## Stage 1 — Library

Open Wallpaper Picker → **Studio**.

- **Favorite** adds/removes the selected local file; starred file chips provide
  quick access even when browsing another folder.
- **Save collection** bookmarks the currently open wallpaper folder. Saved
  collections appear as chips and reopen through the normal folder browser.
- **Right-click** a collection or favorite chip to remove it.
- Up to 256 unique favorites and 24 unique folder collections are validated
  and saved in the existing `wallpaper` section of `native.json`.
  Collections are *saved folders*, not duplicate copies of images.

## Stage 2 — Screens and rotation

- **Monitor** selects All monitors (default) or an individual connected
  output. Applying to a named output updates its override without altering
  other screens. Applying **All monitors** explicitly clears overrides and
  applies one common wallpaper.
- Screen overrides live under `wallpaper.monitors` and fall back to the
  regular global wallpaper on any monitor without an override.
- Live preview targets only the selected monitor. It clears on picker close.
- **Auto** chooses Off, 5 min, 15 min or 1 hour. **Source** chooses the
  current folder or favorites. Autoplay is OFF by default, avoids immediate
  repeats, skips the locked screen, and uses the existing single timer.
- Automatic global changes do not delete monitor overrides.

## Stage 3 — Adaptive theme and video

- **Adaptive on/off** opts in to wallpaper-driven accent color. It never
  overwrites the user's saved manual `theme.style.customAccent` or
  `accentMode`. Switching it off restores the previous theme.
  **Important:** this setting defaults to OFF for existing user
  configurations. After updating, open Wallpaper Picker → Studio → **Adaptive
  off** and click it to switch to **Adaptive on**. Bar and widgets will start
  using the palette of the confirmed wallpaper once sampling completes.
- A tiny Python Pillow helper extracts a muted accent only after a confirmed
  global wallpaper changes. For MP4/WebM and other video wallpapers, a single
  bounded FFmpeg still-frame extraction runs **without** requiring Wallpaper
  Picker to generate a poster first. There is no frame-by-frame sampling or
  network API.
- Adaptive color now tints the shared glass surface, raised/deep surfaces,
  borders, hover/pressed materials, and accent tokens consumed by Bar and
  Desktop Widgets. It preserves opacity and existing text contrast instead
  of replacing the entire window with a saturated color.
- If Pillow or an image decoder is unavailable, the last validated accent
  remains and normal wallpaper application still succeeds.
- **Pause/Resume** appears when previewing a video wallpaper; normal video
  wallpapers are not paused by this control.

## Install and live smoke test — fish shell

Back up `~/.config/raohane/native.json`, then run:

```fish
cd ~/raohane-dots
git pull --ff-only
bash scripts/wallpaper-boundary-audit.sh
bash scripts/wallpaper-studio-audit.sh
bash scripts/runtime-payload-audit.sh
./install-raohane.sh --no-deps --no-login-theme --no-start
systemctl --user reset-failed raohane.service
systemctl --user start raohane.service
journalctl --user -u raohane.service -n 100 --no-pager
```

Test favorites/collections persistence after restart, inaccessible favorite
paths, grid/cinema fallback, Cyrillic MP4 posters, Pause/Resume, manual accent
restoration, locked session, fullscreen playback, multi-monitor previews and
apply behavior. If a screen is disconnected, saved override entries are
preserved for later reconnection; available screens use their own name-based
overrides.

Known limitations: the automatic source is either the current working folder
or favorites (not several nested folders), collection names derive from folder
names, and adaptive color is based on the global applied wallpaper rather than
a different accent per physical monitor. Qt/Hyprland visual and interactive
behavior **has not been verified by source-only checks**; use the smoke test
above before treating this as a stable release.
