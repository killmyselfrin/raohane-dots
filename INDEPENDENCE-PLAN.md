# Raohane independence plan

Raohane's standalone migration goal is a Hyprland + Quickshell shell that does not require end4-pC, illogical-impulse, iNiR, Serpantinum or another shell repository at runtime, install time, update time or normal development time.

As of the current native source boundary, that architectural migration is complete. Upstream projects remain references/provenance only; Raohane owns its runtime graph, dependency manifest, configuration schema, services, UI, scripts and installer.

## Independence status

The following gates are complete:

- installation does not clone or execute another shell repository;
- active QML imports only Raohane-owned runtime modules;
- `modules/common`, `modules/ii` and root inherited `services/` are physically removed;
- inherited root QML and obsolete panel families are physically removed;
- upstream synchronizer/bootstrap scripts and source lock files are removed;
- retired helper script families and the inherited default config are removed;
- Raohane owns its Arch dependency manifests and dependency installer;
- Raohane owns persistent schema v10 and native state/path contracts;
- older native schema documents are upgraded before shell startup without discarding user values;
- Raohane owns audio, media, network, Bluetooth, display, notifications, wallpaper, session, idle, search, autostart, OSK and DropShelf service boundaries;
- all active visible surfaces are Raohane-owned;
- installed runtime pruning prevents stale legacy trees from surviving upgrades;
- CI parses and audits the standalone Raohane graph;
- required provenance/license notices remain where derivative lineage still matters.

## Completed migration phases

### Phase A — Product surfaces — complete

The active family is composed entirely from `modules/raohane` surfaces: bars, launcher, control center, Settings, media overlay, OSD, notifications, wallpaper selector, desktop menu, overview, dock, background, desktop canvas, lock, Polkit, capture/translation, OSK, sidebars, overlay, DropShelf, screen frame/corners and session UI.

### Phase B — Service ownership — complete

Active product code uses Raohane-owned service interfaces and direct system/Quickshell backends instead of inherited service namespaces.

### Phase C — Config/common ownership — complete

Raohane owns `RaohaneConfig`, `RaohaneState`, `RaohanePaths`, theme/widgets/helpers and persistent `~/.config/raohane/native.json`. The inherited common/config/state framework is no longer present in the source graph.

### Phase D — Dependency independence — complete

`install/arch/required.txt` and `install/arch/features.txt` define the supported Arch dependency set. `scripts/install-deps.sh` resolves those manifests without invoking another shell project. `raohane doctor deps` reports package and command availability.

### Phase E — Migration scaffolding removal — complete

The inherited source trees, upstream sync/bootstrap tooling, obsolete panel families, old root QML, retired helper script families and legacy default config have been removed. Defensive runtime pruning remains only to clean stale files from users upgrading an older installed copy.

## Remaining release gates

Architectural independence is not the same as release completeness. The remaining work is validation and product parity rather than dependency migration:

- repeated real Hyprland startup/restart testing;
- multi-monitor placement and focus/input behavior;
- fullscreen/game overlay behavior and GPU load;
- NVIDIA, AMD and Intel graphics validation;
- horizontal/vertical bar parity and dock behavior;
- overview window activation/interaction;
- Settings persistence and all exposed controls;
- wallpaper image/video transitions and thumbnail generation;
- launcher apps/actions/commands/calculator/clipboard modes;
- notifications and action handling;
- audio, brightness, gamma, networking and Bluetooth controls;
- MPRIS/media behavior;
- screenshot, recording, OCR and translation backends;
- OSK + ydotool permissions/input;
- WlSessionLock + PAM + fingerprint authentication;
- Polkit authentication;
- suspend/reboot/poweroff/logout flows;
- clean-install packaging/versioning and upgrade tests.

Static CI must continue to guard the native-only graph, but compositor/device behavior must be tested in a real session.

## Licensing boundary

Technical independence does not automatically erase source-code lineage. Applicable upstream notices must remain for derivative code/assets that are still redistributed. Replacing inherited implementation with independently written Raohane code reduces technical coupling; attribution should only be removed when licensing/provenance actually allows it.

This document is an engineering status/roadmap, not legal advice.
