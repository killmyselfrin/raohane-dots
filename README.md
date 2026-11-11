<div align="center">

<img src="assets/icons/raohane-emblem.png" alt="Raohane feather-nova emblem" width="150">

# Raohane

**Your desktop, your atmosphere.**

A customizable desktop shell for **Hyprland**, built with **Quickshell + Qt/QML**.<br>
Graphite surfaces. Lavender accents. A space that feels like yours.

[![Raohane audit](https://github.com/killmyselfrin/raohane-dots/actions/workflows/raohane-audit.yml/badge.svg?branch=main)](https://github.com/killmyselfrin/raohane-dots/actions/workflows/raohane-audit.yml)
[![GPLv3](https://img.shields.io/badge/license-GPLv3-b9b3f3)](LICENSE)
![Linux](https://img.shields.io/badge/platform-Linux-191d27)
![Development](https://img.shields.io/badge/version-1.3.0--dev-b9b3f3)

[Install](#installation) · [Gallery](#gallery) · [Features](#features) · [Configure](#configuration) · [Documentation](#documentation)

<img src="assets/screenshots/desktop.png" alt="Running Raohane desktop with Orbit bar, clock and idle record widget over a forest photograph" width="100%">

</div>

## Gallery

These are **real captures of the running Quickshell interface**, taken at
1920 × 1080 in the cloud diagnostic session: Sway headless, pixman and Qt software
rendering. The supported product target is **Hyprland**; these images do not
validate Hyprland integration, GPU effects or hardware controls.
[Capture details and credits](assets/screenshots/README.md).

<table>
<tr>
<td width="50%">
<a href="assets/screenshots/welcome.png"><img src="assets/screenshots/welcome.png" alt="Welcome with feather-nova emblem and five-step initial setup" width="100%"></a><br>
<strong>A proper first welcome</strong><br>
<sub>Choose your theme, wallpaper and panel. Setup stays open until you finish.</sub>
</td>
<td width="50%">
<a href="assets/screenshots/settings.png"><img src="assets/screenshots/settings.png" alt="Theme settings with wallpaper categories, palettes and appearance controls" width="100%"></a><br>
<strong>Make it yours</strong><br>
<sub>Wallpaper collections, live theme palettes and shared appearance controls.</sub>
</td>
</tr>
<tr>
<td colspan="2">
<a href="assets/screenshots/control-center.png"><img src="assets/screenshots/control-center.png" alt="Running Raohane Control Center in the diagnostic session" width="100%"></a><br>
<strong>Everyday controls, together</strong><br>
<sub>Audio, connectivity and session controls. Hardware availability reflects the test container.</sub>
</td>
</tr>
</table>

## A desktop with your rhythm

- **An unhurried start.** A finite animated introduction and five setup pages, with reduced-motion support.
- **Ten bar styles.** From floating groups to the centered Orbit capsule, crisp Ribbon panel and transparent Ink layout.
- **A ready-to-use wallpaper library.** 20 nature photographs, 20 abstractions and 20 original anime-inspired offline illustrations. An optional importer adds a separate online anime collection.
- **Music with presence.** A record-style media card, a Now Playing capsule with album art and playback control, real progress and lyrics through the existing media service.
- **One visual language.** Shared palettes, surfaces and motion across the shell.

## Features

| Surface | What Raohane provides |
| --- | --- |
| **Bar &amp; Dock** | Horizontal/vertical bars, configurable modules, workspaces, system tray, Context Island, and a dock. |
| **Launcher &amp; Overview** | Search for apps and actions, navigate workspaces and switch between windows. |
| **Control Center** | Wi-Fi, Bluetooth, audio, microphone, display brightness, notifications, and Scenes. |
| **Settings &amp; Themes** | Central settings, theme presets, JSON theme import/export, live appearance controls, and desktop widgets with an on-wallpaper grid editor and nine selectable Clock/Music/System faces (Classic, Minimal, Aurora). |
| **Wallpaper &amp; Bar** | Wallpaper Studio 2.0 adds favorites, saved folder collections, per-monitor wallpapers, optional adaptive accents, video preview controls and timed rotation; Bar Studio includes the original styles, the centered **Halo** glass capsule, and optional **Chromatic Flow** that slowly blends two colors detected in the applied wallpaper. |
| **Scenes** | Balanced, Gaming, Focus, and Work modes with application rules and contextual runtime policies. |
| **Media** | MPRIS controls, synced/plain lyrics, an artwork-aware Now Playing capsule in the Bar with play/pause, a music surface, and a fullscreen media overlay. |
| **Utilities** | Screenshots, recording, OCR, on-demand screen translation with a resident transaction service, clipboard tools, on-screen keyboard, task manager, and power/session controls. |
| **System integration** | Native service adapters for Hyprland, Wayland, PipeWire, NetworkManager, and Bluetooth. |

Raohane maintains its own runtime and dependency manifests. It does not install another shell as a runtime dependency.

**Current source version:** `1.3.0-dev` (see [VERSION](VERSION) and [CHANGELOG](CHANGELOG.md)). The project remains under active development; static GitHub Actions checks do **not** certify long-session, multi-monitor, or GPU-specific stability. Review the [roadmap](docs/ROADMAP.md) and [release validation](docs/RELEASE-VALIDATION.md).

## Installation

### Arch Linux and derivatives

Install from an existing Hyprland session:

```bash
git clone https://github.com/killmyselfrin/raohane-dots.git
cd raohane-dots
bash install.sh
```

The guided installer checks dependencies, explains missing packages, asks permission for system changes, sets up the Raohane runtime and Hyprland integration, and can install the optional SDDM login theme. The visual onboarding opens on first launch.

After reviewing the package changes, an unattended installer is available:

```bash
bash install.sh --yes
```

Dependencies: [required packages](install/arch/required.txt) · [optional features](install/arch/features.txt). GPU drivers are **not** automatically replaced. The developer/upgrade backend is `install-raohane.sh`.

### NixOS and Home Manager

The flake exports a package, a NixOS module, and a Home Manager module. Follow [Nix installation](docs/NIX.md).

## Update

From the checkout used to install Raohane:

```bash
git pull --ff-only
./install-raohane.sh --no-deps --no-login-theme
raohane restart
```

Pulling repository changes alone does not replace the installed runtime under `~/.config/quickshell/raohane`. Re-run the guided installer when dependencies change.

## Commands

| Command | Action |
| --- | --- |
| `raohane launcher` | Open the application launcher |
| `raohane control` | Open Control Center |
| `raohane settings` | Open Settings |
| `raohane media` | Open the media overlay |
| `raohane desktop` | Open desktop controls |
| `raohane wallpaper` | Open the wallpaper selector |
| `raohane session` | Open power and session controls |
| `raohane translate` | Start screen translation |
| `raohane doctor all` | Inspect installation and runtime |
| `raohane doctor performance` | Read-only process CPU, RSS, threads, and service restarts |
| `raohane validate smoke` | Inspect current-session IPC and significant QML errors |

Launcher search modes: app names · `/` built-in/contextual actions · `>` commands · `=` calculations · `:` clipboard history.

## Configuration

Settings are stored at `~/.config/raohane/native.json`. Scene state and application rules are tracked separately under XDG state paths, so temporary scene policies don't overwrite base preferences. User autostart commands belong in `~/.config/raohane/autostart.conf`.

The default **Raohane** theme combines dark charcoal glass with lavender accents. Built-in alternatives include **Paper, Rose Glass, Sage Glass, Slate, Sand, Ink,** and **Midnight**. Use Settings or `raohane theme` to select, import, and export themes. See [theme format](docs/THEMES.md).

### Wallpaper collections

The bundled collection works offline. To download the optional mixed anime set:

```bash
python3 scripts/import-anime-wallpapers.py \
  --output "$HOME/.local/share/raohane/wallpapers/anime" \
  --register-config "$HOME/.config/raohane/native.json"
```

Run this from the checkout after the initial installation. The importer uses
pinned URLs and checksums; Python Pillow is required for image validation.
[Collection sources, licenses and usage](assets/wallpapers/README.md).

## Troubleshooting

```bash
raohane doctor all
raohane doctor performance
raohane status
raohane logs
raohane validate smoke
```

To observe a clean foreground startup:

```bash
raohane stop
raohane run
```

For performance or disappearing-panel reports, run `raohane doctor performance` while the issue occurs and compare with a healthy-session snapshot. Include the installed version, GPU/compositor details, `raohane validate smoke`, recent logs, and exact reproduction steps. The read-only process snapshot reports lifetime-average CPU, RSS, threads and service restart counts; it does not measure frame time. Hardware/runtime issues should be tested in a real Hyprland session.

Raohane installs updates **manually by default**; automatic installation can be explicitly enabled in Settings → About. Existing explicit automatic-update preferences remain respected.

If Shelly or another package manager reports that polkit is missing on the system bus, check `systemctl status polkit`, `busctl --system status org.freedesktop.PolicyKit1`, and `pkexec whoami`. The system-wide `polkit` daemon is a required dependency; Raohane also provides its own graphical authorization agent via Quickshell. Do not start a second polkit agent unless the built-in one is unavailable. See [Shelly's polkit troubleshooting guide](https://www.seafoam-labs.org/shelly-alpm/docs/polkit/).

## Documentation

- [Initial setup validation](docs/WELCOME-SETUP-VALIDATION.md)
- [Bar, Welcome and wallpaper validation](docs/BAR-WELCOME-PACK-VALIDATION.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Release validation](docs/RELEASE-VALIDATION.md)
- [Roadmap](docs/ROADMAP.md)
- [Widget Studio 2.0 testing and rollback](docs/WIDGET-STUDIO-2-VALIDATION.md)
- [Widget face library — styles, controls and runtime checks](docs/WIDGET-FACE-LIBRARY.md)
- [Cinematic wallpaper + floating bar validation](docs/CINEMATIC-DESKTOP-VALIDATION.md)
- [Wallpaper Studio 2.0 — features and live tests](docs/WALLPAPER-STUDIO-2-VALIDATION.md)
- [Halo Bar — appearance, native modules and smoke tests](docs/HALO-BAR-VALIDATION.md)
- [Theme format](docs/THEMES.md)
- [NixOS / Home Manager](docs/NIX.md)
- [Contributing](CONTRIBUTING.md)
- [Localization](translations/l10n/README.md)
- [Changelog](CHANGELOG.md)

## Development

### Codex Cloud changes in main

The current `main` includes the following reconciled Codex Cloud contributions:

- **Screen translation (#93):** background OCR/translation transaction state is resident in `RaohaneScreenTranslation`; the full-screen presentation is on-demand, and IPC/shortcut entrypoints stay active while it is unloaded.
- **Now Playing island (#145):** bounded album-art decoding, a separate play/pause action and an overlay shortcut, adapted for the current Halo/compact Bar layouts.
- **Motion and visual contracts (#127):** Quick Controls busy indicators respect reduced-motion and Gaming policies; neutral Nocturne design guidance remains the product baseline.
- **Desktop & Spaces preview (#39):** on-demand Settings wallpaper and workspace grid preview, native shortcuts to wallpaper/Overview/widgets, and geometry-aware navigation to controls.
- **Settings navigation (#47):** ranked multiword search with Russian е/ё normalization, a scrollable result list, keyboard-accessible sidebar, and motion-aware page transitions across every Settings page.

These are code integrations, **not proof of live Hyprland acceptance**. Static checks and source review do not replace compositor testing. The original draft PRs may remain open as historical review records even when selected changes have been ported.

Other cloud proposals still require reconciliation against newer `main`: the overlapping [Bar settings (#99)](https://github.com/killmyselfrin/raohane-dots/pull/99) / [single-source Bar Studio (#100)](https://github.com/killmyselfrin/raohane-dots/pull/100) work, and [1.3 release candidate (#48)](https://github.com/killmyselfrin/raohane-dots/pull/48). These are **not yet represented as completed features in `main`**.

The active Quickshell implementation is under `modules/raohane/`. Verify source and runtime boundaries with:

```bash
bash scripts/raohane-audit.sh
bash scripts/runtime-payload-audit.sh
```

**Static validation does not replace running the shell.** Check behavior, QML logs, screenshots, session actions, and long-session resource usage on target Hyprland hardware before declaring release readiness.

## License

Raohane is released under [GNU GPLv3](LICENSE). Retained/adapted code, translations, data, and assets preserve applicable attribution; see [NOTICE-UPSTREAM.md](NOTICE-UPSTREAM.md). Screenshot credits and capture details are listed in [assets/screenshots](assets/screenshots/README.md). Older concept artwork remains separately labeled in [assets/showcase](assets/showcase/README.md).
