# Raohane Halo Bar — validation and rollback

The **Halo** preset adds a long floating adaptive-glass capsule to the existing
native horizontal Bar. It is an **opt-in preset**, not a second Wayland panel or
another bar service. All existing module actions, multi-monitor behavior,
auto-hide/fullscreen handling and presets remain available.

## Visual changes

- One 46px capsule with 24px outer horizontal margins and a 23px radius.
- Three collision-safe module zones on top of the same glass surface.
- Small round workspace controls bound to real Hyprland workspaces.
- Native clock and context in the center; tray, system and Control Center
  on the right. Context retains media/recording/privacy attention styling.
- Minimal 1px separators appear only on wider outputs (>=1100px).
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

## Smoke checks — fish shell

```fish
cd ~/raohane-dots
git pull --ff-only
bash scripts/bar-boundary-audit.sh
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
