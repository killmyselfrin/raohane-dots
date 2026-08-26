<div align="center">

# ラオハネ · Raohane

### A living desktop shell for Hyprland

**Japanese-inspired · Quickshell-powered · being rebuilt into a standalone shell**

[![Hyprland](https://img.shields.io/badge/Hyprland-target-7c5cff?style=for-the-badge)](https://hypr.land/)
[![Quickshell](https://img.shields.io/badge/Quickshell-Qt%2FQML-6f8cff?style=for-the-badge)](https://quickshell.org/)
[![Platform](https://img.shields.io/badge/Linux-Arch%20focused-1793d1?style=for-the-badge&logo=archlinux&logoColor=white)](#installation)
[![Main](https://img.shields.io/badge/main-live%20integration-f0a040?style=for-the-badge)](#main-development-policy)
[![License](https://img.shields.io/badge/License-GPLv3-2f2f2f?style=for-the-badge)](LICENSE)

> **Current phase:** Standalone / Independence Migration
>
> **`main` is the live integration/testing branch.** It may contain runtime bugs while Raohane is being separated from its migration foundation.

</div>

---

## ✦ What is Raohane?

**Raohane** is a desktop shell for **Hyprland**, written with **Quickshell / Qt QML**.

The project combines Japanese-inspired minimalism with a more reactive desktop: contextual surfaces, dynamic media controls, a living center island, polished system panels and fullscreen-aware overlays.

Raohane originally used a mature existing shell foundation so important Linux desktop behavior did not need to be rewritten all at once. That dependency is now being removed subsystem-by-subsystem.

The end goal is explicit:

> **Raohane must be able to install, run, update and evolve without cloning, executing or depending on another desktop-shell repository.**

---

## 🚧 What we are doing right now

The standalone migration is now integrated directly into **`main`**.

PR #11 was merged so a normal installation from the repository exercises the current Raohane code instead of an older compatibility snapshot. Old foundation PRs #9 and #10 were closed as superseded rather than merged back into the new architecture.

The migration is moving from this:

```text
Quickshell
   ↓
inherited services / common framework
   ↓
Raohane presentation
```

into this:

```text
Quickshell + Linux system APIs
   ↓
Raohane-owned services
   ↓
Raohane-owned config / state / common framework
   ↓
Raohane-native UI
```

### Current focus

1. migrate the wallpaper/background backend into Raohane ownership;
2. replace inherited session/system-information services;
3. introduce `RaohaneConfig` and a native common framework;
4. remove compatibility runtime layers only after feature parity is preserved;
5. install and test `main` on a real Hyprland session, then fix runtime failures in batches.

---

## 🧪 Main development policy

During the current 0.10 migration, **`main` is intentionally an integration branch**.

That means:

- new Raohane work is integrated into `main` instead of being hidden behind a long-lived development PR;
- installation from `main` always exercises the newest architecture;
- runtime bugs found after installation are useful migration data rather than a reason to keep the code isolated indefinitely;
- fixes should be grouped by subsystem when possible so we can discover several related failures in one real session;
- static CI still guards syntax and architecture boundaries, but a passing CI run does **not** mean the desktop has been proven on actual hardware;
- a future tagged release can become the stable reference once the standalone runtime is ready.

This is deliberate: while Raohane is under heavy reconstruction, it is more useful to have **one obvious source of truth** than several partially overlapping branches.

---

## ✅ Raohane-owned boundaries already in `main`

| Area | Current ownership |
|---|---|
| Dependency installation | Raohane-owned Arch manifests |
| MPRIS / media | `RaohaneMedia` |
| Bluetooth | `RaohaneBluetooth` |
| PipeWire audio | `RaohaneAudio` |
| NetworkManager | `RaohaneNetwork` |
| Brightness / DDC / gamma | `RaohaneDisplay` |
| Notification server / history | `RaohaneNotifications` |
| Privacy / capture state | `RaohanePrivacy` |
| Context Island | Raohane-native |
| Horizontal bar | Raohane-native development surface |
| Launcher | Raohane-native development surface |
| Control Center | Raohane-native presentation |
| Settings shell / Control Deck | Raohane-native presentation |
| Media / game overlay | Raohane-native |
| OSD | Raohane-native |
| Notification UI | Raohane-native |
| Wallpaper selector | Raohane-native presentation |
| Desktop context menu | Raohane-native |
| Session / power screen | Raohane-native presentation |
| Dependency / architecture CI | Raohane-owned audit pipeline |

### Active service boundary

```text
Quickshell.Services.Mpris
        ↓
   RaohaneMedia
        ↓
Context Island / Media Overlay

Quickshell.Services.Pipewire
        ↓
   RaohaneAudio
        ↓
Control Center / OSD

Quickshell.Bluetooth
        ↓
 RaohaneBluetooth
        ↓
   Control Center

NetworkManager / nmcli
        ↓
  RaohaneNetwork
        ↓
   Control Center

brightnessctl + ddcutil + hyprsunset
        ↓
  RaohaneDisplay
        ↓
Control Center / OSD

Quickshell.Services.Notifications
        ↓
 RaohaneNotifications
        ↓
Popup / Notification Center / compatibility facade
```

The installer and dependency doctor no longer need to execute another shell repository's setup process.

---

## 🔧 In progress now

The next major boundary is **wallpapers and the desktop background stack**.

The selector UI is already Raohane-native, but the wallpaper data/apply layer still depends on inherited helpers.

The target is:

```text
filesystem / wallpaper directory
        +
thumbnail generation
        +
wallpaper apply / random / preview
        ↓
 RaohaneWallpapers
        ↓
RaohaneWallpaperSelector
        +
future Raohane background renderer
```

After wallpapers:

```text
Session / SystemInfo
        ↓
RaohaneConfig
        ↓
Raohane common framework
        ↓
compatibility cleanup
```

---

## 🧩 Still being migrated

The largest remaining areas are:

- wallpaper backend and desktop background renderer;
- system/session information and warnings;
- application/search providers;
- remaining desktop widgets;
- lock/capture/region-selection support;
- remaining shared `modules/common` utilities;
- the inherited configuration schema;
- remaining compatibility `modules/ii` surfaces;
- compatibility service facades that exist only until old UI is removed.

These components are migration scaffolding, not the intended final architecture.

---

## 🗺️ Roadmap to standalone Raohane

### Phase 1 — Installation boundary

- [x] Raohane-owned dependency manifests
- [x] independent dependency installer
- [x] dependency doctor
- [x] stop normal CI from fetching upstream shell repositories
- [x] explicit legacy-config migration
- [x] integrate the current standalone batch into `main`

### Phase 2 — Core services

- [x] MPRIS / media
- [x] Bluetooth
- [x] PipeWire audio
- [x] NetworkManager
- [x] Privacy / capture state
- [x] Brightness / DDC
- [x] Night light / gamma
- [x] Notifications / notification history
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
- [ ] remove compatibility service facades
- [ ] remove upstream panel-family fallback
- [ ] remove migration sync/bootstrap scripts
- [ ] remove obsolete upstream lock files

### Phase 5 — Standalone release

- [ ] clean install on a fresh Arch/Hyprland system
- [ ] multi-monitor validation
- [ ] NVIDIA validation
- [ ] AMD / Intel validation
- [ ] fullscreen / game overlay validation
- [ ] package and dependency audit
- [ ] standalone tagged Raohane release

---

## ✨ Product direction

Raohane is not intended to be only another themed status bar.

The shell is being designed around:

- a **Context Island** that reacts to media, active windows, privacy and system events;
- a media overlay that can appear over fullscreen applications and games;
- a coherent Control Center for audio, networking, Bluetooth, display and system modes;
- a native launcher and search experience;
- a customizable Japanese-inspired visual language;
- dynamic wallpaper and desktop surfaces;
- polished notifications and OSD;
- full settings instead of requiring manual config editing;
- gaming-aware behavior and low-latency modes;
- strong **Hyprland-first** integration.

Raohane does not pretend to target every compositor. **Hyprland is the product target.**

---

## 📦 Installation

The current development build is installed directly from **`main`**:

```bash
git clone https://github.com/snuskidau/raohane-dots.git
cd raohane-dots

chmod +x install-raohane.sh
./install-raohane.sh --deps

hyprctl reload
raohane restart
```

`--deps` installs the Raohane-owned Arch package manifests. It does **not** execute another desktop shell's installer.

If the required packages are already installed:

```bash
./install-raohane.sh
hyprctl reload
raohane restart
```

To update an existing checkout before testing:

```bash
git checkout main
git pull --ff-only
./install-raohane.sh
hyprctl reload
raohane restart
```

> `main` is currently a development integration branch. A broken surface after installation should be reported with diagnostics rather than assumed to be a finished release.
>
> GPU drivers are never silently selected or replaced. Font binaries remain package-managed instead of being vendored into the repository.

---

## 🎛️ Main controls

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

Foreground debugging:

```bash
raohane stop
raohane run
```

Logs:

```bash
raohane logs
```

---

## 🔎 Runtime debugging workflow

After installing a fresh `main`, do **one broad test pass** before fixing individual issues.

Recommended order:

1. start/restart Raohane;
2. check bar on every monitor;
3. open launcher and test keyboard focus/search;
4. open Control Center;
5. test volume/microphone and OSD;
6. test Bluetooth;
7. test Wi-Fi/Ethernet state and Wi-Fi toggle;
8. test brightness/DDC/gamma/night light;
9. send several notifications, use actions, dismiss them and restart Raohane to verify history;
10. test media selection, play/pause, previous/next and seek;
11. test media overlay over a fullscreen application/game;
12. test wallpaper preview/apply/random;
13. test desktop menu;
14. test settings pages;
15. test lock/logout/reboot/shutdown UI without triggering destructive actions unnecessarily.

Collect this first:

```bash
raohane doctor all
```

Then run the shell in the foreground:

```bash
raohane stop
raohane run
```

For service-start failures or earlier crashes:

```bash
raohane logs
```

When reporting failures, the most useful format is:

```text
1. What I opened / clicked
2. What I expected
3. What actually happened
4. Terminal error from `raohane run`
5. Relevant section from `raohane doctor all`
```

This lets us fix several connected problems in one migration batch instead of chasing them one at a time.

---

## 🧱 Repository structure

```text
raohane-dots/
├── modules/
│   ├── raohane/
│   │   ├── services/        # Raohane-owned backend adapters
│   │   └── ...              # native UI / state
│   ├── common/              # shared framework being migrated
│   └── ii/                  # temporary compatibility UI
├── services/                # inherited services / compatibility facades
├── panelFamilies/
│   └── RaohaneFamily.qml    # current composition boundary
├── install/
│   └── arch/                # Raohane dependency manifests
├── scripts/
│   ├── raohane              # CLI
│   └── ...
├── defaults/
├── shell.qml
└── install-raohane.sh
```

---

## 🔒 Project rules

Current development rules:

- `main` is the current integration source of truth during the migration;
- no silent GPU-driver replacement;
- no vendored font binaries;
- no new Niri-specific product work — Raohane targets Hyprland;
- no Raohane-specific state inside migration-owned `GlobalStates.qml`;
- new product state belongs in Raohane-owned singletons;
- migrated UI should consume stable Raohane service APIs instead of inherited adapters;
- only one subsystem owner should talk directly to each system daemon where duplicate ownership is unsafe;
- normal install/doctor/CI paths should not execute another shell repository;
- GPL and attribution obligations remain preserved while derivative code is still present.

---

## 📜 Licensing and upstream lineage

Raohane is distributed under **GPLv3**.

The repository currently contains code with upstream lineage from the migration foundation. Relevant notices and attribution remain preserved while that code is still present.

The independence migration means removing permanent build/runtime/development dependency — not erasing authorship or licensing history.

See:

- [`NOTICE-UPSTREAM.md`](NOTICE-UPSTREAM.md)
- [`INDEPENDENCE-PLAN.md`](INDEPENDENCE-PLAN.md)
- [`ARCHITECTURE.md`](ARCHITECTURE.md)
- [`RAOHANE-CHANGELOG.md`](RAOHANE-CHANGELOG.md)

---

<div align="center">

### Raohane is being rebuilt into its own shell.

**One integration branch. One install path. Real runtime failures become the next work queue.**

`ラオハネ` · Hyprland · Quickshell

</div>
