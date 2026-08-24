# Foundation migration status

## Completed

- Imported complete pinned `pctrade/end4-pC` shell snapshot at `369554b62de8d659875de828c779b83b28ae9ada`.
- Preserved GPL-3.0 license and upstream attribution controls.
- Preserved selected pre-reset Raohane prototype files under `migration/legacy-raohane/`.
- Vendored pinned `end-4/dots-hyprland` system/dependency sources at `42d0aae17b744a38cd05c9044c189bfc9b13869a` under `upstream/illogical-impulse-system/`.
- Excluded font binaries from both imports.
- Added reproducible foundation import and audit automation.

## Not yet complete

- Live Hyprland/Quickshell validation on the target desktop.
- Raohane runtime namespace migration.
- Standalone package installer derived from upstream dependency coverage.
- GPU/display doctor port on top of the new foundation.
- Raohane visual transformation.

## Current rule

Do not merge this foundation branch into `main` as a finished release until the imported baseline has been run in a real target session and runtime errors have been captured/resolved.
