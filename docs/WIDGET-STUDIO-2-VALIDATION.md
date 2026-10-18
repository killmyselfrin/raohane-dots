# Widget Studio 2.0 — on-desktop grid editing

> Implementation on `main`, not yet verified in a live Hyprland session. This guide covers the actual wallpaper editor, not the retired widget-gallery popup.

## Expected interaction

1. **Right-click** an empty area of the wallpaper or an existing desktop widget. Raohane's regular desktop menu opens at the pointer.
2. Choose **Desktop widgets**. The context menu closes. A subtle 32 px grid appears on the **actual wallpaper** with the **real running widgets**, not proxy cards or a smaller preview in Settings.
3. The editor switches to **Free layout** if necessary. Previously saved Balanced/Left/Right compositions are kept intact. The widget layer is enabled if it was disabled.
4. Drag the body of a widget to move it. Drag the highlighted lower-right handle to resize it. The widget stays visible as it moves and snaps to the grid when released. Position and scale are committed to `RaohaneConfig` **once at the end of the gesture**, then saved via the existing debounced config write.
5. A narrow toolbar above the desktop contains the widget-type icons, **Reset** for the selected widget, **Hide**, and **Done**. Selecting a hidden type enables it. Click **Done** or press **Escape** to leave edit mode.
6. The edit grid and full-screen input area are unloaded/disarmed outside edit mode, so normal wallpaper right clicks and widget media controls are restored. Editing also exits on screen lock, fullscreen activation on the edited output, and removal of that monitor.

Only the four existing native widget types (Clock, Media/Context, System, Motto) are currently supported. Settings → Widgets → Free layout continues to offer the older preview-based editor as an optional alternative.

## Test in a live Hyprland session

Back up the current settings before updating:

```bash
test -f ~/.config/raohane/native.json && cp ~/.config/raohane/native.json ~/.config/raohane/native.json.before-desktop-grid
cd ~/raohane-dots
git pull --ff-only
bash scripts/desktop-widget-boundary-audit.sh
./install-raohane.sh --no-deps --no-login-theme
raohane restart
```

Then verify:

1. Right-click the wallpaper → **Desktop widgets**. Confirm the popup **disappears** and the grid appears across the real desktop, showing actual widget content. No card gallery/secondary popup should appear.
2. Drag Clock to a new location and release. Move it again, then resize with the lower-right handle. Test System/Motto/Media too. Confirm live position and scale persist after `raohane restart`.
3. Click **Reset** and **Hide** for the selected widget. Click its icon in the toolbar to restore a hidden widget. The other widget positions must remain unchanged.
4. Choose **Done**, then right-click an empty wallpaper area: the usual compact menu must work. Left-click playback/media controls must work again. Check Escape exit separately.
5. Switch the saved layout back to **Balanced**, then to **Free**: the previous rail order and individually saved free positions must be preserved.
6. On multiple monitors, edit each separately. Disconnect the selected monitor while editing; no ghost fullscreen input region or focus trap should remain.
7. Enter fullscreen and lock the screen: editing must exit and must not capture inputs over apps/games.
8. Check pointer hit boxes with global Widget scale at 0.75 and 1.25 and mixed-DPI setups.
9. Run `raohane validate smoke`, `raohane doctor runtime`, and `raohane doctor performance`. Inspect `raohane logs` for QML errors.

Source audits: `bash scripts/desktop-widget-boundary-audit.sh`, `bash scripts/raohane-audit.sh`, `bash scripts/runtime-payload-audit.sh`. These are **not** a substitute for runtime/visual testing.

## Rollback

Exit edit mode with Done/Escape. To restore the previous visual arrangement, choose the old layout preset in Settings → Widgets. To reset a monitor's free positions use Reset monitor in the Settings free-layout editor. To recover the entire configuration from the backup, stop the shell before restoring `native.json`.

## Known limits

- The grid operates on the selected monitor only; repeat on another monitor as needed.
- Only one scale parameter per widget is stored (0.65–1.4); arbitrary rectangle aspect ratios and rotation are not available yet.
- Snapping is 32 px, and dragging only applies inside the selected output's bounds.
- Live Quickshell/QML compilation and visual behavior have not been verified from this environment.

See [Serpantinum reference](SERPANTINUM-REFERENCE.md) for future widget variants.
