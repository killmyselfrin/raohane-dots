# Raohane / ラオハネ

Raohane is a Hyprland + Quickshell desktop shell in active migration toward a standalone,
Raohane-native system. This branch uses the mature `end4-pC` / `illogical-impulse`
architecture as its working foundation while the visible identity, runtime paths,
installer, diagnostics and later UI are migrated to Raohane.

> **Build status:** `0.11.0-foundation` is a testable migration build, not the final
> visual Raohane release. Some internal QML module names and upstream UI are intentionally
> retained until the foundation is proven stable on a real Hyprland session.

## What is already Raohane-owned

- Quickshell config name: `raohane` (`qs -c raohane`)
- installed runtime: `~/.config/quickshell/raohane`
- user config: `~/.config/raohane`
- user state/cache/temp paths use Raohane namespaces
- user service: `raohane.service`
- CLI: `raohane`
- dependency baseline/installer and read-only doctor tools
- active runtime no longer hardcodes `~/.config/illogical-impulse`

## Foundation sources

Raohane currently derives its migration baseline from pinned upstream revisions:

- `pctrade/end4-pC` — `369554b62de8d659875de828c779b83b28ae9ada`
- `end-4/dots-hyprland` — `42d0aae17b744a38cd05c9044c189bfc9b13869a`

See `NOTICE-UPSTREAM.md`, `UPSTREAM-BASE.md`, `SYSTEM-UPSTREAM-BASE.md`, `LICENSE`,
and `docs/upstream/end4-pC-README.md` for provenance and attribution.

## Safe first test

Run these from the extracted Raohane directory:

```bash
bash install-raohane-foundation.sh --check
bash scripts/raohane-deps summary
```

On Arch-family systems you can inspect what would be needed without installing anything:

```bash
bash scripts/raohane-deps plan
```

The dependency installer intentionally requires an interactive confirmation. Generic
dependency installation does **not** install or replace GPU drivers.

## Graphics / 60 Hz diagnostics

Before changing a GPU driver or monitor configuration, run the read-only diagnostics:

```bash
bash scripts/raohane-doctor graphics
bash scripts/raohane-graphics plan
```

After Raohane is installed, the equivalent commands are:

```bash
raohane doctor graphics
raohane graphics plan
```

The doctor checks the active kernel graphics driver, NVIDIA DRM/KMS when applicable,
OpenGL software-rendering fallbacks, Vulkan availability, Hyprland monitor modes and
the common case where the current mode is around 60 Hz while a higher refresh mode is advertised.
It never installs a driver and never writes a monitor configuration.

## Install the test foundation

If the dry checks look correct and Quickshell is already available:

```bash
bash install-raohane-foundation.sh --shell-only
raohane start
```

For the full pinned dependency foundation on a supported Arch-family system:

```bash
bash install-raohane-foundation.sh --with-deps
```

Package changes are shown first and require the literal interactive confirmation requested
by the dependency tool.

The installer:

- does not overwrite `hyprland.conf`;
- does not replace a GPU driver;
- backs up an existing Raohane runtime before `rsync --delete`;
- does not silently import an old `~/.config/illogical-impulse/config.json`;
- installs the shell as the named Quickshell config `raohane`;
- installs/enables `raohane.service` but does not start it unless requested.

To install and immediately start after the checks:

```bash
bash install-raohane-foundation.sh --shell-only --start
```

## Useful commands

```text
raohane run
raohane start
raohane stop
raohane restart
raohane status
raohane logs
raohane settings
raohane deps summary
raohane deps check
raohane deps plan
raohane doctor all
raohane doctor graphics
raohane graphics detect
raohane graphics plan
raohane foundation-audit
```

## Migration rule

Do not bulk-rename `modules/ii`, QML singleton identifiers or other internal upstream names
just to make the tree look branded. The migration order is runtime correctness first,
then Hyprland-only cleanup, then Raohane design-system/UI replacement. This avoids turning
a mature working foundation into a visually renamed but broken shell.

## License and credits

Raohane keeps the inherited GPL licensing and upstream attribution. The project does not
bundle font binaries; required fonts/themes are represented through package dependencies.
