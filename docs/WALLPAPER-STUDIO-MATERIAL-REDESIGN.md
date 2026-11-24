# Wallpaper Studio — Material layout and transitions

The Settings navigation exposes a dedicated **Wallpapers** page. It follows the visual hierarchy of the supplied reference: a current-wallpaper hero, a directory row, a Random / Custom set selector, and a three-column transition gallery that collapses to two or one columns on narrower windows.

## Shared wallpaper pipeline

- The hero reads the active path from `RaohaneConfig.wallpaperPath` and uses the existing generated video poster for video wallpapers.
- Select wallpaper opens the existing wallpaper selector; folder selection uses a native folder dialog and the existing `RaohaneWallpapers.setDirectory()` validation path.
- Transition mode and effect are persisted in the existing `native.json` wallpaper object. No second settings file or wallpaper daemon is introduced.
- The same `RaohaneWallpaperTransitionEffect.qml` component is used by the preview cards and the desktop background renderer.

## Transition modes

- **Random** selects one of the available effects for each confirmed wallpaper change.
- **Custom set** uses the effect selected in the gallery.
- **Fade** crossfades the incoming still image.
- **Wipe** reveals the incoming image from left to right.
- **Circle** uses a centered alpha-mask reveal through Qt Quick Effects.
- **Dissolve** reveals a bounded 8×5 set of image tiles in a deterministic staggered order.

Video wallpapers retain the existing muted `MediaPlayer` path and use the selected reveal component only for still-image content; the video layer keeps the existing opacity transition. This avoids duplicating or restarting the video pipeline for preview cards.

## Optional Matugen palette provider

Wallpaper Studio includes an optional **Matugen · Material You** palette provider alongside the built-in Raohane extractor.

- Install Matugen separately; on Arch Linux / CachyOS the upstream README documents `sudo pacman -S matugen`.
- Select **Matugen · Material You** in Settings → Wallpapers → Dynamic color engine.
- The provider supplies the color pair consumed by the existing wallpaper Adaptive Accent and Bar Chromatic Flow features; enable one of those features to see the generated colors applied. The built-in provider remains the default.
- Raohane invokes `matugen image <wallpaper> --json hex --dry-run` through an argument array (no shell interpolation). `--dry-run` prevents Matugen's own templates and wallpaper command from taking over Raohane's wallpaper pipeline.
- If Matugen is missing, returns an unsupported JSON payload, or fails, the adapter logs a warning and falls back to the existing `wallpaper-palette.py` extractor.
- The Matugen adapter exports the Material You dark and light schemes as validated role maps. Enable **Apply full Material You palette** to map primary/secondary/tertiary, backgrounds, surface containers, outlines, text contrast and error roles into RaohaneTheme. Existing Raohane presets remain the fallback for any role not emitted by Matugen.
- The full-palette toggle is independent of Adaptive Accent: the former recolors the full shell, while the latter remains available as an accent-only mode. The Bar Chromatic Flow colors continue to use the extracted primary/secondary pair.
- Matugen v4 JSON is read from `colors.dark` and `colors.light`; only known Material roles and six-digit hex colors are accepted into native.json. Invalid or missing roles are ignored, not blindly applied.
- The adapter does not replace the full Raohane theme-token system or overwrite user Matugen configuration/templates.

## Validation

Run:

```bash
bash scripts/wallpaper-studio-audit.sh
bash scripts/runtime-payload-audit.sh
```

Then validate in a live Quickshell session:

1. Open Settings → Wallpapers and confirm the active wallpaper, file name and path.
2. Select a different wallpaper and confirm the existing selector applies it without a black decode flash.
3. Change the folder and verify only readable image/video files populate the existing library.
4. Switch between Random and Custom set, select every transition, restart Quickshell and confirm the mode/effect persist.
5. Change wallpapers repeatedly in Random mode and verify all four still-image effects render.
6. Test video wallpapers, multiple monitors, reduced motion, Game Mode, fullscreen hiding and a zero-millisecond transition duration.
7. Confirm the page remains usable at compact widths and with a long directory path.

Live compositor checks are still required; static source checks do not substitute for testing Qt Quick Effects availability and actual rendering on the target Quickshell build.
