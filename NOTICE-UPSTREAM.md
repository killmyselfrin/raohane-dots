# Upstream notice

Raohane currently contains GPLv3-covered derivative/migration code from earlier development stages.

## Current migration sources

During development Raohane has studied and/or retained code from:

- `pctrade/end4-pC`
- `end-4/dots-hyprland` / illogical-impulse
- `snowarch/iNiR`

These projects are **not** intended to remain permanent runtime, installation, update, or development dependencies of Raohane.

## Standalone target

The target Raohane repository owns its UI, service adapters, configuration/common framework, dependency manifest, scripts and release process. Upstream shell repositories become references only and are not required to install or run Raohane.

Migration code under `modules/ii`, inherited services/common code, upstream lock files, the end4 synchronization helper and the illogical-impulse dependency bootstrap are temporary and are scheduled for removal/replacement as defined in `INDEPENDENCE-PLAN.md`.

## Licensing / attribution

Technical independence does not automatically erase copyright or license obligations for code that was copied or modified from another GPL project. While derivative code remains, the GNU GPLv3 license and applicable upstream notices must remain intact.

The correct path to reducing this lineage is to replace inherited implementations with independently written Raohane code and then remove code/notices only when they are no longer applicable. Do not remove required third-party notices merely to make the repository appear independent.

Separate assets, shaders, helper projects, integrations, icons or themes can also carry their own licenses and attribution requirements.

## Raohane-owned direction

Raohane-specific work includes its product identity, Japanese/minimal dark-glass direction, Context Island, native bar/launcher/control/settings/media/OSD/notification/desktop/session surfaces, hardware/bootstrap diagnostics, graphics/display planning and the standalone architecture defined in `INDEPENDENCE-PLAN.md`.

This notice documents current source provenance during migration; it is not a statement that Raohane must remain architecturally tied to those projects.
