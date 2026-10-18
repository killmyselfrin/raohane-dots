# Cinematic desktop — wallpaper picker and Bar

The first cinematic redesign pass builds on Raohane's **existing native**
wallpaper service and Bar. The project does not add a second wallpaper
database, an independently polling Bar, or extra compositor surfaces.

## Wallpaper picker

Open **Wallpaper** through the desktop context menu or existing shortcut.
The default view is now **Cinematic**, an image carousel with:

- a larger centered card, subdued angled neighbors and a restrained selection rim;
- keyboard left/right, arrow buttons, mouse scrolling and double-click apply;
- softly tinted backdrop based on the selected local wallpaper;
- shared folder/search/back/forward/random commands and existing Apply / Preview;
- a **Grid** toggle that restores the previous full thumbnail browser.

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
bash scripts/bar-boundary-audit.sh
bash scripts/runtime-payload-audit.sh
./install-raohane.sh --no-deps --no-login-theme --no-start
systemctl --user reset-failed raohane.service
systemctl --user start raohane.service
```

Verify:

1. Raohane starts normally, and the old desktop widgets / floating bar have not
   changed until you select a different bar preset.
2. Open Wallpaper. Confirm Cinema loads, scroll through actual images,
   use arrow keys, choose an image, click Preview, then Apply.
3. Double-click an image to apply it; click/double-click a folder to navigate.
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
