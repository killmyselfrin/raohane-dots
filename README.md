<div align="center">

# ラオハネ · Raohane

### A Japanese-minimal desktop shell for Hyprland

**Quickshell · Qt/QML · Arch focused · standalone runtime**

[![Version](https://img.shields.io/badge/version-0.10.0--dev-8b7cf6?style=flat-square)](VERSION)
[![Raohane audit](https://github.com/snuskidau/raohane-dots/actions/workflows/raohane-audit.yml/badge.svg?branch=main)](.github/workflows/raohane-audit.yml)
[![Release boundary](https://github.com/snuskidau/raohane-dots/actions/workflows/release-boundary.yml/badge.svg?branch=main)](.github/workflows/release-boundary.yml)
[![Hyprland](https://img.shields.io/badge/Hyprland-only-1f6feb?style=flat-square)](https://hypr.land/)
[![License](https://img.shields.io/badge/license-GPLv3-2f2f2f?style=flat-square)](LICENSE)

**A complete desktop experience — not just a bar.**

[Install](#installation) · [Features](#features) · [Themes](#themes) · [Commands](#commands) · [Validation](#validation) · [Roadmap](RAOHANE-ROADMAP.md)

</div>

---

## About

**Raohane** is a standalone desktop shell for **Hyprland**, built with **Quickshell and Qt/QML**.

It combines the pieces of a desktop environment into one coherent shell: bars, workspaces, a dock, launcher, Control Center, Settings, notifications, media controls, wallpapers, lock/session surfaces, overlays and system integrations.

The current visual direction is **Japanese minimalism** — quiet frosted surfaces, restrained accents, clean typography and a consistent shell-wide theme system.

Raohane owns its active UI, configuration, services and runtime paths. A normal installation does **not** clone or execute another desktop-shell repository.

> **Development status — `0.10.0-dev`**
>
> The standalone source/runtime boundary and static CI are complete. Real Hyprland validation is still required for hardware-, PAM-, fullscreen- and multi-monitor-specific behavior before a stable release.

---

## Features

| Desktop | System | Workflow |
| --- | --- | --- |
| Horizontal & vertical Bar | PipeWire audio | Native application launcher |
| Context Island | NetworkManager | Calculator / command modes |
| Floating application Dock | Bluetooth | Clipboard history search |
| Spaces / workspace Overview | Brightness / DDC / gamma | Screen translation |
| Wallpaper & video background | Privacy / capture state | Region screenshot / OCR / recording |
| Desktop context menu | Notifications & history | DropShelf |
| Screen frame & corners | Lock / PAM / fingerprint | On-screen keyboard |
| Media overlay | Polkit authentication | Session / power controls |
| OSD | System information | CLI + diagnostics |

### Shell surfaces

Raohane currently includes:

- **Bar** — horizontal and vertical layouts with workspaces, tray, status and Context Island;
- **Context Island** — contextual media, window and privacy state;
- **Dock** — pinned/running applications, multi-window focus, autohide and fullscreen-aware reveal;
- **Spaces** — native Hyprland workspace and window overview;
- **Launcher** — apps, built-in actions, commands, calculator and clipboard search;
- **Control Center** — network, Bluetooth, audio, display, privacy and notifications;
- **Settings** — grouped navigation, global search, Theme Library and native configuration;
- **Media Overlay** — MPRIS controls and lyrics in a fullscreen-friendly overlay;
- **Notifications** — popup cards, history and actions;
- **Wallpaper Selector** — image/video browsing, preview, random selection and slideshow support;
- **Session / Lock / Polkit** — native system surfaces for session actions and authentication;
- **OSK / Translator / DropShelf** — shell-native utility surfaces.

---

## Themes

Raohane uses one shared shell-wide theme engine. Theme selection is persisted through `RaohaneConfig` and applies live across the active UI.

Eight Raohane signature presets ship with the shell:

| Light / soft | Dark / muted |
| --- | --- |
| **Zen Mist** — default | **Sumi** |
| **Paper** | **Midnight** |
| **Sakura** | **Slate** |
| **Matcha** | **Sand** |

**Zen Mist** is the current default: warm off-white frosted surfaces, charcoal text, thin borders, quiet accents and restrained motion.

The Settings **Theme Library** provides live miniature previews and instant preset switching.

Raohane also ships Serpantinum's palette collection converted into the complete native Raohane token schema. The conversion retains palette provenance but does not load Serpantinum QML, services or configuration at runtime.

Custom native themes and additional Serpantinum palettes can be managed with:

```bash
raohane theme list
raohane theme import ./my-raohane-theme.json
raohane theme import-serpantinum ./serpantinum/src/assets/themes
raohane theme export serp-kanagawa ./kanagawa-raohane.json
raohane theme remove my-theme
```

Advanced styling is also centralized rather than hard-coded per component, including glass opacity, border strength, radius/density scale, motion, accent behavior and selected shell-surface sizing.

---

## Architecture

Raohane is organized around a small native framework and Raohane-owned services.

```text
Hyprland / Linux / Quickshell APIs
              │
              ▼
      Raohane services
              │
   ┌──────────┼──────────┐
   │          │          │
 Audio     Network     Media
 Display   Bluetooth   Privacy
 Notify    Wallpapers  Session
   │          │          │
   └──────────┼──────────┘
              ▼
        Raohane UI
              │
 Bar · Dock · Island · Settings
 Launcher · Control Center · Spaces
 Lock · Media · Notifications · Utilities
```

Persistent configuration lives in:

```text
~/.config/raohane/native.json
```

Core configuration APIs:

```text
modules/raohane/config/RaohaneConfig.qml
modules/raohane/config/RaohanePaths.qml
```

Shared UI primitives include:

```text
RaohaneSurface.qml
RaohaneDivider.qml
RaohaneIcon.qml
RaohaneIconButton.qml
RaohaneTheme.qml
```

For the deeper runtime and ownership model, see [`ARCHITECTURE.md`](ARCHITECTURE.md).

---

## Installation

### Arch Linux / Arch-based systems

Clone the current development branch:

```bash
git clone https://github.com/snuskidau/raohane-dots.git
cd raohane-dots
```

Install Raohane and its declared dependencies:

```bash
chmod +x install-raohane.sh
./install-raohane.sh --deps
```

Reload Hyprland and start the shell:

```bash
hyprctl reload
raohane restart
```

> The installer does not silently replace GPU drivers and does not vendor font binaries into the repository.

### NixOS + Home Manager

Raohane exposes both NixOS and Home Manager modules. The NixOS module enables the system services and package set; Home Manager installs the immutable runtime, seeds mutable native settings and owns the user service.

```nix
{
  inputs.raohane.url = "github:snuskidau/raohane-dots";

  outputs = { nixpkgs, home-manager, raohane, ... }: {
    nixosConfigurations.yourHost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        raohane.nixosModules.default
        home-manager.nixosModules.home-manager
        {
          programs.raohane.enable = true;
          home-manager.users.yourName = {
            imports = [ raohane.homeModules.default ];
            programs.raohane.enable = true;
          };
        }
      ];
    };
  };
}
```

### Update an existing installation

```bash
cd raohane-dots
git checkout main
git pull --ff-only

./install-raohane.sh
hyprctl reload
raohane restart
```

### Foreground debugging

```bash
raohane stop
raohane run
```

View logs with:

```bash
raohane logs
```

---

## Commands

### Open shell surfaces

```bash
raohane launcher
raohane control
raohane settings
raohane media
raohane desktop
raohane wallpaper
raohane session
raohane translate
```

Random wallpaper:

```bash
raohane wallpaper random
```

### Launcher modes

```text
firefox        application search
/settings      Raohane built-in actions
> command      shell command
= 2+2          calculator via qalc
: clipboard    clipboard history via cliphist
```

### Diagnostics

```bash
raohane doctor all
raohane doctor runtime
raohane doctor deps
raohane doctor services
raohane doctor graphics

raohane wifi status
raohane audio status
```

---

## Validation

Raohane has two separate validation layers.

### Static / CI

GitHub Actions validates:

- all Raohane-owned QML parses successfully;
- shell scripts and release helpers are valid;
- active runtime/config/service ownership stays standalone;
- horizontal/vertical bar, fullscreen and multi-monitor contracts remain intact;
- Settings, Lock/PAM, Polkit, OSK, notifications, wallpapers and capture surfaces retain their required boundaries;
- the shared visual/theme system does not silently regress;
- the release payload is reproducible and source lineage remains explicit.

Workflows:

- [`Raohane audit`](.github/workflows/raohane-audit.yml)
- [`Release boundary`](.github/workflows/release-boundary.yml)

### Real Hyprland session

CI cannot emulate every Wayland, GPU, PAM or hardware path. For a real-machine validation run:

```bash
raohane validate phase4 --full
```

Release-oriented validation is documented in [`RELEASE-VALIDATION.md`](RELEASE-VALIDATION.md).

The remaining release gates include:

- fresh Arch + Hyprland installation;
- lock/password/fingerprint behavior;
- NVIDIA and AMD/Intel validation;
- multi-monitor placement and focus;
- fullscreen/game overlay behavior;
- capture/OCR/translation/OSK/DropShelf live interaction.

---

## Project structure

```text
raohane-dots/
├── modules/raohane/
│   ├── config/          # persisted configuration + paths
│   ├── helpers/         # shared helpers
│   ├── models/          # reusable models
│   ├── services/        # native backend services
│   ├── osk/             # on-screen keyboard data
│   └── *.qml            # shell surfaces and framework
├── panelFamilies/
│   └── RaohaneFamily.qml
├── defaults/
│   └── native.json
├── install/arch/        # dependency manifests
├── scripts/             # CLI, diagnostics, validation, packaging
├── shell.qml
├── install-raohane.sh
└── VERSION
```

---

## Development status

`main` is the active integration branch while Raohane remains in development.

| Area | Status |
| --- | --- |
| Standalone active runtime | ✅ Complete |
| Raohane-owned services/config | ✅ Complete |
| Minimal shell-wide theme system | ✅ Complete |
| Static QML/runtime audits | ✅ Passing |
| Source release boundary | ✅ Passing |
| Real-session visual polish | 🚧 In progress |
| Fresh hardware validation | 🚧 Pending |
| Stable release | ⏳ Not yet |

Detailed development history belongs in:

- [`RAOHANE-CHANGELOG.md`](RAOHANE-CHANGELOG.md)
- [`RAOHANE-ROADMAP.md`](RAOHANE-ROADMAP.md)
- [`RELEASE-VALIDATION.md`](RELEASE-VALIDATION.md)

This README intentionally avoids duplicating the old migration-phase checklist.

---

## Source lineage & license

Raohane is distributed under **GPLv3**.

The active runtime is standalone, but retained source/data/assets with upstream lineage keep their required attribution. Technical independence does not erase authorship or licensing history.

See:

- [`LICENSE`](LICENSE)
- [`NOTICE-UPSTREAM.md`](NOTICE-UPSTREAM.md)
- [`ARCHITECTURE.md`](ARCHITECTURE.md)

---

<div align="center">

### ラオハネ

**Quiet surfaces. Native control. One coherent Hyprland shell.**

`Hyprland · Quickshell · Qt/QML`

</div>
