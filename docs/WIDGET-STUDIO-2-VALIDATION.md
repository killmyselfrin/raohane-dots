# Widget Studio 2.0 — free layout MVP validation

> Source implementation on `main`. **Not yet certified in a live Hyprland session.** The existing Balanced / Left rail / Right rail layouts remain the default and are intended to be unaffected.

## Scope of the first increment

- Adds `Free layout` as an optional fourth Widget Studio composition.
- **Right-click wallpaper or any desktop widget** to open the compact Raohane Desktop menu. Choose **Desktop widgets** to expand that same popup into a two-pane gallery: four visual cards (each with show/hide), and a shared interactive preview editor. Right-clicking a widget preselects it when the gallery opens.
- When a preset layout is active, the preview offers **Enable free layout** (never switches automatically). In Free Layout, drag the preview tiles to position them, drag their corner handles or use +/- to resize, select a widget in the card grid, reset it, choose the monitor, or open Full Widget Studio. The original preset order remains untouched.
- Only widget hit areas receive pointer input from the desktop widget layer; the remaining wallpaper should remain clickable. Mouse/touch playback controls are not replaced by a new fullscreen interaction layer.
- In Settings → Widgets → Free layout, drag each enabled widget in the monitor preview to change its position, or drag the lower-right handle (or use +/-) to change its scale. Click a widget and press the arrow keys for 1% position steps; choose a widget in the selector to edit it without a pointer, or use **Reset** to restore only that widget.
- The runtime renders the existing four native widgets on each monitor using normalized positions and per-widget size, without creating extra media/audio/network services.
- Geometry is stored in `desktopWidgets.freeLayouts` under `~/.config/raohane/native.json`, indexed by monitor name. The editor falls back to a connected output when the selected monitor disconnects.
- The QML config serializer validates known widget IDs, monitor names, position and scale bounds. The legacy `composition` object and original three layout presets are still present.
- The new schema is v14. The existing install migration deep-merges defaults and changes schema v13 → v14 while preserving user values.

## Testing in a real session

1. **Backup the current configuration.** `cp ~/.config/raohane/native.json ~/.config/raohane/native.json.before-widget-studio-2` if the file exists.
2. Fetch the updated checkout: `cd ~/raohane-dots && git pull --ff-only`.
3. Install the edited runtime: `./install-raohane.sh --no-deps --no-login-theme`, then `raohane restart`.
4. Open **Settings → Widgets**. Confirm `Balanced`, `Left rail` and `Right rail` still work, then choose **Free layout**.
5. Drag clock, media/context, system and motto previews. Resize one. Click the preview, press arrow keys and use the widget selector / Reset control; verify the changes. Change the global widget scale to 0.75 and 1.25 and confirm free widgets stay inside monitor edges.
6. On multi-monitor setups, choose each monitor in the editor and give the same widget different placements. Unplug the selected monitor while the editor is open and confirm it switches to a connected output; check fractional scaling, fullscreen games and return to desktop.
7. On uncovered wallpaper, **right-click → Desktop widgets** and confirm the compact menu expands into a two-column gallery/editor, rather than a second standalone window. Use Back and Escape to return to the compact menu and Escape again to close. Repeat with right-click on a widget: the gallery should preselect that widget after choosing Desktop widgets. Check switches, drag handles, resize +/- and reset.
8. While in Balanced mode, right-click Clock → Desktop widgets → **Enable free layout**; confirm you can drag it and switching back to Balanced restores the previous rail positions. Hide and re-enable a widget through a gallery card; confirm the state persists.
9. Verify *left-click actions, media playback and pointer controls* continue functioning. On a fullscreen window, verify the widget layer does not intercept right-clicks. Check an uncovered desktop area beside the widgets also receives right-click.
10. Restart the shell and Settings. Confirm positions and scales persist. Switch back to `Balanced` and confirm the previous rail ordering is unchanged.
11. Confirm disabled widgets stay unloaded. Ensure that moving widgets does not start additional media polling or background Quickshell processes.
12. Check `raohane doctor performance`, `raohane validate smoke` and `raohane logs` for QML errors, CPU/RSS growth and stale service state.
13. In a source checkout with dependencies, run `bash scripts/desktop-widget-boundary-audit.sh`, `bash scripts/raohane-audit.sh`, `bash scripts/runtime-payload-audit.sh`. CI also runs Qt `qmlformat` parsing.

## Rollback

- In Settings → Widgets, choose `Balanced` (or the previous preset); the old rail composition has not been deleted.
- To reset only the currently selected monitor's free placements, use **Reset monitor** within Free layout.
- To revert the configuration completely, restore the backup after stopping the shell, then restart. Do not restore an old config while a running writer can overwrite it.
- Source changes themselves can be reverted with ordinary Git history. Do not reset or force-push `main` to rollback on a user machine.

## Known limitations of this MVP

- Only the four pre-existing native widget types are available; more widget faces are subsequent phases.
- This is a preview-based editor, **not** direct on-desktop dragging. The controls persist normalized positions and size rather than arbitrary rotation or layered overlap order.
- The preview uses simplified static cards and estimates native widget dimensions; exact live geometry requires real-session confirmation.
- Multi-monitor behavior and full-screen/game performance still need live testing, and a passing static audit is not sufficient to call the build stable.

See [Serpantinum reference and the longer-term roadmap](SERPANTINUM-REFERENCE.md).
