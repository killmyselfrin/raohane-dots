# Raohane Flow — visual system

Raohane Flow is the native visual system for the Raohane desktop shell.
It aims to balance a calm, cohesive interface with predictable Quickshell
performance on ordinary Wayland systems.

All UI implementations should use Raohane-owned QML components and the
existing shared service contracts. Do not introduce third-party code, art,
fonts or binary shaders without first checking their licenses and recording
any legally required notices in the appropriate license files.

## Shared material contract — phase 1

- **Palette:** deep charcoal with a subtle plum cast, subdued lavender
  accents, clearly distinguished secondary text and muted status colors.
- **Shape:** modular islands, softly rounded panels, consistent padding
  and restrained one-pixel hairline reflections.
- **Material:** translucency comes from `RaohaneTheme.glassOpacity` and the
  `RaohaneSurface` state machine. Base usability must not depend on
  continuous wallpaper capture, expensive fragment shaders or
  full-screen blur. Compositor blur is optional and requires dedicated
  NVIDIA/Wayland and fullscreen testing.
- **Components:** Bar, Control Center, Settings, Launcher, Media, Dock,
  Notifications and desktop widgets use shared theme, motion and control
  tokens instead of isolated magic colors or duplicated state owners.
- **Customization:** the existing `raohane-dark` preset adopts Raohane
  Flow without overwriting user settings. Alternate presets, accent choices,
  reduced-motion preferences and custom Style Studio values remain available.
- **Delivery:** this initial change concerns shared visual materials, not
  a complete layout redesign or a guarantee of compositor behavior.

## UI roadmap

1. **Bar:** modular grouping, hover/focus states, workspace indicators,
   tray alignment, responsive sizing and multi-monitor recovery.
2. **Settings & Control Center:** clear navigation, balanced responsive
   cards and a single owner for each audio/network/Bluetooth control.
3. **Media:** consistent artwork, transport, progress, visualization, lyrics
   and an overlay that suspends unnecessary work when hidden.
4. **Desktop:** wallpaper-aware widgets, accessible text contrast and
   unified calendar/system/media tiles.
5. **Motion:** shared enter/exit cadence, opt-outs for Reduced Motion and
   Gaming Mode, and no off-screen animation loops.
6. **Website:** align public presentation and capture genuine screenshots
   only after the actual shell layout passes runtime validation.

## Runtime acceptance before merging

Verify behavior in an actual Hyprland session with 1920 × 1080 and compact
logical outputs, fractional scaling and fullscreen applications. Exercise
Keyboard/Mouse focus, contrast, accessibility, notification timing, panel
recovery, CPU/RSS during an extended session, GPU load and QML diagnostics.
Compare real screenshots against the desired Raohane Flow composition.
Static CI is necessary, but not a substitute for these tests.
