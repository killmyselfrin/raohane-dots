# Raohane 0.11.0-foundation

This is the first test archive after resetting Raohane onto the pinned end4-pC /
illogical-impulse maturity baseline. It is intended for real Hyprland-session testing
before the final Raohane visual transformation.

## Major changes

- complete pinned `end4-pC` Quickshell foundation imported;
- pinned `end-4/dots-hyprland` system/dependency source retained for standalone package coverage;
- active config/state/cache/temp paths moved to Raohane namespaces;
- named Quickshell runtime: `qs -c raohane`;
- `raohane.service` and `raohane` CLI;
- generated dependency baseline from 14 upstream PKGBUILDs;
- 104 unique selected upstream runtime dependencies plus Raohane diagnostic extras;
- `raohane-deps` check/plan/install/build-meta flow;
- safe installer that never overwrites Hyprland config or silently replaces GPU drivers;
- existing Raohane runtime backup before replacement;
- read-only `raohane doctor graphics` for GPU/DRM/software-rendering/Vulkan/refresh diagnostics;
- read-only `raohane graphics plan` for Arch-family GPU package planning;
- standalone runtime path audit;
- GPL/upstream attribution preserved;
- no bundled font binaries.

## Important limitation

This is a **foundation migration build**. Internal `modules/ii` names and substantial
upstream UI remain on purpose. The next Raohane phase is the design-system/UI conversion:
Context Island, Raohane bar/control center/settings/launcher, motion and Hyprland-only cleanup.

Do not interpret the current upstream-looking surfaces as the final visual identity.

## First test

```bash
bash install-raohane-foundation.sh --check
bash scripts/raohane-deps summary
bash scripts/raohane-deps plan
bash scripts/raohane-doctor graphics
bash scripts/raohane-graphics plan
```

If those checks look correct and Quickshell is already installed:

```bash
bash install-raohane-foundation.sh --shell-only --start
```

For full dependency setup on an Arch-family system, review the plan and then use:

```bash
bash install-raohane-foundation.sh --with-deps
```

The dependency tool asks for explicit interactive confirmation before package changes.

## Recovery

The installer does not overwrite `hyprland.conf`. If an earlier Raohane runtime exists,
it is backed up under the user's Raohane state backup directory before replacement.

Use:

```bash
raohane status
raohane logs
raohane doctor all
```

for the first diagnostics after startup.
