# ラオハネ · Raohane

A desktop shell for Hyprland, built with Quickshell and Qt/QML. Dark glass surfaces, Japanese-inspired styling, and a shared theme across the desktop.

[![Raohane audit](https://github.com/killmyselfrin/raohane-dots/actions/workflows/raohane-audit.yml/badge.svg?branch=main)](.github/workflows/raohane-audit.yml)
[![Release boundary](https://github.com/killmyselfrin/raohane-dots/actions/workflows/release-boundary.yml/badge.svg?branch=main)](.github/workflows/release-boundary.yml)
[![License: GPLv3](https://img.shields.io/badge/license-GPLv3-blue)](LICENSE)

**Status:** `0.10.0-dev`. Active development; hardware and session validation remain open. See the [roadmap](docs/ROADMAP.md) for current priorities.

## Features

- Horizontal and vertical bars, workspaces, system tray, Context Island, and a dock.
- Application launcher, workspace overview, and configurable desktop widgets.
- Control Center with Wi-Fi, Bluetooth, audio, microphone, brightness, and notifications.
- Settings, theme import/export, and image or video wallpapers.
- MPRIS media controls, lyrics, and a media overlay for fullscreen applications.
- Screenshots, recording, OCR, screen translation, clipboard tools, and an on-screen keyboard.
- Lock screen, session controls, Polkit authentication, and a process manager.

Raohane includes its own runtime and dependency manifests. Installation does not require another desktop-shell repository.

## Install

### Arch Linux and derivatives

Run from an existing Hyprland session:

```bash
git clone https://github.com/killmyselfrin/raohane-dots.git
cd raohane-dots
./install-raohane.sh --deps
hyprctl reload
raohane restart
```

Dependencies are listed in [install/arch/required.txt](install/arch/required.txt) and [install/arch/features.txt](install/arch/features.txt). GPU driver changes require an explicit choice; fonts are installed through the package manager.

### NixOS and Home Manager

The flake exports a package, a NixOS module, and a Home Manager module. See [Nix installation](docs/NIX.md) for configuration.

## Update

From the checkout used to install Raohane:

```bash
git pull --ff-only
./install-raohane.sh --no-deps --no-login-theme
raohane restart
```

The installer copies the source into `~/.config/quickshell/raohane`; pulling Git changes alone does not update the running shell. Use `--deps` when updating dependencies, and omit `--no-login-theme` when updating the login theme.

## Use

| Command | Opens |
| --- | --- |
| `raohane launcher` | Application launcher |
| `raohane control` | Control Center |
| `raohane settings` | Settings |
| `raohane media` | Media overlay |
| `raohane desktop` | Desktop controls |
| `raohane wallpaper` | Wallpaper selector |
| `raohane session` | Session and power controls |
| `raohane translate` | Screen translation |

The launcher supports application names, `/` for built-in actions, `>` for commands, `=` for calculations, and `:` for clipboard history.

Settings are stored in `~/.config/raohane/native.json`. User autostart commands belong in `~/.config/raohane/autostart.conf`.

The default **Raohane** theme uses dark charcoal glass and violet accents. Paper, Sakura, Matcha, Slate, Sand, Sumi, Midnight, and converted Serpantinum palettes are also available. Themes can be selected in Settings or managed through `raohane theme`; see the [theme format](docs/THEMES.md).

## Troubleshooting

```bash
raohane doctor all
raohane status
raohane logs
```

To inspect startup errors in the terminal:

```bash
raohane stop
raohane run
```

For performance or disappearing-panel reports, include the installed version, recent logs, process usage during the problem, and the steps that triggered it.

## Development

Product QML lives in `modules/raohane/`. The [architecture guide](docs/ARCHITECTURE.md) describes the module layout and service interfaces.

```bash
bash scripts/raohane-audit.sh
bash scripts/runtime-payload-audit.sh
```

Run the relevant feature checks as well. Static checks do not replace testing in a real Hyprland session; the [release validation guide](docs/RELEASE-VALIDATION.md) covers that process.

- [Contributing](CONTRIBUTING.md)
- [Changelog](CHANGELOG.md)
- [Roadmap](docs/ROADMAP.md)
- [Localization](translations/l10n/README.md)

## License

Raohane is distributed under [GPLv3](LICENSE). Retained and adapted code, palettes, translations, and assets keep their applicable attribution; see [NOTICE-UPSTREAM.md](NOTICE-UPSTREAM.md).
