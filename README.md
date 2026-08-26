<div align="center">

# ラオハネ · Raohane

### A living desktop shell for Hyprland

**Japanese-inspired · Quickshell-powered · built to become fully standalone**

[![Hyprland](https://img.shields.io/badge/Hyprland-target-7c5cff?style=for-the-badge)](https://hypr.land/)
[![Quickshell](https://img.shields.io/badge/Quickshell-Qt%2FQML-6f8cff?style=for-the-badge)](https://quickshell.org/)
[![Platform](https://img.shields.io/badge/Linux-Arch%20focused-1793d1?style=for-the-badge&logo=archlinux&logoColor=white)](#installation)
[![License](https://img.shields.io/badge/License-GPLv3-2f2f2f?style=for-the-badge)](LICENSE)

> **Current project phase:** Raohane is being separated from its migration foundation and rebuilt as an independent Hyprland + Quickshell shell.

</div>

---

## ✦ What is Raohane?

**Raohane** is a desktop shell for **Hyprland** built with **Quickshell / Qt QML**.

The visual direction combines Japanese minimalism with a more alive, reactive desktop: a contextual center island, dynamic media surfaces, polished control panels, desktop overlays, smooth transitions and a shell that reacts to what the user is doing instead of behaving like a static bar.

Raohane started from a mature existing shell foundation so that important Linux desktop behavior did not need to be reimplemented all at once. That foundation is now being removed subsystem-by-subsystem.

The final architecture is not intended to remain a reskin or permanent derivative runtime of another shell.

---

## 🚧 What we are doing now

The active development effort is the **Standalone / Independence Migration**.

The current development branch is:

```text
raohane-context-media-foundation
```

and the active migration is tracked in **PR #11 — `Raohane 0.10 standalone migration batch`**.

The goal of this phase is simple:

> Raohane should be able to install, run, update and evolve without cloning, executing or depending on another desktop-shell repository.

### Current migration direction

```text
Before

Quickshell
   ↓
inherited shell services / modules
   ↓
Raohane presentation


Target

Quickshell + system APIs
   ↓
Raohane-owned services
   ↓
Raohane-owned state / config / common framework
   ↓
Raohane-native UI
```

---

## ✅ Already separated in the development branch

| Area | Current Raohane ownership |
|---|---|
| Dependency installation | Raohane-owned Arch manifests |
| MPRIS / media backend | `RaohaneMedia` |
| Bluetooth backend | `RaohaneBluetooth` |
| PipeWire audio backend | `RaohaneAudio` |
| Privacy / capture state | `RaohanePrivacy` |
| Context Island | Raohane-native |
| Horizontal bar | Raohane-native development surface |
| Launcher | Raohane-native development surface |
| Control Center | Raohane-native presentation |
| Settings shell / Control Deck | Raohane-native presentation |
| Media / game overlay | Raohane-native |
| OSD | Raohane-native |
| Notification UI | Raohane-native presentation |
| Wallpaper selector | Raohane-native presentation |
| Desktop context menu | Raohane-native |
| Session / power screen | Raohane-native presentation |
| CI ownership checks | Raohane-owned audit pipeline |

### First independent service boundary

```text
Quickshell.Services.Mpris
        ↓
   RaohaneMedia
        ↓
Context Island / Media Overlay

Quickshell.Bluetooth
        ↓
 RaohaneBluetooth
        ↓
   Control Center

Quickshell.Services.Pipewire
        ↓
   RaohaneAudio
        ↓
Control Center / OSD
```

The development installer also no longer needs to clone or execute another shell repository to install Raohane dependencies.

---

## 🧩 Still being migrated

Some mature subsystems are still inherited temporarily so the desktop remains usable while their replacements are built.

The largest remaining areas are:

- network / NetworkManager integration;
- brightness and gamma / night-light integration;
- notification backend and history ownership;
- wallpaper backend and desktop background renderer;
- system/session information and warnings;
- application/search providers;
- remaining desktop widgets;
- lock/capture/region-selection support;
- remaining shared `modules/common` utilities;
- the inherited configuration schema;
- compatibility `modules/ii` surfaces that are still required at runtime.

These components are migration scaffolding, not the final architecture.

---

## 🗺️ Roadmap to standalone Raohane

### Phase 1 — Installation boundary

- [x] Raohane-owned dependency manifests
- [x] Independent dependency installer
- [x] Dependency doctor
- [x] Stop normal CI from fetching upstream shell repositories
- [x] Make legacy config import explicit instead of automatic

### Phase 2 — Core services

- [x] MPRIS / media
- [x] Bluetooth
- [x] PipeWire audio
- [x] Privacy / capture state
- [ ] NetworkManager
- [ ] Brightness / DDC
- [ ] Night light / gamma
- [ ] Notifications
- [ ] Wallpapers
- [ ] Session / system information

### Phase 3 — Core framework

- [ ] `RaohaneConfig`
- [ ] Raohane-owned directory/path API
- [ ] Raohane-owned common widgets
- [ ] Raohane-owned models and utility functions
- [ ] remove direct active-runtime imports from inherited services

### Phase 4 — Runtime cleanup

- [ ] remove remaining `modules/ii` runtime dependencies
- [ ] remove inherited service graph
- [ ] remove upstream panel-family fallback
- [ ] remove migration sync/bootstrap scripts
- [ ] remove upstream lock files that are no longer needed

### Phase 5 — Standalone release

- [ ] clean install on a fresh Arch/Hyprland system
- [ ] multi-monitor runtime validation
- [ ] NVIDIA + AMD/Intel validation
- [ ] fullscreen/game overlay validation
- [ ] package/dependency audit
- [ ] standalone Raohane release

---

## ✨ Product direction

Raohane is not meant to be only another themed status bar.

The intended shell includes:

- a **Context Island** that changes with media, active windows, privacy and system events;
- a media overlay that can appear over fullscreen applications and games;
- a coherent Control Center for audio, networking, Bluetooth, brightness and system modes;
- a native application launcher and search experience;
- a customizable Japanese-inspired visual language;
- dynamic wallpaper and desktop surfaces;
- polished notifications and OSD;
- a full settings experience rather than editing config files manually;
- gaming-aware behavior and low-latency presentation modes;
- strong Hyprland integration without pretending to support every compositor.

Hyprland is the product target.

---

## 📦 Installation

### Stable `main`

`main` still contains the current migration foundation. Until the standalone batch is merged, use the existing foundation bootstrap when installing directly from `main`:

```bash
git clone https://github.com/snuskidau/raohane-dots.git
cd raohane-dots

bash scripts/install-foundation-deps.sh
chmod +x install-raohane.sh
./install-raohane.sh

hyprctl reload
raohane restart
```

### Current standalone development build

To test the current independence work instead:

```bash
git clone https://github.com/snuskidau/raohane-dots.git
cd raohane-dots

git checkout raohane-context-media-foundation

chmod +x install-raohane.sh
./install-raohane.sh --deps

hyprctl reload
raohane restart
```

The development installer uses Raohane-owned package manifests and does **not** run another shell repository's setup process.

> GPU drivers are never silently replaced by the installer. Font binaries are package-managed rather than vendored into this repository.

---

## 🎛️ Main controls

The current development line exposes the following commands:

```bash
raohane launcher
raohane control
raohane settings
raohane media
raohane desktop
raohane wallpaper
raohane wallpaper random
raohane session
```

Diagnostics:

```bash
raohane doctor all
raohane doctor deps
raohane doctor services
raohane doctor graphics
raohane wifi status
raohane audio status
```

Direct foreground debugging:

```bash
raohane stop
raohane run
```

Logs:

```bash
raohane logs
```

---

## 🧪 Testing a development batch

A migration batch should not be considered release-ready only because QML parses successfully.

A real Hyprland session should verify at least:

1. startup and restart behavior;
2. bar behavior on every monitor;
3. launcher keyboard focus and search;
4. Control Center toggles and sliders;
5. audio sink/source volume and mute;
6. Bluetooth state and toggling;
7. Wi-Fi/network state;
8. brightness and gamma controls;
9. notifications and notification history;
10. OSD behavior;
11. MPRIS player selection, seek and transport controls;
12. media overlay behavior over fullscreen applications;
13. wallpaper preview/apply/random;
14. desktop context menu;
15. session, lock, logout, reboot and shutdown actions.

When something fails, useful output is:

```bash
raohane doctor all
raohane run
```

or:

```bash
raohane logs
```

---

## 🧱 Repository structure

```text
raohane-dots/
├── modules/
│   ├── raohane/            # Raohane-owned UI, state and service adapters
│   ├── common/             # shared framework currently being migrated
│   └── ii/                 # temporary compatibility UI
├── services/               # inherited services being replaced
├── panelFamilies/
│   └── RaohaneFamily.qml   # current composition boundary
├── install/
│   └── arch/               # Raohane dependency manifests in development
├── scripts/
│   ├── raohane             # CLI
│   └── ...
├── defaults/
├── shell.qml
└── install-raohane.sh
```

---

## 🔒 Project rules

Raohane development currently follows a few important rules:

- no silent GPU-driver replacement;
- no vendored font binaries;
- no new Niri-specific product work — Raohane targets Hyprland;
- no Raohane-specific state added to migration-owned `GlobalStates.qml`;
- new Raohane state belongs in Raohane-owned singletons;
- migrated services should expose stable Raohane APIs instead of letting UI depend directly on inherited adapters;
- upstream attribution and GPL obligations remain preserved while derivative code is still present.

---

## 📜 Licensing and upstream lineage

Raohane is distributed under **GPLv3**.

The repository currently contains code with upstream lineage from the migration foundation. Relevant notices and attribution are intentionally preserved while that code remains part of the project.

The independence migration is about removing permanent runtime/development dependency on another shell project — not erasing authorship or licensing history.

See:

- [`NOTICE-UPSTREAM.md`](NOTICE-UPSTREAM.md)
- [`INDEPENDENCE-PLAN.md`](INDEPENDENCE-PLAN.md)
- [`ARCHITECTURE.md`](ARCHITECTURE.md)
- [`RAOHANE-CHANGELOG.md`](RAOHANE-CHANGELOG.md)

---

<div align="center">

### Raohane is being rebuilt into its own shell.

**The current focus is architecture first — then polish without inherited limits.**

`ラオハネ` · Hyprland · Quickshell

</div>
