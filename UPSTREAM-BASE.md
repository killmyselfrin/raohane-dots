# Raohane upstream foundation

Raohane now uses **pctrade/end4-pC** as its GPL-3.0 technical foundation and will progressively transform that foundation into the Raohane product.

## Pinned baseline

- Repository: `https://github.com/pctrade/end4-pC`
- Upstream branch observed: `main`
- Pinned commit: `369554b62de8d659875de828c779b83b28ae9ada`
- Upstream commit timestamp: `2026-08-24T19:04:43Z`
- Upstream project: end4-pC, itself derived from end-4/dots-hyprland / illogical-impulse
- License: GPL-3.0

This SHA is deliberately pinned. Foundation imports must not silently follow a moving `main` branch.

## Migration policy

1. Import the complete working end4-pC shell foundation first.
2. Verify the imported baseline before destructive renames or redesign.
3. Preserve upstream licensing, attribution, third-party notices and modification history.
4. Preserve mature upstream backends until a Raohane replacement is verified.
5. Apply Raohane runtime/doctor/GPU/display improvements on top of the working baseline.
6. Transform visible UI progressively into the Raohane design system.
7. Do not bundle font files; use distribution/AUR packages for font dependencies.

## Reproducible import

Use:

```bash
./scripts/import-end4-foundation.sh
./scripts/import-end4-foundation.sh --apply
./scripts/audit-foundation.sh
```

The first command is a dry-run/inspection. `--apply` performs the synchronized import after explicit confirmation and keeps a migration snapshot of selected pre-reset Raohane work under `migration/legacy-raohane/`.
