# Upstream notice

Raohane is a standalone Hyprland + Quickshell shell at runtime, but parts of the repository still carry GPL-covered source/data lineage from earlier migration work. Runtime independence does **not** erase copyright, license or attribution obligations for retained or modified material.

## Historical migration sources

Raohane development studied, imported and/or modified material from:

- `pctrade/end4-pC`
  - foundation pin used during migration: `369554b62de8d659875de828c779b83b28ae9ada`
- `end-4/dots-hyprland` / illogical-impulse
  - system/dependency foundation pin used during migration: `42d0aae17b744a38cd05c9044c189bfc9b13869a`
- `snowarch/iNiR`

Those projects are provenance/reference sources. They are not required as cloned repositories to install, start or update the current Raohane runtime.

## Current standalone boundary

The active shell graph is Raohane-owned:

- `shell.qml` boots `panelFamilies/RaohaneFamily.qml`;
- active product code lives under `modules/raohane/`;
- native configuration is stored through the Raohane config/path APIs;
- normal installation uses Raohane-owned dependency manifests and scripts;
- retired migration trees such as `modules/ii`, inherited root `services`, compatibility common modules and upstream bootstrap/sync trees are no longer part of the active source/runtime graph.

The repository keeps explicit audits to prevent those runtime dependencies from being reintroduced.

## Retained data and assets

Standalone runtime ownership does not mean that every repository byte was independently authored from a blank file. In particular, retained data and modified resources under areas such as:

- `assets/`
- `translations/`
- `defaults/`

may include material inherited, adapted or reorganized from earlier foundation work or from separate third-party projects. These resources remain subject to the applicable copyright/license terms of their sources where those terms apply.

Do not remove attribution solely because a resource no longer depends on an upstream runtime module. When replacing retained material, verify provenance and licensing of the replacement independently.

Font binaries are intentionally not vendored by Raohane; required fonts are package-managed. Separate icons, shaders, prompts, translations, helper integrations, themes and other assets can have licensing requirements distinct from the shell's own source files.

## Licensing / attribution

Raohane is distributed under the GNU GPLv3 for GPL-covered derivative source in this repository. The root `LICENSE` remains authoritative for the project license.

Technical rewrites can reduce architectural dependence, but they do not retroactively remove rights or notices attached to code or data that remains copied or modified. Applicable upstream and third-party notices must therefore be preserved for as long as the corresponding material remains in the project.

This file records known repository provenance and the current technical boundary. It is not a claim that every individual asset has been legally reclassified as Raohane-original work.

## Raohane-owned direction

Raohane-specific work includes the product identity, Japanese/minimal dark-glass design direction, Context Island, native bar/launcher/control/settings/media/OSD/notification/desktop/session surfaces, Raohane-owned services/configuration framework, hardware/bootstrap diagnostics, graphics/display planning and the standalone release/runtime architecture.
