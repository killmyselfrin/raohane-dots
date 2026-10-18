# Raohane Halo Bar — validation and rollback

The **Halo** preset adds a long floating adaptive-glass capsule to the existing
native horizontal Bar. It is an **opt-in preset**, not a second Wayland panel or
another bar service. All existing module actions, multi-monitor behavior,
auto-hide/fullscreen handling and presets remain available.

## Visual changes

- One centered capsule capped at 1240px, 44px high with 24px outer
  horizontal margins and a 22px radius. The full-width red strip has been
  replaced with quieter, wallpaper-tinted elevated glass.
- Three collision-safe module zones on top of the same glass surface.
  The center reserves a hard width budget and the side zones cannot draw over
  it. Long track names are elided inside a compact context.
- Small round workspace controls bound to real Hyprland workspaces.
- Native clock and context in the center; tray, system and Control Center
  on the right. Context retains media/recording/privacy attention styling.
- Minimal 1px separators appear only on wider outputs (>=1100px).
  At narrower output widths, secondary date text, workspaces and tray entries
  compress progressively without moving the central clock away from the
  physical screen center.
- Accent border and catch light consume shared `RaohaneTheme` colors, including
  Wallpaper Studio's optional adaptive wallpaper palette.
- No new polling, GPU blur shader or persistent background process.

## Enable

Open **Settings → Bar Studio → Presets → Halo**.

The preset selects the horizontal orientation and this initial module layout:
`left = launcher, workspaces`, `center = clock, context`,
`right = tray, system, control`.

You can rearrange, remove and add modules through the existing Bar Layout
editor. Picking any previous preset restores its previous visual style,
without removing its availability.

To adapt the glass to the wallpaper, open **Wallpaper Picker → Studio →
Adaptive on**. Halo also works with manual themes and adaptive color OFF.

## Other presets (same geometry engine)

- **Classic:** edge-hugging groups, consistent compact spacing.
- **Floating:** three balanced glass islands with softer shadows.
- **Cinematic:** slightly larger rounded islands and a modest accent line.
- **Islands:** separated functional module cards with wider gaps.
- **Compact:** shorter 38px pods, fewer visible details and quick access to
  primary actions.
- **Panel:** continuous edge-to-edge system surface, with the same central
  reservation logic.

The layout is bounded by a shared set of width and density rules, not a
new set of components for each preset. Even custom module sequences are
clipped within their zones instead of painting on top of other modules.
The native three-zone layout editor remains authoritative.

## Chromatic Flow — optional wallpaper gradient

Open **Settings → Bar Studio → Chromatic Flow** and enable
**Wallpaper gradient**. The control is **OFF by default** and does not change
the current wallpaper or the manual theme. It works independently of
Wallpaper Studio's **Adaptive Colors** toggle.

- The existing bounded wallpaper palette worker samples the **applied**
  image or a single FFmpeg video frame once and chooses two distinguishable
  hues that actually appear in the wallpaper.
- The 2-color glass wash works in **Classic, Float, Cinematic, Halo, Islands,
  Compact and Panel**. Separate islands share one animation phase per display.
- **Gradient intensity:** 5–45% opacity (default 20%). Text, status icons
  and click targets remain untouched and on top of the translucent overlay.
- **Flow duration:** 12–60 seconds for a full swap-and-return (default 28 s).
  No new service/polling timer is required.
- Animation pauses when the Bar is hidden, during fullscreen Game Mode, or
  if the shell's reduced-motion preference disables transform motion. The
  tint remains static if motion is disabled.

The two sampled colors are cached in existing native preferences, so the
bar can render immediately on the next login without decoding the same
wallpaper every frame. If decoding fails or the artwork is essentially one
color, the cached/fallback palette remains available.

## Smoke checks — fish shell

```fish
cd ~/raohane-dots
git pull --ff-only
bash scripts/bar-boundary-audit.sh
bash scripts/wallpaper-studio-audit.sh
# Geometry regression test includes sizes from 320 to 3840 logical px.
bash scripts/multimonitor-boundary-audit.sh
bash scripts/fullscreen-boundary-audit.sh
./install-raohane.sh --no-deps --no-login-theme --no-start
systemctl --user reset-failed raohane.service
systemctl --user restart raohane.service
journalctl --user -u raohane.service -b -n 80 --no-pager
```

After enabling the Halo preset, test workspace activation, tray menus, time,
music/recording context actions, right-hand indicators, Control Center,
adaptive wallpaper colors, a narrow output, multiple monitors and fullscreen
games. Check that the capsule never overlaps the clock or truncates the
workspace controls on your actual scale factor.

## Rollback

Open **Settings → Bar Studio → Presets → Floating** (or Cinematic). The Halo
preset does not rewrite the default native theme, vertical bar layout or
wallpaper configuration.

These source checks do not prove that an installed Quickshell/Hyprland session
has rendered correctly. Verify the new style in the actual session before
treating it as visually final.
