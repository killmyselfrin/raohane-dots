# Raohane

Raohane is a standalone Hyprland + Quickshell desktop shell.

## Current architecture

The active product runtime is Raohane-owned. Historical end4/illogical/iNiR code was used during migration, but another shell repository is no longer an installation, runtime, update or normal-development dependency.

Current source/runtime boundary:

- `shell.qml` boots `panelFamilies/RaohaneFamily.qml`;
- active QML/product code lives under `modules/raohane/`;
- Raohane owns service adapters, state, theme, reusable widgets/helpers/models and the persisted config/path framework;
- `defaults/native.json` is the current native schema baseline;
- `install/arch/*.txt`, `scripts/install-deps.sh` and `install-raohane.sh` are the supported install/dependency path;
- retired `modules/ii`, `modules/common`, root inherited `services`, upstream family fallbacks and sync/bootstrap trees must not be reintroduced.

Do not build new features against historical upstream shell namespaces. If mature behavior must be studied, use upstream repositories as references and implement the resulting product path through Raohane-owned APIs.

## Provenance and licensing

Historical migration/provenance sources include:

- `pctrade/end4-pC`
- `end-4/dots-hyprland` / illogical-impulse
- `snowarch/iNiR`
- `ilyamiro/serpantinum`

Preserve GNU GPLv3 obligations for covered derivative work. Runtime independence does not mean every retained asset, translation, default or historical implementation became independently authored.

- Keep `LICENSE` and `NOTICE-UPSTREAM.md` accurate.
- Preserve applicable upstream/third-party notices for retained code, data, assets, shaders, integrations, icons, prompts or themes.
- Do not remove attribution merely because an upstream runtime dependency was deleted.
- Do not bundle font binaries; fonts remain package-managed.
- Run `bash scripts/source-lineage-audit.sh` for provenance/release-boundary changes.

## Product target

- Hyprland only for the Raohane product target.
- Quickshell / Qt QML UI.
- New or rewritten product code belongs under `modules/raohane/` or another explicitly Raohane-owned root.
- Do not introduce Niri-specific product architecture.
- Do not restore compatibility bridges as a shortcut around a missing native implementation.

## Native framework rules

- Persisted product settings belong in `RaohaneConfig` and `defaults/native.json`.
- Filesystem/config/cache/state/runtime locations belong in `RaohanePaths`.
- Shared visual primitives belong in Raohane-owned framework components rather than ad-hoc copies.
- Complete color themes belong in the central `RaohaneTheme.presets` catalog and selected preset state belongs in `RaohaneConfig.themePreset`.
- Feature surfaces must consume shared theme tokens rather than embedding one-off light/dark/neon palettes.
- New system integrations should expose a Raohane-owned service/API boundary before being consumed across multiple surfaces.
- Keep expensive polling/event work centralized and demand-driven where possible.
- Preserve horizontal/vertical bar, fullscreen and multi-monitor contracts when touching shared shell state.

## Design direction

Raohane visual identity is now **Japanese minimalism** while preserving the established UI structure and interaction model.

- calm frosted-glass surfaces;
- light warm-gray / off-white default appearance;
- optional dark minimalist presets instead of a dark-only shell;
- thin low-contrast borders and restrained shadows/highlights;
- charcoal, stone, sage, blush and cool-gray accents rather than neon purple/magenta;
- generous negative space and quiet information hierarchy;
- floating Bar pods, Context Island and Dock remain signature geometry;
- wallpaper-aware atmosphere should be subtle and Japanese-inspired rather than cyberpunk-heavy;
- animation should be short, smooth and understated;
- semantic colors (recording, warning, success) may stand out, but decorative glow should not.

`Zen Mist` is the default visual preset. The Theme Library should offer multiple coherent whole-shell moods while keeping layout, shortcuts, services and behavior stable across presets.

References may inform behavior, but the final user-facing design must remain recognizably Raohane rather than a renamed upstream shell.

## Runtime validation rule

A UI/runtime task is not complete only because QML parses or static checks pass.

For changes that touch active shell behavior, verify when possible:

- `qs -c raohane` / the installed `raohane.service` starts cleanly;
- Settings opens and persists the changed setting;
- theme selection updates shared surfaces live and survives a restart;
- Launcher/Control Center/affected IPC routes still open;
- notifications/OSD/media remain functional when their shared services are touched;
- network/Bluetooth/audio/display backends still respond when changed;
- no critical QML runtime errors appear;
- no duplicate Quickshell instances or conflicting services are introduced.

For the current Phase 4 live boundary use:

```bash
raohane doctor phase4
raohane validate phase4 --full
```

The complete validator intentionally exercises real compositor/PAM/capture behavior. If the implementation environment cannot run Hyprland/Quickshell, do not claim those live gates passed; state the limitation and leave the corresponding roadmap items open.

## Package/dependency rule

Do not reduce package coverage to a small hand-written convenience list. Audit retained/native features against `install/arch/required.txt` and `install/arch/features.txt` and keep required versus optional/hardware-specific dependencies explicit.

GPU driver mutation must remain explicit and architecture-aware; never silently replace a working GPU driver.

## Release boundary

`VERSION` is the committed product version. Source releases are produced from committed `HEAD`:

```bash
bash scripts/package-release.sh
```

The packager runs the source-lineage and runtime-payload audits and emits a source archive plus SHA-256 checksum. `.github/workflows/release-boundary.yml` must continue to verify this path.

Do not create a release from a dirty tracked working tree or bypass provenance/runtime-payload validation to make an archive pass.

## Before finishing

Run the relevant focused audit plus the umbrella audit:

```bash
bash scripts/raohane-audit.sh
```

For release/provenance work also run:

```bash
bash scripts/source-lineage-audit.sh
bash scripts/runtime-payload-audit.sh
bash scripts/package-release.sh
```

Also run `bash -n` on touched shell scripts and validate `qmldir`/local QML imports. For active UI changes, treat real Hyprland runtime validation as a separate required gate rather than substituting static CI for it.
