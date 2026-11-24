# Running-interface captures

This folder contains direct, unretouched captures of the Raohane Quickshell
interface. They are **real application renders**, not generated mockups.

## Capture environment

- Captured: 2026-11-11
- Source revision: `a038d025024a5aeee9a70a55de183ed469478ac5`
- Output: 1920 × 1080 logical pixels, scale 1, no fullscreen application
- Runtime: Quickshell 0.3.2 / Qt 6.11.2
- Compositor: Sway headless with pixman
- Qt rendering: `QT_QUICK_BACKEND=software`
- Environment: isolated Debian diagnostic container; no GPU was exposed
- Theme: Raohane; panel preset: Orbit; Russian interface
- No mock media player or synthetic lyrics were used

| File | Captured surface |
| --- | --- |
| `desktop.png` | Bar, clock, idle media card and desktop system widget |
| `welcome.png` | First page of the persistent setup wizard |
| `settings.png` | Theme library and wallpaper category cards |
| `control-center.png` | Control Center with the device availability of the diagnostic container |

## Important limitations

These images document the UI as it rendered in that specific diagnostic
environment and source revision. They do **not** establish current visual
parity with later source changes, nor do they validate:

- Hyprland rendering on physical GPU hardware;
- compositor blur, frame pacing or GPU performance;
- real Wi-Fi, Bluetooth, audio, brightness and other hardware controls;
- multi-monitor placement, mixed scaling or fullscreen/game behavior;
- long-session resource usage or release stability.

A real target-system capture should be added after validating the same surface
on a live Hyprland session. Do not present concept artwork as a runtime capture.

## Artwork credits

The forest background is **Path**, by **Risto Saukonpää**, from KDE Plasma
Workspace Wallpapers, licensed LGPLv3. Source, original file and license are
included in [the bundled collection](../wallpapers/README.md).

Other wallpaper thumbnails retain their individual source credits in that
catalog. The Settings anime thumbnail comes from the optional personal
collection listed in [online-anime.json](../wallpapers/online-anime.json);
original artwork rights remain with their creators.

The feather-nova emblem is AI-generated Raohane artwork. Its simplified SVG
companion and provenance are described in [NOTICE-UPSTREAM](../../NOTICE-UPSTREAM.md).
