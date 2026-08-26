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

The product direction is a Japanese-inspired, responsive desktop rather than only a themed bar: a contextual center island, system controls, media surfaces, fullscreen overlays, native launcher/search, notifications, wallpaper management and a coherent settings experience.

Raohane began its migration using mature existing shell code so desktop functionality did not have to be reinvented in one unsafe rewrite. That was a migration technique — **not the final architecture**.

The target is explicit:

> **Raohane must install, run, update and evolve without cloning, executing or requiring another desktop-shell repository.**

---

## 🚧 Main development policy

We now develop against **`main` directly** for normal integration work.

That means:

```text
main
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

Older foundation PRs were closed as superseded rather than merged back into the current architecture.

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

The active service direction now looks like this:

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

Compatibility service names still exist where old UI expects them, but several of them are now **facades**, not backend owners. For example, the compatibility Notifications, Wallpapers, SessionWarnings, SystemInfo and Session APIs route into Raohane services instead of running duplicate implementations.

---

## ⚙️ Native configuration has started

Raohane now has a separate persisted config module:

```text
modules/raohane/config/RaohaneConfig.qml
~/.config/raohane/native.json
```

The first native settings cover wallpaper state, display temperature, selected app commands and Raohane feature flags.

During migration, `RaohaneLegacyBridge` is the **single intentional synchronization boundary** between the new config and the inherited compatibility config. New backend services should not import the old `Config.qml` directly.

Already moved to `RaohaneConfig`:

- `RaohaneWallpapers`
- `RaohaneDisplay`
- `RaohaneSession`

The bridge will disappear when the remaining old settings pages/background components have moved to native configuration.

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

## ✨ Raohane-native product surfaces

Current Raohane-owned presentation includes:

- horizontal bar;
- Context Island;
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

The repository is not fully standalone yet. Important compatibility code still exists while feature parity is preserved.

Largest remaining areas:

- desktop background renderer and desktop widget canvas;
- vertical bar;
- workspace/window Overview;
- Dock and Lock UI;
- capture / region selection / screen translation;
- Polkit / OSK / left sidebar compatibility surfaces;
- heavy inherited Settings pages;
- portions of shared `modules/common` widgets/models/functions;
- the large inherited config schema used by compatibility UI;
- old service files that still support compatibility surfaces;
- old upstream migration/sync material that can be deleted only after its code is no longer required.

These are migration scaffolding, not the desired final structure.

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
- [ ] expand native config to the complete product schema
- [ ] Raohane-owned paths/directories API
- [ ] Raohane-owned common widgets
- [ ] Raohane-owned models/helpers
- [ ] remove active UI dependence on compatibility services/common framework

### Phase 4 — Visible runtime cleanup

- [ ] native Background + desktop canvas
- [ ] native Overview/workspace UI
- [ ] native Dock
- [ ] native Lock
- [ ] native vertical-bar strategy or explicitly horizontal-only product decision
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

1. bar and workspaces;
2. launcher and its `/`, `>`, `=`, `:` modes;
3. Control Center network/Bluetooth/audio/display controls;
4. notifications + actions + history;
5. volume/brightness OSD;
6. MPRIS and Media Overlay;
7. wallpaper preview/apply/random;
8. desktop context menu;
9. Settings pages;
10. lock/session/logout/reboot/shutdown;
11. microphone/camera/screen-sharing privacy state;
12. fullscreen game/overlay behavior;
13. multiple monitors if available.

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
