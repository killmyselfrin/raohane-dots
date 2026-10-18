# Raohane Flow — visual direction

This is Raohane's own interpretation of the calm, modular desktop language seen
in [Serpantinum](https://github.com/ilyamiro/serpantinum). **Do not import
Serpantinum's AGPL-3.0 QML, shaders, art, font files, or bundled assets** to
implement this design. Study the *visual ideas* and author Raohane-owned
components using the existing Quickshell infrastructure.

Reference screenshots (upstream design, **not** Raohane output):

- [Serpantinum preview 1](https://github.com/ilyamiro/serpantinum/blob/master/docs/assets/previews/preview_1.png)
- [Serpantinum preview 2](https://github.com/ilyamiro/serpantinum/blob/master/docs/assets/previews/preview_2.png)
- [Serpantinum preview 3](https://github.com/ilyamiro/serpantinum/blob/master/docs/assets/previews/preview_3.png)
- [Serpantinum preview 4](https://github.com/ilyamiro/serpantinum/blob/master/docs/assets/previews/preview_4.png)

## Shared visual contract — phase 1

- Core palette: deep charcoal with a subtle plum cast, lavender accents,
  soft secondary text, muted semantic status colors.
- Shape language: round modular islands and softly rounded larger panels,
  consistent spacing and restrained 1px hairline reflections.
- Material: translucency is controlled by `RaohaneTheme.glassOpacity` and
  the existing RaohaneSurface state machine. Never require an expensive
  fragment shader, constantly captured wallpaper, or full-scene blur for basic
  usability. Compositor blur remains an **optional future enhancement**, tested
  separately for NVIDIA/Wayland and games.
- Reuse: Bar, Control Center, Settings, Launcher, Media, Dock, Notification
  surfaces and desktop widgets consume shared tokens; do not add duplicate
  service owners or create one-off local theme colors.
- The primary `raohane-dark` preset carries the new visual language so
  existing installs using it receive the redesign; other presets and user
  overrides remain independently selectable.
- Changes in this PR affect material only. They do **not** claim a complete
  UI replication, new features, or verified live screenshots.

## Next phases (tracked separately)

1. **Bar composition:** align island spacing, workspace indicators, tray
   grouping, module hover states and compact/multi-monitor behavior.
2. **Control Center + Settings:** coherent navigation rail, responsive cards,
   fewer redundant control groups and consistent content density.
3. **Music:** unified track artwork, transport, seek bar, audio visualization,
   lyrics and game-overlay appearance with idle work suspended.
4. **Widgets and wallpaper:** matching calendar/system/media tiles with
   wallpaper-aware but legible color contrast.
5. **Animations:** shared open/close cadence; honor Reduced Motion, Gaming
   Mode and fullscreen suppression.

## Runtime acceptance before merging

Test with the actual current shell on Hyprland, including a compact logical
output, a 1920x1080 desktop, fractional scaling and an active fullscreen game.
Verify QML warnings, CPU and RSS over an extended session, input/focus
behavior, active button contrast, reduced-motion mode and whether transparency
is supported by the compositor. Capture **real screenshots** for review; do
not substitute mock-ups. The website should use this language *only after*
the shell design is approved and runtime verified.
