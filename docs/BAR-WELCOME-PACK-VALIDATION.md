# Bar, animated Welcome and wallpaper collection

## Result

Raohane uses its own Quickshell bar, not a Waybar process. Existing seven presets
remain; Orbit adds a centered 1040 px capsule, Ribbon a slim continuous panel,
and Ink a transparent module-only layout. All three use the existing persisted
bar settings, modules, service adapters and positions.

Fixed Context Island's extra background when the bar disables backgrounds or
uses a continuous panel. Privacy/recording priority still forces emphasis.
The bar preview now distinguishes a continuous panel from three pill zones and
honors background-off for module previews. Updated stale source assertions in
the bar audit and fixed an rg invocation that treated a leading '-' as a flag.

Welcome has a finite 4 second intro followed by persistent five-page initial
setup (welcome, theme, wallpaper, bar, finish). Completion requires the final
page's explicit action; Escape returns to the previous page. Reduced motion and
Gaming Mode bypass the intro. A textured feather-nova emblem appears in Welcome,
with a simplified SVG mark for the bar. See WELCOME-SETUP-VALIDATION.md for the
latest lifecycle checks. Language-picker focus ownership remains unchanged.

The primary local collection has 20 online mixed anime images, 20 nature images
and 20 abstractions. The bundled set also includes original offline alternatives
for anime. See `assets/wallpapers/README.md` for exact storage and rights.

## Validation in the cloud diagnostic session

- Wallpaper pack audit passed: bundled counts, image decoding/XML, minimum Full
  HD size, distinct hashes, provenance and license files. Original Git symlinks
  in KDE's resolution aliases were resolved to real image blobs before import.
- Downloaded all 20 online anime images and decoded them; replaced three small
  source candidates. Verified all primary 60 files are Full HD or larger.
- Ran the anime importer against a fresh directory and twice against the same
  config. Checksums passed, registration was idempotent and other settings were
  preserved. No online anime images are committed to this repository.
- All 10 bar presets applied using the real `applyPreset` implementation and
  were captured at 1920×1080. Orbit additionally rendered at 800×600. The bar IPC
  switched from horizontal to vertical and back successfully.
- Recorded intro frames covering the whole output and its transition into
  Welcome. `phase` progressed from intro to welcome. With motionScale=0 it
  returned welcome immediately; the test preference was restored.
- Physical input simulation is unreliable on this headless compositor, so
  click/key dismissal remains a target-session check.
- Bar, Welcome, theme-library, qmldir, source-lineage and runtime-payload audits
  and QML parsing were run; results are recorded in the task report.

Hyprland cannot initialize without a GPU in this machine. Screenshots/video use
Sway headless/pixman and Qt software rendering. Fullscreen/game transitions,
real shortcut/input routing and rendering costs need Hyprland hardware checks.
Previously observed RaohanePrivacy undefined bindings and the unrelated umbrella
DesktopWidgetHost Loader.source assertion remain baseline failures. No new bar
or Welcome QML errors were observed.
