# Raohane independence plan

Raohane's target state is a standalone Hyprland + Quickshell shell that does not require end4-pC, illogical-impulse, iNiR, Serpantinum or any other shell repository at runtime, install time, update time, or development time.

Upstream projects may be studied as references during development, but the final Raohane repository must own its runtime architecture, dependency manifest, configuration schema, services, UI, scripts, documentation and release process.

## Definition of independent

Raohane is considered independent when all of the following are true:

- installation does not clone or execute another shell repository;
- no runtime module imports `modules/ii` or another upstream shell namespace;
- no production code depends on an upstream sync script or pinned upstream lock file;
- Raohane has its own package/dependency manifest and installer;
- Raohane owns its Config schema and persistent-state contract;
- Raohane owns system-service adapters for audio, media, network, Bluetooth, brightness, notifications, wallpapers and compositor data;
- Raohane owns all visible surfaces, including bar, overview, background/widgets, dock, lock, capture tools, session/polkit and settings;
- CI validates only Raohane-owned runtime code;
- upstream code retained for migration is removed after equivalent Raohane-native code is verified;
- required third-party license/attribution notices remain for any code/assets that are still derivative or redistributed.

## Migration phases

### Phase A — Product surfaces

Replace active compatibility UI while keeping proven backend behavior temporarily. This phase includes bar, launcher, control center, settings shell, media overlay, OSD, notifications, wallpaper selector, desktop menu, session menu, overview, dock, lock, capture and desktop widgets.

### Phase B — Service ownership

Replace inherited service implementations with Raohane-owned adapters behind stable interfaces. Priority order:

1. compositor/workspace/window state;
2. MPRIS/media;
3. audio/PipeWire;
4. network and Bluetooth;
5. brightness/gamma;
6. notifications;
7. wallpapers/thumbnails;
8. session/idle/system information;
9. clipboard/capture/translation/optional online services.

UI must talk to Raohane service interfaces so a backend rewrite does not require another UI rewrite.

### Phase C — Config/common ownership

Replace inherited Config, Appearance, models, utility widgets and common helpers with Raohane-owned equivalents. Move persistent paths to Raohane namespaces and remove assumptions about illogical-impulse/end4 configuration.

### Phase D — Dependency independence

Replace the illogical-impulse dependency bootstrap with a Raohane package manifest. Dependencies should be grouped as required, feature-specific and optional. `raohane doctor deps` must report missing features without forcing unrelated packages.

### Phase E — Remove migration scaffolding

After runtime parity is verified:

- remove active `modules/ii` imports;
- remove `ii-upstream` fallback;
- remove `scripts/sync-end4-foundation.sh`;
- remove upstream lock files used only for source synchronization;
- remove the illogical-impulse dependency installer;
- remove unneeded inherited assets/scripts/modules;
- reduce CI to the standalone Raohane graph.

## Licensing boundary

Technical independence does not automatically erase source-code lineage. While GPL-derived code remains in the repository, the applicable GPL and upstream notices must be preserved. The way to reduce that dependency is to replace inherited code with independently written Raohane implementations, not simply remove attribution from copied code.

This document is a product/engineering target, not legal advice.
