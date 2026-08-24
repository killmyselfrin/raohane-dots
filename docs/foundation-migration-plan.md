# Raohane foundation migration plan

This branch is intentionally a foundation reset, not a finished Raohane release.

## Baselines

- Shell/UI baseline: `pctrade/end4-pC@369554b62de8d659875de828c779b83b28ae9ada`
- System/dependency baseline: `end-4/dots-hyprland@42d0aae17b744a38cd05c9044c189bfc9b13869a`

## Stage 0 — imported upstream baseline

Goal: prove that the imported end4-pC shell remains complete before redesign.

Do not mass-rebrand `ii`/end4 identifiers yet. Existing upstream runtime names are compatibility boundaries until the shell launches on the target Hyprland session.

User validation required:

```bash
mkdir -p ~/.config/quickshell
rm -rf ~/.config/quickshell/raohane-foundation-test
cp -a /path/to/raohane-dots ~/.config/quickshell/raohane-foundation-test
qs -p ~/.config/quickshell/raohane-foundation-test/shell.qml
```

If the user's installed Quickshell expects named configs, test the branch from a clone/symlink inside `~/.config/quickshell/` and launch it directly before replacing the working session.

Capture QML/runtime errors before any destructive migration.

## Stage 1 — package and environment parity

Use `upstream/illogical-impulse-system/sdata/dist-arch` as the authoritative coverage source.

Build Raohane package profiles without reducing feature coverage:

- core/runtime
- Quickshell/Qt
- Hyprland/Wayland
- portals/polkit/keyring
- PipeWire/WirePlumber/media
- NetworkManager/Wi-Fi
- BlueZ/Bluetooth
- brightness/power
- screenshot/recording/OCR
- clipboard/input helpers
- widgets/tooling
- themes/fonts-as-packages
- graphics diagnostics
- GPU-specific profiles

Retain required/optional, official/AUR, build/runtime and service/socket metadata.

## Stage 2 — Raohane runtime namespace

Introduce compatibility-first Raohane runtime:

- `qs -c raohane`
- `raohane.service`
- `raohane` CLI
- `~/.config/raohane`
- IPC aliases

Do not break upstream services/config reads until migrated consumers are verified.

## Stage 3 — doctor + hardware bootstrap

Port the useful ideas from the pre-reset prototype snapshot:

- dependency doctor
- graphics detector
- NVIDIA legacy/modern split
- AMD/Intel profiles
- kernel header detection
- DRM/KMS diagnostics
- monitor refresh/mode detection
- audio/network/Bluetooth/portal doctor

GPU driver mutation must remain opt-in and explicit.

## Stage 4 — Hyprland-only product cleanup

Only after the baseline runs:

- remove Niri runtime paths from active Raohane product code;
- keep migration history intact;
- create Raohane-managed Hyprland snippets instead of overwriting user config.

## Stage 5 — Raohane design system

Create shared tokens for spacing, radii, glass surfaces, typography, accent, states and motion.

Visual direction:

- Japanese minimalism
- dark translucent glass
- purple/magenta accent
- wallpaper/media-aware color
- floating composition
- organic but performant motion

## Stage 6 — UI transformation

Order:

1. Bar + Context Island
2. Control Center and system detail surfaces
3. Settings
4. Launcher + Overview
5. Notifications + OSD
6. Media/session/capture/lock surfaces

Working upstream backends remain until their Raohane replacement is tested.

## Stage 7 — standalone install

Raohane must no longer require a separately installed illogical-impulse environment.

The final installer should provision the equivalent dependencies/services/config integrations itself, then install and verify the Raohane Quickshell shell.

## Completion gate

A visual/system phase is not complete until it has been tested in a real Hyprland + Quickshell session. Static QML validity alone is insufficient.
