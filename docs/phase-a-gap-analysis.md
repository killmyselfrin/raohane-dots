# Phase A — system foundation gap analysis

## Scope and method

This phase treats the end-4 Arch meta-package layout as a **coverage reference**, not
as a package list or implementation source. The review categories were base tools,
audio, backlight, fonts/themes, Hyprland, portals, toolkit helpers, widgets,
screencapture, and Quickshell/Qt. Network, Bluetooth, authorization/keyring, service
health, hardware conditions, and driver safety were then modelled explicitly because
they cross traditional package boundaries.

Direct retrieval of the reference repository was blocked by the implementation
environment's network proxy. Consequently, Phase A makes no claim of line-by-line
parity with its current PKGBUILDs; the named meta-package boundaries supplied in the
project brief were used as the coverage checklist. A future maintainer should repeat
the comparison when network access is available.

## Repository findings

Before Phase A, the installer only checked for `hyprctl` and `qs`, copied the source,
and created a user unit. It did not model packages, distinguish install profiles,
inspect services, classify hardware dependencies, or verify the resulting runtime.
The launcher referenced `scripts/raohane`, but that file and the audit script were not
present on the starting branch. The repository also has a legacy-heavy root QML graph;
that UI migration is deliberately outside this system-foundation phase.

## Gaps closed

- A version-controlled TSV manifest now records package identity, group, Arch package,
  requirement level, profiles, feature, capability, diagnostic, service/socket,
  source, notes, session requirement, and hardware condition.
- Minimal, recommended, and full profiles are resolved from the same manifest.
- The bootstrapper detects distribution, kernel, GPU binding, DRM nodes, OpenGL,
  Vulkan, Hyprland, and Quickshell before printing a package plan.
- Official packages and AUR/manual packages are separated. GPU driver groups are
  always excluded from automatic installation.
- Runtime installation consistently uses `qs -c raohane`, creates a single user
  service, and verifies multiple subsystems rather than accepting `qs` alone.
- Doctor sections cover dependencies, graphics, display, audio, network, Bluetooth,
  portals, and UI/IPC. Bluetooth without hardware is intentionally a warning.

## Package groups

The manifest contains: `raohane-core`, `raohane-quickshell-qt`,
`raohane-hyprland-wayland`, `raohane-portals`, `raohane-polkit-keyring`,
`raohane-audio-media`, `raohane-network`, `raohane-bluetooth`,
`raohane-backlight-power`, `raohane-capture`, `raohane-input-clipboard`,
`raohane-widgets-tools`, `raohane-theming`, `raohane-graphics-common`,
`raohane-graphics-nvidia-legacy`, `raohane-graphics-nvidia-modern`,
`raohane-graphics-amd`, and `raohane-graphics-intel`.

Qt packages were limited to capabilities visible in the current root QML imports or
known Quickshell runtime needs. Positioning, Sensors, QuickTimeline, and Kirigami were
not added because the current primary graph does not import them. They should enter
the manifest only alongside an actual feature and diagnostic.

## Deliberate exclusions

- No end-4 source, branding, layout, palette, package names, or identity was copied.
- No Niri, iNiR, Waffle, Ricelin, or legacy sidebar dependency was introduced.
- No NVIDIA `.run` installer, automatic GPU driver selection, kernel-module mutation,
  or hybrid-GPU reconfiguration is performed.
- KDE applications, AI tooling, gaming packages, and broad “nice to have” collections
  are not dependency defaults. A package must map to a Raohane capability.
- The installer does not overwrite monitor configuration or the user's primary
  Hyprland configuration; it adds two idempotent source statements only.

## Known limitations and next phase

Phase B must provide the interactive graphics plan/install workflow, architecture-aware
PCI mapping, matching kernel-header selection, hybrid-GPU safeguards, DRM/KMS details,
and the complete display backend with advertised-mode validation. Doctor currently
reports display availability but does not yet compare the current refresh rate with
advertised modes. Audio, Wi-Fi, and Bluetooth manipulation commands and their QML
consumers remain subsequent backend/UI work.

This container is not an Arch Hyprland graphical session, so package installation,
user-session services, live QML startup, IPC, and visual screenshots cannot be validated
here. They must be checked on a target Arch/CachyOS session after reviewing the plan.
