<div align="center">

# ラオハネ · Raohane

### A living desktop shell for Hyprland

**Japanese-inspired · Quickshell-powered · being rebuilt into a standalone shell**

[![Hyprland](https://img.shields.io/badge/Hyprland-target-7c5cff?style=for-the-badge)](https://hypr.land/)
[![Quickshell](https://img.shields.io/badge/Quickshell-Qt%2FQML-6f8cff?style=for-the-badge)](https://quickshell.org/)
[![Platform](https://img.shields.io/badge/Linux-Arch%20focused-1793d1?style=for-the-badge&logo=archlinux&logoColor=white)](#installation)
[![License](https://img.shields.io/badge/License-GPLv3-2f2f2f?style=for-the-badge)](LICENSE)

> **Current phase:** Standalone / Independence Migration

</div>

---

## ✦ What is Raohane?

**Raohane** is a desktop shell for **Hyprland**, written with **Quickshell / Qt QML**.

The project combines Japanese-inspired minimalism with a more reactive desktop: contextual surfaces, dynamic media controls, a living center island, polished system panels and fullscreen-aware overlays.

Raohane originally used a mature existing shell foundation so that important Linux desktop behavior did not have to be rewritten all at once. We are now removing that dependency subsystem-by-subsystem.

The end goal is explicit:

> **Raohane must be able to install, run, update and evolve without cloning, executing or depending on another desktop-shell repository.**

---

## 🚧 What we are doing right now

Active development is happening in:

```text
raohane-context-media-foundation
```

Tracked by:

```text
PR #11 · Raohane 0.10 standalone migration batch
```

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

1. finish owning core hardware/system services;
2. remove direct inherited service usage from active Raohane UI;
3. introduce `RaohaneConfig` and a native common framework;
4. delete compatibility runtime layers only after feature parity is preserved;
5. validate the result on real Hyprland hardware before merging the standalone batch.

---

## ✅ Already separated in the development branch

| Area | Raohane ownership |
|---|---|
| Dependency installation | Raohane-owned Arch manifests |
| MPRIS / media | `RaohaneMedia` |
| Bluetooth | `RaohaneBluetooth` |
| PipeWire audio | `RaohaneAudio` |
| NetworkManager | `RaohaneNetwork` |
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
| Dependency / architecture CI | Raohane-owned audit pipeline |

### Service boundary already active

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
```

The development installer also uses Raohane-owned package manifests and no longer runs another shell project's setup process.

---

## 🔧 In progress now

The next service boundary is display control.

A new `RaohaneDisplay` backend is being introduced around:

```text
brightnessctl
     +
ddcutil
     +
hyprsunset
```

The target behavior is to keep the current combined brightness model:

```text
normal range  → hardware brightness
very low range → gamma dimming
```

while dropping legacy compositor branches and unrelated inherited presentation logic.

After display control, the next large backends are notifications, wallpapers and session/system information.

---

## 🧩 Still being migrated

Some mature subsystems remain temporarily inherited so the desktop stays usable while replacements are developed.

The largest remaining areas are:

- display UI cutover for brightness / DDC / gamma / night light;
- notification backend and history ownership;
- wallpaper backend and desktop background renderer;
- system/session information and warnings;
- application/search providers;
- remaining desktop widgets;
- lock/capture/region-selection support;
- remaining shared `modules/common` utilities;
- the inherited configuration schema;
- remaining compatibility `modules/ii` surfaces.

These components are migration scaffolding, not the intended final architecture.

---

## 🗺️ Roadmap to standalone Raohane

### Phase 1 — Installation boundary

- [x] Raohane-owned dependency manifests
- [x] independent dependency installer
- [x] dependency doctor
- [x] stop normal CI from fetching upstream shell repositories
- [x] make legacy config import explicit instead of automatic

### Phase 2 — Core services

- [x] MPRIS / media
- [x] Bluetooth
- [x] PipeWire audio
- [x] NetworkManager
- [x] Privacy / capture state
- [ ] Brightness / DDC — backend currently being integrated
- [ ] Night light / gamma — backend currently being integrated
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
- [ ] remove obsolete upstream lock files

### Phase 5 — Standalone release

- [ ] clean install on a fresh Arch/Hyprland system
- [ ] multi-monitor validation
- [ ] NVIDIA validation
- [ ] AMD / Intel validation
- [ ] fullscreen / game overlay validation
- [ ] package and dependency audit
- [ ] standalone Raohane release

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

### Stable `main`

`main` still contains the current migration foundation. Until PR #11 is runtime-tested and merged, installation directly from `main` uses the existing foundation bootstrap:

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

To test the active independence work:

```bash
git clone https://github.com/snuskidau/raohane-dots.git
cd raohane-dots

git checkout raohane-context-media-foundation

chmod +x install-raohane.sh
./install-raohane.sh --deps

hyprctl reload
raohane restart
```

The development installer uses Raohane-owned package manifests and does **not** execute another shell repository's setup process.

> GPU drivers are never silently selected or replaced. Font binaries remain package-managed instead of being vendored into the repository.

---

## 🎛️ Main controls

Current development commands:

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

## 🧪 Testing a development batch

Passing static QML checks is not enough for a shell release.

A real Hyprland session should verify:

1. startup and restart behavior;
2. bar behavior on every monitor;
3. launcher keyboard focus and search;
4. Control Center toggles and sliders;
5. audio sink/source volume and mute;
6. Bluetooth state and toggling;
7. Wi-Fi / Ethernet state and Wi-Fi toggling;
8. brightness, DDC and gamma behavior;
9. night-light state;
10. notifications and notification history;
11. OSD behavior;
12. MPRIS selection, seek and transport controls;
13. media overlay behavior over fullscreen applications;
14. wallpaper preview/apply/random;
15. desktop context menu;
16. session, lock, logout, reboot and shutdown actions.

Useful failure output:

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
│   ├── raohane/
│   │   ├── services/        # Raohane-owned backend adapters
│   │   └── ...              # native UI / state
│   ├── common/              # shared framework being migrated
│   └── ii/                  # temporary compatibility UI
├── services/                # inherited services being replaced
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

- no silent GPU-driver replacement;
- no vendored font binaries;
- no new Niri-specific product work — Raohane targets Hyprland;
- no Raohane-specific state inside migration-owned `GlobalStates.qml`;
- new product state belongs in Raohane-owned singletons;
- migrated UI should consume stable Raohane service APIs instead of inherited adapters;
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

**Architecture first. Feature parity second. Polish without inherited limits after that.**

`ラオハネ` · Hyprland · Quickshell

</div>
