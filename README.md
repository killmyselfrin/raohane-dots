<div align="center">

# ラオハネ · Raohane

### A living desktop shell for Hyprland

**Japanese-inspired · Quickshell-powered · moving toward a fully standalone shell**

[![Hyprland](https://img.shields.io/badge/Hyprland-target-7c5cff?style=for-the-badge)](https://hypr.land/)
[![Quickshell](https://img.shields.io/badge/Quickshell-Qt%2FQML-6f8cff?style=for-the-badge)](https://quickshell.org/)
[![Platform](https://img.shields.io/badge/Linux-Arch%20focused-1793d1?style=for-the-badge&logo=archlinux&logoColor=white)](#installation)
[![Main](https://img.shields.io/badge/main-live%20integration-f0a040?style=for-the-badge)](#main-development-policy)
[![Audit](https://img.shields.io/badge/CI-Raohane%20audit-36b37e?style=for-the-badge)](.github/workflows/raohane-audit.yml)
[![License](https://img.shields.io/badge/License-GPLv3-2f2f2f?style=for-the-badge)](LICENSE)

> **Current phase:** Standalone / Independence Migration
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
continue migration
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

Compatibility service names still exist where old UI expects them, but several are now **facades**, not backend owners. Notifications, Wallpapers, SessionWarnings, SystemInfo and Session compatibility APIs route into Raohane services instead of running duplicate implementations.

---

## ⚙️ Native configuration

Raohane has a separate persisted config module:

```text
modules/raohane/config/RaohaneConfig.qml
~/.config/raohane/native.json
```

The native schema currently owns:

- wallpaper path, directory, preview, slideshow and rendering behavior;
- native Overview workspace count/layout;
- native Dock enable/autohide/pin/geometry/pinned apps;
- display color temperature;
- selected application commands;
- Raohane feature flags.

During migration, `RaohaneLegacyBridge` is the **single intentional synchronization boundary** between the new config and the inherited compatibility config. New backend services should not import the old `Config.qml` directly.

Already consuming native config directly include `RaohaneWallpapers`, `RaohaneDisplay`, `RaohaneSession`, `RaohaneBackground`, `RaohaneOverview` and `RaohaneDock`.

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

Desktop applications are read directly from Quickshell `DesktopEntries`.

---

## 🖼️ Native desktop pipeline

The wallpaper/desktop path is now owned end-to-end by Raohane:

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

`RaohaneBackground` replaced the inherited monolithic background in the active panel family. Desktop context presentation is deliberately separated into `RaohaneDesktopCanvas` instead of being mixed into the wallpaper backend.

---

## 間 Native Spaces / Overview

`RaohaneOverview` is now the active workspace view. It talks directly to Hyprland workspaces/toplevels and no longer mixes workspace navigation with the old launcher/search implementation.

It supports:

- real Hyprland workspaces and window titles;
- keyboard navigation;
- click/Enter workspace activation;
- configurable workspace grouping/columns;
- preserved compatibility shortcuts and `search` IPC while existing bindings migrate;
- clipboard shortcut routing into the native Raohane Launcher.

---

## ◇ Native Dock

`RaohaneDock` replaced the inherited Dock in the active runtime.

It is built directly on Quickshell `ToplevelManager` and `DesktopEntries` and supports:

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

It does **not** depend on inherited `TaskbarApps`, `AppSearch`, `MprisController` or the old Dock UI.

---

## ♪ Native media surface

`RaohaneMediaOverlay` is now the only media-controls surface loaded by `RaohaneFamily`.

The inherited `modules/ii/mediaControls` implementation is no longer loaded. Existing `mediaControls` IPC plus `mediaControlsToggle`, `mediaControlsOpen` and `mediaControlsClose` shortcuts are absorbed by the native overlay so old bindings can continue working during migration.

---

## ✨ Raohane-native product surfaces

Current Raohane-owned presentation includes:

- horizontal bar;
- Context Island;
- Background renderer;
- living Desktop Canvas;
- Spaces / workspace Overview;
- application Dock;
- launcher;
- Control Center internals;
- Settings navigation + Control Deck;
- media/game overlay;
- OSD;
- notification popup + notification center;
- wallpaper selector;
- desktop context menu;
- session/power screen.

The project is **Hyprland-first and Hyprland-only as a product target**. We are not adding parallel Niri product architecture.

---

## 🧩 What is still temporary

The repository is not fully standalone yet. Important compatibility code remains while feature parity is preserved.

Largest remaining active areas:

- vertical bar;
- Lock UI;
- capture / region selection / screen translation;
- Polkit / OSK / left sidebar compatibility surfaces;
- Overlay / DropShelf / ScreenFrame chrome;
- heavy inherited Settings pages;
- portions of shared `modules/common` widgets/models/functions;
- the inherited config schema used by remaining compatibility UI;
- old service files that still support compatibility surfaces;
- upstream migration/sync material that can be deleted only after its code is no longer required.

The inherited Background, Overview, Dock and MediaControls code may still exist in the source tree for lineage/reference, but **they are no longer part of the active Raohane panel family**.

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
- [x] isolated compatibility config bridge
- [x] native wallpaper/overview/dock schema
- [ ] expand native config to the complete product schema
- [ ] Raohane-owned paths/directories API
- [ ] Raohane-owned common widgets
- [ ] Raohane-owned models/helpers
- [ ] remove active UI dependence on compatibility services/common framework

### Phase 4 — Visible runtime cleanup

- [x] native Background + desktop canvas
- [x] native Overview/workspace UI
- [x] native Dock
- [x] native media controls surface in active runtime
- [ ] native Lock
- [ ] native vertical-bar strategy or explicitly horizontal-only product decision
- [ ] native remaining screen chrome/capture surfaces
- [ ] migrate remaining Settings pages
- [ ] remove remaining `modules/ii` runtime imports

### Phase 5 — Remove migration scaffolding

- [ ] delete inherited service graph after all consumers migrate
- [ ] delete compatibility config bridge
- [ ] delete upstream panel-family fallback
- [ ] delete obsolete upstream sync/bootstrap scripts
- [ ] delete obsolete upstream lock files
- [ ] final source-lineage/license audit

### Phase 6 — Standalone release validation

- [ ] clean install on fresh Arch + Hyprland
- [ ] NVIDIA validation
- [ ] AMD / Intel validation
- [ ] multi-monitor validation
- [ ] fullscreen/game overlay validation
- [ ] package/dependency audit
- [ ] release packaging/versioning

---

## 📦 Installation

### Fresh installation from `main`

```bash
git clone https://github.com/snuskidau/raohane-dots.git
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

1. horizontal bar and workspaces;
2. Spaces / Overview navigation;
3. native Dock: running apps, pinned apps, middle/right click and autohide;
4. launcher and its `/`, `>`, `=`, `:` modes;
5. Control Center network/Bluetooth/audio/display controls;
6. notifications + actions + history;
7. volume/brightness OSD;
8. MPRIS and Media Overlay, including legacy media-controls shortcut names;
9. image/video wallpaper preview/apply/random;
10. Desktop Canvas and desktop context menu;
11. Settings pages;
12. lock/session/logout/reboot/shutdown;
13. microphone/camera/screen-sharing privacy state;
14. fullscreen game/overlay behavior;
15. multiple monitors if available.

If something fails, the most useful output is the full terminal section around the error plus `raohane doctor all`.

---

## 🛡️ Raohane audit

The repository runs `.github/workflows/raohane-audit.yml`.

It validates:

- Bash syntax;
- QML parsing for all Raohane-owned QML;
- module/qmldir integrity;
- native service ownership;
- native config ownership;
- wallpaper/background ownership;
- Overview ownership;
- Dock/toplevel ownership;
- native media overlay ownership and compatibility entrypoints;
- launcher-search ownership;
- compatibility facade boundaries;
- installer/dependency independence;
- integration graph completeness;
- clean checkout after validation.

Service/config regressions are additionally guarded by:

```text
scripts/service-boundary-audit.sh
```

This prevents migrated components from silently drifting back to old backend implementations.

---

## 🧱 Repository direction

```text
raohane-dots/
├── modules/
│   ├── raohane/
│   │   ├── config/          # standalone Raohane persisted config
│   │   ├── services/        # Raohane-owned backend services
│   │   └── *.qml            # native product surfaces/state
│   ├── common/              # compatibility framework being reduced
│   └── ii/                  # compatibility UI being replaced
├── services/                # remaining services/facades during migration
├── panelFamilies/
│   └── RaohaneFamily.qml
├── install/
│   └── arch/                # Raohane package manifests
├── scripts/
│   ├── raohane
│   ├── raohane-audit.sh
│   └── service-boundary-audit.sh
├── defaults/
├── shell.qml
└── install-raohane.sh
```

---

## 🔒 Project rules

- Hyprland is the product compositor target.
- No silent GPU-driver replacement.
- No vendored font binaries.
- New backend code should use Raohane-owned APIs.
- New persisted product settings belong in `RaohaneConfig`.
- Compatibility synchronization belongs in `RaohaneLegacyBridge`, not scattered through services.
- Normal install/doctor/CI paths must not execute another shell repository.
- Do not remove legally required attribution while derived code remains.

---

## 📜 Licensing and source lineage

Raohane is distributed under **GPLv3**.

The current repository still contains code with upstream lineage from the migration period. Relevant licensing and attribution must remain while that derivative code remains in the tree.

Independence means removing permanent technical dependence — not rewriting authorship history.

See:

- [`NOTICE-UPSTREAM.md`](NOTICE-UPSTREAM.md)
- [`INDEPENDENCE-PLAN.md`](INDEPENDENCE-PLAN.md)
- [`ARCHITECTURE.md`](ARCHITECTURE.md)
- [`RAOHANE-CHANGELOG.md`](RAOHANE-CHANGELOG.md)

---

<div align="center">

### Raohane is becoming its own shell.

**Own the services. Own the state. Own the UI. Then remove the scaffolding.**

`ラオハネ` · Hyprland · Quickshell

</div>
