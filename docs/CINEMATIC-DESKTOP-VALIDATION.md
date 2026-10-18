# Cinematic desktop — wallpaper picker and Bar

The first cinematic redesign pass builds on Raohane's **existing native**
wallpaper service and Bar. The project does not add a second wallpaper
database, an independently polling Bar, or extra compositor surfaces.

## Transparent glass — Wallpaper Picker only

The picker now uses a low-opacity screen scrim and theme-aware translucent
surfaces. Cinematic mode also uses a semitransparent background gradient that
lets the **real desktop wallpaper** show through behind the carousel. In
Grid mode the navigation sidebar and search field have matching glass density.
Only **background fills** are translucent; thumbnail cards, controls and text
stay fully opaque for readability.

This refinement **does not modify the Bar or its presets**. The separately
available Cinematic Bar described below remains opt-in and unchanged.
Transparency uses QML alpha composition; background blur is available only
if the user's Hyprland configuration applies blur to the wallpaper selector's
layer namespace. No shader-based blur worker is added.

After installing, test both dark and light themes against bright and dark
wallpapers. Verify that the search text, folder names, Preview/Apply controls
and selected-card indicators remain clearly readable.

## Wallpaper picker

Open **Wallpaper** through the desktop context menu or existing shortcut.
The default view is now **Cinematic**, an image carousel with:

- a larger centered card, subdued angled neighbors and a restrained selection rim;
- smooth scroll snapping, keyboard left/right, working arrow buttons in a floating
  glass toolbar, and double-click Apply;
- fast delayed (70 ms) selection preview: browsing updates the pending filename
  immediately, but only settled selections trigger live desktop preview;
- two bounded, asynchronously decoded background layers that crossfade over
  about 120 ms after the incoming image is ready (reduced-motion respected);
- softly tinted, translucent backdrop on the *real wallpaper*, not a solid
  mini-preview that covers the entire screen;
- shared folder/search/back/forward/random commands and existing Apply / Preview;
- a **Grid** toggle that restores the previous full thumbnail browser.


Live desktop preview is controlled by the existing
`RaohaneConfig.wallpaperPreview` setting. When that setting is disabled,
carousel selection and in-picker crossfade still work, but the running desktop
background does not change until Apply. Videos preview only after an explicit
click, rather than launching video decode for every flick. Saved wallpaper
configuration is modified **only by Apply or the existing Random action**.

Folder navigation is explicit: highlighting a folder in the carousel never
opens it automatically. Movies and folders receive their own placeholders.
Image decoding is capped (`sourceSize`) and the hidden grid releases its
image model while Cinema is active.

The carousel is **lazy-loaded** from `RaohaneWallpaperCinema.qml`. If loading
fails, the wallpaper selector should return to the old grid rather than crash
the shell. Users can always switch to Grid through the header.

## Bar

Open **Settings → Bar Studio → Presets → Cinematic**. This opt-in style adds
softer separated glass pods, slightly wider breathing room and fine accent
lines while retaining every user module, bar positioning, autohide, fullscreen
policy, contextual status service and tray action.

Existing Float, Compact, Panel, Classic and Islands presets are unchanged.
The Cinematic preset is persisted under `bar.stylePreset`, together with
the existing bar geometry fields. Switching back to Float reuses the same
module layout.

## Install and test in a live Hyprland session

Before an update, copy your current `~/.config/raohane/native.json` settings.
In fish shell:

```fish
cd ~/raohane-dots
git pull --ff-only
bash scripts/wallpaper-boundary-audit.sh
# When ffmpeg and Pillow are installed, this now also generates a real test
# MP4 and verifies the exact cache thumbnail path/decoded image.
bash scripts/bar-boundary-audit.sh
bash scripts/runtime-payload-audit.sh
./install-raohane.sh --no-deps --no-login-theme --no-start
systemctl --user reset-failed raohane.service
systemctl --user start raohane.service
```

Verify:

1. Raohane starts normally, and the old desktop widgets / floating bar have not
   changed until you select a different bar preset.
2. Open Wallpaper. Confirm Cinema shows **actual cards and its floating
   CINEMATIC toolbar** (not a blank transparent section), even if the folder
   contains only 1–2 items. The cards read `filePath/fileName/fileIsDir`
   from `FolderListModel`, with dimensions supplied by the Loader. Scroll
   through actual images using mouse/trackpad or the arrows, and watch the
   centered card move with soft scaling/rotation. Selection should not apply
   the wallpaper.
   Wait briefly for the image crossfade and live background preview, click
   Preview, then Apply. Check that rapid scrolling does not launch a flurry
   of expensive intermediate wallpaper decodes.
3. Open a folder with a `.mp4` or `.webm` video. The existing
   existing thumbnail generator should produce an x-large poster frame at
   ~5 seconds (falling back to 1/0 seconds for short videos); the carousel
   should show that actual extracted frame **inside the video card and behind
   the carousel**, instead of a permanently dark video-icon placeholder.
   The decoder uses the installed FFmpeg CLI and Python Pillow; if these are
   missing or the file is corrupt, the original fallback icon remains.
   Double-click an image to apply it; click/double-click a folder to navigate.
   Make sure browsing past a folder does not navigate by itself.
4. Switch Grid → Cinematic → Grid. Verify folder navigation, search, thumbnail
   display, video entries, random wallpaper and lockscreen target.
5. Open Settings → Bar Studio and select Cinematic. Inspect the center/edge
   islands at wide and narrow output widths. Test bar auto-hide, screen edges,
   game fullscreen, Super reveal, vertical orientation and keyboard/tray.
6. Change Bar back to Float and confirm original visual spacing is restored.
7. Review logs for QML errors and performance changes:
   ```fish
   journalctl --user -u raohane.service -n 100 --no-pager
   raohane doctor runtime
   raohane doctor performance
   ```

If Cinema reports a loaded view but its cards fail to instantiate, the
picker automatically reverts to Grid after a short health check. Capture
`journalctl --user -u raohane.service -n 100 --no-pager` for messages
containing `RaohaneWallpaperCinema`, `Required property`, `Cinematic
cards` or `Loader`. A folder showing only **2 items** can display only two
different cards; point Raohane at a folder with more wallpaper files to see
the full fanned-out composition.

The installer checks required QML assets and, when `qmlformat` is present,
parses the new picker, Bar, and related components **before stopping Raohane**.
The staging audit rejects packages missing the carousel file. These checks
cannot replace a live Qt/Hyprland runtime test.

## Known limitations

The visual carousel is currently hosted in Raohane's existing selector
window rather than making wallpaper widgets part of the desktop background
layer itself. GPU-intensive blur shaders, full image color extraction and a
persisted list of favorites are deliberately out of scope for this first
pass. The bar preset is opt-in and does not change the layout order of existing
modules.
