# Serpantinum → Raohane adoption map

Raohane uses `ilyamiro/serpantinum` as a behavior and packaging reference, not as a runtime dependency. Every adopted feature must terminate in Raohane-owned QML, services, configuration and paths.

## Current position

Raohane already has native equivalents for the Serpantinum bar, launcher, media, notifications, lock, Polkit, wallpaper picker, volume OSD, network panel and system information. Replacing those surfaces wholesale would remove Raohane features such as Context Island, Spaces, Dock, Task Manager, screen translation, OCR, OSK and the fullscreen Command Deck.

| Serpantinum area | Raohane decision | Status |
| --- | --- | --- |
| Theme preset data | Convert to complete `RaohaneTheme` tokens | Adopted: 94 palettes |
| Theme import/export | Raohane-owned catalog and CLI | Adopted |
| Nix package + modules | Rewrite for Hyprland and Raohane paths | Adopted |
| Bar / side bar | Preserve Raohane pods and vertical bar; port missing controls individually | Native base complete |
| Launcher | Preserve Raohane multi-mode launcher; compare display and search controls | Native base complete |
| Media + CAVA | Preserve MPRIS/lyrics overlay; add optional low-cost visualization later | Planned |
| Desktop widgets/editor | Rebuild on the Raohane widget SDK and desktop canvas | Adopted: four native faces + arrange studio |
| First-launch guide | Build a short Raohane Japanese-minimal onboarding flow | Adopted: four-step persisted setup |
| Weather + calendar | Add native demand-driven services and bar/widget surfaces | Planned |
| Idle actions | Expose the existing Raohane idle service through native settings | Planned |
| Notification sounds/position | Add to native notification configuration | Planned |
| Digital wellbeing/timer | Adapt as optional Raohane utilities | Planned |
| Wallpaper web search | Reuse Raohane wallpaper/caching APIs; no Serpantinum scripts at runtime | Planned |
| Hyprland defaults | Compare bindings/monitor controls without overwriting user config | Planned |
| Niri/Sway configurations | Not part of the Hyprland-only product | Excluded |
| Serpantinum installer/updater/daemon | Raohane already owns installation, service and release boundaries | Replaced |
| Bundled font binaries | Keep fonts package-managed | Excluded |

## Adoption order

1. Theme/data and deployment foundations.
2. First-launch guide plus initial configurable widget composition. **Complete.**
3. Weather, calendar, idle and notification settings.
4. Extend the native widget editor with weather/calendar faces.
5. Optional media visualization, quick utilities and wellbeing.
6. Real Hyprland validation on NVIDIA, multi-monitor and fullscreen workloads.

Each layer must pass `scripts/raohane-audit.sh`. Active UI work also remains open until it passes the real Hyprland/Quickshell validation gates documented in `RELEASE-VALIDATION.md`.
