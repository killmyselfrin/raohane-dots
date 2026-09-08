# ラオハネ · Raohane

A desktop shell for Hyprland, built with Quickshell and Qt/QML. Dark glass surfaces, Japanese-inspired styling, and a shared theme across the desktop.

[![Raohane audit](https://github.com/killmyselfrin/raohane-dots/actions/workflows/raohane-audit.yml/badge.svg?branch=main)](.github/workflows/raohane-audit.yml)
[![Release boundary](https://github.com/killmyselfrin/raohane-dots/actions/workflows/release-boundary.yml/badge.svg?branch=main)](.github/workflows/release-boundary.yml)
[![License: GPLv3](https://img.shields.io/badge/license-GPLv3-blue)](LICENSE)

**Status:** `1.2.0` — stable contextual-shell release with Scenes, application-aware switching, Launcher 2.0 actions, Context Island 2.0 activity states, native recording, and reversible runtime policy overlays. See the [release validation guide](docs/RELEASE-VALIDATION.md) and [roadmap](docs/ROADMAP.md) for validation and future work.

## Features

- Horizontal and vertical bars, workspaces, system tray, Context Island, and a dock.
- Contextual Scenes for Balanced, Gaming, Focus, and Work, including application rules and configurable runtime behavior.
- Application launcher with scene-aware actions, workspace overview, and configurable desktop widgets.
- Control Center with Wi-Fi, Bluetooth, audio, microphone, brightness, notifications, and Scene switching.
- Settings, theme import/export, image or video wallpapers, and per-Scene behavior controls.
- MPRIS media controls, lyrics, and a media overlay for fullscreen applications.
- Screenshots, native gameplay recording, OCR, screen translation, clipboard tools, and an on-screen keyboard.
- Lock screen, session controls, Polkit authentication, and a process manager.

Raohane includes its own runtime and dependency manifests. Installation does not require another desktop-shell repository.

## Install

### Arch Linux and derivatives

Run the guided installer from an existing Hyprland session:

```bash
git clone https://github.com/killmyselfrin/raohane-dots.git
cd raohane-dots
bash install.sh
```

The installer performs a system preflight, shows every missing package before making changes, asks for permission to install the complete dependency set, installs the optional Raohane SDDM login theme, configures Hyprland integration, enables `raohane.service` for autostart, and starts the shell for a live check when a Hyprland session is available. The visual Raohane welcome/onboarding opens on first launch.

For unattended or already-reviewed installation choices:

```bash
bash install.sh --yes
```

Dependencies are owned by Raohane and listed in [install/arch/required.txt](install/arch/required.txt) and [install/arch/features.txt](install/arch/features.txt). GPU drivers are never changed automatically; fonts and feature backends are installed through the package manager.

`install-raohane.sh` remains the low-level backend installer for development, upgrades, recovery, and scripted maintenance.

### NixOS and Home Manager

The flake exports a package, a NixOS module, and a Home Manager module. See [Nix installation](docs/NIX.md) for configuration.

## Update

From the checkout used to install Raohane:

```bash
git pull --ff-only
./install-raohane.sh --no-deps --no-login-theme
raohane restart
```

The installer copies the source into `~/.config/quickshell/raohane`; pulling Git changes alone does not update the running shell. Use the guided installer again when dependency requirements change, and omit `--no-login-theme` when updating the login theme.

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

The launcher supports application names, `/` for built-in and contextual actions, `>` for commands, `=` for calculations, and `:` for clipboard history.

Settings are stored in `~/.config/raohane/native.json`. Scene state and application rules are stored separately under the XDG state directory so temporary policies do not overwrite base settings. User autostart commands belong in `~/.config/raohane/autostart.conf`.

The default **Raohane** theme uses dark charcoal glass and violet accents. Paper, Sakura, Matcha, Slate, Sand, Sumi, and Midnight are included as built-in alternatives. Themes can be selected in Settings or managed through `raohane theme`; see the [theme format](docs/THEMES.md).

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

Raohane is distributed under [GPLv3](LICENSE). Retained and adapted code, translations, data, and assets keep their applicable attribution; see [NOTICE-UPSTREAM.md](NOTICE-UPSTREAM.md).
