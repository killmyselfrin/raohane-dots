# Running-interface captures

Captured 2026-11-11 from source commit `a038d025024a5aeee9a70a55de183ed469478ac5`.
These are direct, unretouched `grim` captures, not generated UI concepts.

- Output: 1920 × 1080 logical pixels, scale 1, no fullscreen application.
- Runtime: Quickshell 0.3.2 / Qt 6.11.2, Sway headless with pixman,
  `QT_QUICK_BACKEND=software`, in the isolated Debian diagnostic container.
- GPU: none exposed. Hyprland could not initialize its rendering backend.
- Theme: Raohane; panel: Orbit. Russian interface; desktop clock uses lab time.
- No mock media player or synthetic lyrics were used in these captures.
- CPU/RSS and frame timing were not measured for this capture set.

| File | Surface |
| --- | --- |
| desktop.png | Bar, clock, idle media card and desktop system widget |
| welcome.png | First page of the persistent setup wizard |
| settings.png | Theme library and wallpaper category cards |
| control-center.png | Control Center with actual container device availability |

These demonstrate the rendered UI only. Hyprland focus/shortcuts, compositor
blur, hardware controls, multi-monitor behavior and GPU costs remain separate
validation gates. Known baseline Privacy warnings and the umbrella desktop
widget audit failure are recorded in the linked validation notes.

## Artwork credits

The forest background is **Path**, by **Risto Saukonpää**, from KDE Plasma
Workspace Wallpapers, licensed LGPLv3. Source, original file and license are
included in [the bundled collection](../wallpapers/README.md) and its catalog.
Other wallpaper thumbnails retain their individual source credits in that catalog.
The Settings anime thumbnail comes from the optional personal collection listed
in [online-anime.json](../wallpapers/online-anime.json); original artwork rights
remain with its creators. The feather-nova emblem is AI-generated Raohane artwork;
its simplified SVG companion and provenance are described in [NOTICE-UPSTREAM](../../NOTICE-UPSTREAM.md).
