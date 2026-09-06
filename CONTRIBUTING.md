# Contributing to Raohane

Raohane targets Hyprland and Quickshell. See the [architecture guide](docs/ARCHITECTURE.md) for the module layout.

- Put product QML under `modules/raohane/` and use the shared UI components.
- Store persistent settings through `RaohaneConfig` and filesystem paths through `RaohanePaths`.
- Route system operations through the service APIs and keep background polling demand-driven.
- Preserve applicable copyright and license notices.
- Keep generated packages, caches, and local backups out of commits.

Before submitting a change, run the relevant feature audit and:

```bash
bash scripts/raohane-audit.sh
```

For packaging or installation changes, also run `bash scripts/runtime-payload-audit.sh`. Build source archives from a clean committed checkout with `bash scripts/package-release.sh`.

For UI or service changes, test the affected behavior in a real Hyprland session. Describe the problem, the resulting behavior, checks performed, and any validation that remains unavailable. Include relevant logs when reporting a failure. See [release validation](docs/RELEASE-VALIDATION.md) for hardware and session checks.
