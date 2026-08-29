<div align="center">

# ラオハネ · Raohane

### A living desktop shell for Hyprland

**Japanese-inspired · Quickshell-powered · standalone core framework**

[![Hyprland](https://img.shields.io/badge/Hyprland-target-7c5cff?style=for-the-badge)](https://hypr.land/)
[![Quickshell](https://img.shields.io/badge/Quickshell-Qt%2FQML-6f8cff?style=for-the-badge)](https://quickshell.org/)
[![Platform](https://img.shields.io/badge/Linux-Arch%20focused-1793d1?style=for-the-badge&logo=archlinux&logoColor=white)](#installation)
[![Main](https://img.shields.io/badge/main-live%20integration-f0a040?style=for-the-badge)](#main-development-policy)
[![Audit](https://img.shields.io/badge/CI-Raohane%20audit-36b37e?style=for-the-badge)](.github/workflows/raohane-audit.yml)
[![License](https://img.shields.io/badge/License-GPLv3-2f2f2f?style=for-the-badge)](LICENSE)

> **Current phase:** Phase 3 complete · Phase 4 runtime/product parity
>
> **`main` is the live integration/testing branch.** We intentionally install and test the current integration graph there so real Hyprland runtime errors are found early.

</div>

---

## ✦ What is Raohane?

**Raohane** is a Hyprland desktop shell written with **Quickshell / Qt QML**.

The product direction is a Japanese-inspired, responsive desktop rather than only a themed bar: a contextual center island, system controls, living desktop canvas, workspace overview, application dock, fullscreen media overlays, native launcher/search, notifications, wallpaper management and a coherent settings experience.

Raohane began its migration using mature existing shell code so desktop functionality did not have to be reinvented in one unsafe rewrite. That was a migration technique — **not the final architecture**.

The target is explicit:

> **Raohane must install, run, update and evolve without cloning, executing or requiring another desktop-shell repository.**

---

## 🚧 Main development policy

We develop against **`main` directly** for normal integration work.

```text
main
  ↓
static Raohane audit
  ↓
install on real Hyprland session
  ↓
collect runtime errors as one batch
  ↓
fix architecture + runtime together
  ↓
continue product work
```

Separate branches/PRs are reserved for experiments dangerous enough to make the shell broadly unbootable.

---

## ✅ Standalone boundaries already owned by Raohane

### Core system services

| Area | Current owner |
|---|---|
| MPRIS / media | `RaohaneMedia` |
| PipeWire audio | `RaohaneAudio` |
| Bluetooth | `RaohaneBluetooth` |
| NetworkManager | `RaohaneNetwork` |
| Brightness / DDC / gamma | `RaohaneDisplay` |
| Notifications + history | `RaohaneNotifications` |
| Wallpaper filesystem/state | `RaohaneWallpapers` |
| Session / power actions | `RaohaneSession` |
| Shutdown/download warnings | `RaohaneSessionWarnings` |
| System / distro information | `RaohaneSystemInfo` |
| Privacy / capture state | `RaohanePrivacy` |
| Launcher application search | `RaohaneSearch` |

```text
Linux / Hyprland / Quickshell APIs
              │
              ▼
┌──────────────────────────────────┐
│       Raohane-owned services     │
│                                  │
│ Media · Audio · Network          │
│ Bluetooth · Display · Privacy    │
│ Notifications · Wallpapers       │
│ Session · SystemInfo · Search    │
└──────────────────────────────────┘
              │
              ▼
        Raohane-native UI
```

The active service graph is Raohane-owned. The old root compatibility-service tree is no longer part of the source or installed runtime graph.

---

## ⚙️ Native core framework

Raohane owns its persisted configuration and directory APIs:

```text
modules/raohane/config/RaohaneConfig.qml
modules/raohane/config/RaohanePaths.qml
~/.config/raohane/native.json
```

The current schema v10 owns the product settings used by the active shell, including:

- wallpaper and lock-wallpaper paths, browsing, slideshow, dimming, transitions and fullscreen behavior;
- Overview workspace count/layout;
- Dock enable/autohide/pinning/geometry/pinned apps;
- horizontal/vertical Bar behavior, monitor targeting, date and Super reveal;
- Screen Frame and screen-corner/hot-corner behavior;
- OSK preferences and OSD timeout;
- display/night-light state;
- application helper commands;
- local profile identity;
- Quick Controls visibility;
- Context Island/media/integration feature flags.

`RaohanePaths` is the single Raohane directory contract for config, state, cache, runtime capture data, thumbnails, cover art, screenshots, recordings, assets, scripts and defaults. Active services such as notifications persist through this API rather than rebuilding XDG paths independently.

The temporary config bridge was isolated during migration and has now been retired. `RaohaneLegacyBridge.qml`, the inherited config framework and the old compatibility trees are not part of the active source/runtime graph.

Raohane also owns reusable framework primitives and utility modules:

```text
modules/raohane/RaohaneSurface.qml
modules/raohane/RaohaneDivider.qml
modules/raohane/RaohaneIconButton.qml
modules/raohane/helpers/RaohaneUtils.qml
modules/raohane/models/RaohaneSelectionModel.qml
```

The Launcher is an active consumer of the shared surface/model/helper chain, so these are product framework APIs rather than unused migration scaffolding.

Phase 3 completion is enforced by:

```text
scripts/core-framework-phase3-audit.sh
```

---

## 🔎 Native launcher search

The active Raohane Launcher no longer uses inherited `LauncherSearch`, `AppSearch`, fuzzy helpers or `LauncherSearchResult` models.

`RaohaneSearch` currently supports:

```text
firefox        application search
/settings      Raohane built-in actions
> command      shell command
= 2+2          calculator through qalc
: clipboard    clipboard history through cliphist
```

Desktop applications are read directly from Quickshell `DesktopEntries`. Keyboard selection is owned by the native `RaohaneSelectionModel` framework model.

---

## 🖼️ Native desktop pipeline

The wallpaper/desktop path is owned end-to-end by Raohane:

```text
RaohaneWallpaperSelector
          │
          ▼
RaohaneWallpapers + RaohaneConfig
          │
          ▼
RaohaneBackground
          │
          ├── image wallpaper
          ├── Qt Multimedia video wallpaper
          ├── preview / random / slideshow
          └── lock/fullscreen behavior
          │
          ▼
RaohaneDesktopCanvas
```

Desktop context presentation is deliberately separated into `RaohaneDesktopCanvas` instead of being mixed into the wallpaper backend.

---

## 間 Native Spaces / Overview

`RaohaneOverview` is the active workspace view. It talks directly to Hyprland workspaces/toplevels and no longer mixes workspace navigation with an inherited launcher/search implementation.

It supports:

- real Hyprland workspaces and window titles;
- keyboard navigation;
- click/Enter workspace activation;
- direct activation of individual toplevel windows;
- configurable workspace grouping/columns;
- clipboard shortcut routing into the native Raohane Launcher.

---

## ◇ Native Dock

`RaohaneDock` is built directly on Quickshell `ToplevelManager` and `DesktopEntries` and supports:

- pinned applications persisted in `RaohaneConfig`;
- active/running app discovery;
- multiple windows per app;
- click-to-focus/cycle windows;
- middle-click new instance;
- right-click pin/unpin;
- autohide and pinned modes;
- fullscreen-aware reveal behavior;
- multi-monitor instances;
- Spaces shortcut into `RaohaneOverview`;
- a compact entry into the native media overlay.

It does **not** depend on inherited taskbar/search/media models.

---

## ♪ Native media surface

`RaohaneMediaOverlay` is the media-controls surface loaded by `RaohaneFamily` and talks to the Raohane-owned MPRIS service.

---

## ✨ Raohane-native product surfaces

Current Raohane-owned presentation includes:

- horizontal and vertical bars;
- Context Island;
- Background renderer;
- living Desktop Canvas;
- Spaces / workspace Overview;
- application Dock;
- launcher;
- Control Center;
- Settings;
- media/game overlay;
- OSD;
- notification popup + notification center;
- wallpaper selector;
- desktop context menu;
- session/power screen;
- native Lock/PAM/fingerprint surface;
- Polkit authentication;
- OSK;
- capture/OCR/search/recording;
- screen translation;
- DropShelf, side panel, screen frame and corners.

The project is **Hyprland-first and Hyprland-only as a product target**. We are not adding parallel Niri product architecture.

---

## 🧩 What remains after the core framework

Phase 3 no longer has a compatibility/common-framework dependency to remove. Remaining work is product/runtime completion rather than framework extraction:

- continue UI/UX parity and polish across all native surfaces;
- exercise Lock, fingerprint, Polkit, OSK, capture and translation in real sessions;
- validate vertical/horizontal bar behavior and fullscreen/game interaction;
- validate multi-monitor placement and focus behavior;
- complete fresh-install and hardware validation across NVIDIA/AMD/Intel;
- finish release packaging/versioning and the final source-lineage/license audit.

Static CI proves the source/integration boundaries; real Wayland/PAM/GPU behavior still requires live validation.

---

## 🗺️ Roadmap

### Phase 1 — Installation boundary

- [x] Raohane-owned Arch dependency manifests
- [x] independent dependency installer
- [x] dependency doctor
- [x] normal install does not clone/execute another shell repository
- [x] CI does not fetch an upstream shell
- [x] legacy config migration is explicit

### Phase 2 — Core services

- [x] Media / MPRIS
- [x] Audio / PipeWire
- [x] Bluetooth
- [x] NetworkManager
- [x] Display / brightness / DDC / gamma
- [x] Privacy / capture state
- [x] Notifications / history
- [x] Wallpapers backend
- [x] Session actions / warnings
- [x] System information
- [x] Launcher application search

### Phase 3 — Core framework

- [x] first standalone `RaohaneConfig`
- [x] isolated compatibility config bridge (retired after migration)
- [x] native wallpaper/overview/dock schema
- [x] expand native config to the complete current product schema
- [x] Raohane-owned paths/directories API
- [x] Raohane-owned common widgets
- [x] Raohane-owned models/helpers
- [x] remove active UI dependence on compatibility services/common framework

Phase 3 is guarded by `scripts/core-framework-phase3-audit.sh` in the required GitHub Actions workflow.

### Phase 4 — Visible runtime cleanup

- [x] native Background + desktop canvas
- [x] native Overview/workspace UI
- [x] native Dock
- [x] native media controls surface in active runtime
- [ ] native Lock runtime validation
- [ ] vertical-bar runtime/product validation
- [ ] native remaining screen chrome/capture runtime validation
- [ ] final Settings UX/parity pass
- [x] remove `modules/ii` runtime imports/source tree

### Phase 5 — Remove migration scaffolding

- [x] delete inherited service graph after all consumers migrate
- [x] delete compatibility config bridge
- [x] delete upstream panel-family fallback
- [x] delete obsolete upstream sync/bootstrap scripts
- [x] delete obsolete upstream lock files
- [ ] final source-lineage/license audit

### Phase 6 — Standalone release validation

- [ ] clean install on fresh Arch + Hyprland
- [ ] NVIDIA validation
- [ ] AMD / Intel validation
- [ ] multi-monitor validation
- [ ] fullscreen/game overlay validation
- [x] package/dependency static audit
- [ ] release packaging/versioning

---

## 📦 Installation

### Fresh installation from `main`

```bash
git clone https://github.com/killmyselfrin/raohane-dots.git
cd raohane-dots

chmod +x install-raohane.sh
./install-raohane.sh --deps

hyprctl reload
raohane restart
```

The dependency installer uses Raohane-owned Arch manifests. It does **not** run another shell project's setup script.

> Raohane does not silently choose or replace GPU drivers. Font binaries remain package-managed instead of being vendored into the repository.

### Updating an existing checkout

```bash
cd raohane-dots
git checkout main
git pull --ff-only

./install-raohane.sh
hyprctl reload
raohane restart
```

---

## 🎛️ Main commands

```bash
raohane launcher
raohane control
raohane settings
raohane media
raohane desktop
raohane wallpaper
raohane wallpaper random
raohane session
raohane translate
```

Diagnostics:

```bash
raohane doctor all
raohane doctor runtime
raohane doctor deps
raohane doctor services
raohane doctor graphics
raohane wifi status
raohane audio status
```

Foreground runtime debugging:

```bash
raohane stop
raohane run
```

Logs:

```bash
raohane logs
```

---

## 🧪 Runtime testing workflow

Static CI is useful, but it cannot validate a real compositor session.

When testing `main`, collect a **batch** of failures instead of stopping at the first cosmetic issue.

Recommended sequence:

```bash
raohane doctor all
raohane stop
raohane run
```

Then exercise:

1. horizontal/vertical bar and workspaces;
2. Spaces / Overview navigation and toplevel focus;
3. native Dock: running apps, pinned apps, middle/right click and autohide;
4. launcher and its `/`, `>`, `=`, `:` modes;
5. Control Center network/Bluetooth/audio/display controls;
6. notifications + actions + history;
7. volume/brightness OSD;
8. MPRIS and Media Overlay;
9. image/video wallpaper preview/apply/random;
10. Desktop Canvas and desktop context menu;
11. Settings pages;
12. lock/session/logout/reboot/shutdown;
13. fingerprint/PAM and Polkit;
14. OSK/ydotool key release;
15. capture/OCR/translation/recording;
16. microphone/camera/screen-sharing privacy state;
17. fullscreen game/overlay behavior;
18. multiple monitors if available.

If something fails, the most useful output is the full terminal section around the error plus `raohane doctor all`.

---

## 🛡️ Raohane audit

The repository runs `.github/workflows/raohane-audit.yml`.

It validates:

- Bash syntax;
- QML parsing for all Raohane-owned QML;
- module/qmldir integrity;
- native service ownership;
- complete current product-config persistence contract;
- Raohane-owned paths/directories;
- reusable widgets/models/helpers and active consumers;
- compatibility-free active startup/UI graph;
- wallpaper/background ownership;
- Overview and Dock/toplevel ownership;
- native media ownership;
- launcher-search ownership;
- lock/PAM/fingerprint, Polkit and OSK boundaries;
- capture/translation runtime-surface boundaries;
- installer/dependency independence;
- integration graph completeness;
- clean checkout after validation.

Core-framework regressions are explicitly guarded by:

```text
scripts/core-framework-audit.sh
scripts/core-framework-phase3-audit.sh
```

This prevents native components from silently drifting back toward a compatibility/common framework.

---

## 🧱 Repository direction

```text
raohane-dots/
├── modules/
│   └── raohane/
│       ├── config/          # standalone persisted config + path API
│       ├── helpers/         # Raohane-owned utility helpers
│       ├── models/          # reusable product models
│       ├── services/        # Raohane-owned backend services
│       ├── osk/             # native keyboard data
│       └── *.qml            # native framework + product surfaces/state
├── panelFamilies/
│   └── RaohaneFamily.qml
├── install/
│   └── arch/                # Raohane package manifests
├── scripts/
│   ├── raohane
│   ├── raohane-audit.sh
│   ├── core-framework-phase3-audit.sh
│   └── *-boundary-audit.sh
├── defaults/
│   └── native.json
├── shell.qml
└── install-raohane.sh
```

---

## 🔒 Project rules

- Hyprland is the product compositor target.
- No silent GPU-driver replacement.
- No vendored font binaries.
- New backend code uses Raohane-owned APIs.
- New persisted product settings belong in `RaohaneConfig`.
- New filesystem/config/cache/runtime paths belong in `RaohanePaths`.
- Reusable native UI belongs in Raohane-owned framework primitives rather than ad-hoc compatibility widgets.
- Normal install/doctor/CI paths must not execute another shell repository.
- Do not remove legally required attribution while derived code remains.

---

## 📜 Licensing and source lineage

Raohane is distributed under **GPLv3**.

The repository retains attribution for code with upstream lineage from the migration period. Technical independence does not erase authorship or licensing history.

See:

- [`NOTICE-UPSTREAM.md`](NOTICE-UPSTREAM.md)
- [`INDEPENDENCE-PLAN.md`](INDEPENDENCE-PLAN.md)
- [`ARCHITECTURE.md`](ARCHITECTURE.md)
- [`RAOHANE-CHANGELOG.md`](RAOHANE-CHANGELOG.md)

---

<div align="center">

### Raohane now owns its core framework.

**Own the services. Own the state. Own the UI. Validate the product.**

`ラオハネ` · Hyprland · Quickshell

</div>
