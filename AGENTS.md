# Raohane Engineering Contract

Raohane is a standalone Hyprland + Quickshell desktop shell.

This repository is the canonical source of truth for the project. ChatGPT acts as architecture/design lead and reviewer; Codex is expected to execute implementation and refactoring tasks against this repository while respecting this contract.

## Product identity

- Product name: **Raohane**
- Japanese mark: **ラオハネ**
- Compositor: **Hyprland only**
- Shell/UI runtime: **Quickshell / QML**
- User-facing CLI: `raohane`
- User service: `raohane.service`
- Runtime path: `~/.config/quickshell/raohane`
- User configuration namespace: `raohane.*`

Raohane must feel like an independent shell. Do not reintroduce iNiR, Niri, Waffle, Ricelin, or other upstream shell identities into primary UI or user-facing commands.

## Architectural direction

Primary UI must live under `modules/raohane/` and be loaded directly by the shell entrypoint.

Core surfaces:

- `RaohaneBar`
- `ContextIsland`
- `RaohaneControlCenter`
- `RaohaneSettings`
- `RaohaneLauncher`
- `GameMediaOverlay`
- Raohane-native OSD / notification surfaces

Legacy code may temporarily remain only as a backend compatibility layer while functionality is migrated. New UI work must not depend on legacy visual components.

### Allowed transitional backend reuse

The following kinds of existing services may be reused until replaced, provided they are not exposed as old product identity:

- MPRIS / media control
- NetworkManager integration
- Bluetooth integration
- Audio / PipeWire integration
- Notifications
- Hyprland workspace/window data
- Brightness and power services
- System information

When touching a legacy backend service, prefer moving paths, service names, IPC names, cache/state directories, and configuration keys toward Raohane-native equivalents.

## Design language

Raohane's visual identity is:

- Japanese minimalism
- dark translucent glass surfaces
- floating islands instead of one monolithic panel
- restrained purple / magenta accenting
- soft organic motion rather than excessive effects
- high information density without visual clutter
- wallpaper-aware and media-aware accent behavior
- subtle `ラオハネ` details, not anime-themed UI overload

The current target concept includes:

- three-zone floating top bar
- central Context Island
- compact left workspace cluster
- right system status cluster
- layered Control Center on the right
- independent Settings surface
- floating launcher
- game media overlay

## Reference projects

### end4-pC

`pctrade/end4-pC` is an architectural and UX reference only.

Useful ideas to study:

- modular left / middle / right bar composition
- independent settings surface
- Control Center separation into quick actions, sliders, media, notifications and detail pages
- dedicated dialogs for Wi-Fi, Bluetooth and audio
- modular shell surfaces instead of a single giant sidebar

Do **not** clone its visual design or copy source code into Raohane unless licensing implications are explicitly reviewed and accepted. Raohane must retain its own component structure and visual identity.

### iNiR / legacy upstream

Treat inherited iNiR code as migration debt, not as the design specification.

Do not create new dependencies on old iNiR UI modules. When practical, replace them with Raohane-native components or isolate them behind backend services.

## Context Island

Context Island is a defining Raohane feature, not merely a media widget.

It should evolve as a state machine, with priority roughly:

1. critical privacy / recording state
2. microphone / camera state
3. temporary system event
4. active media
5. active-window context
6. idle/default state

Transitions should be smooth and spatially coherent. Avoid abrupt width/height jumps where animation can preserve continuity.

## Control Center

Control Center must be Raohane-native and must not load the old sidebar UI.

Structure should generally be:

1. header/status area
2. quick actions
3. volume / brightness controls
4. media card
5. notification summary/list
6. detail pages for Wi-Fi, Bluetooth, audio, night light, etc.

Detail pages should replace content inside the same surface rather than spawning unrelated legacy panels.

## Settings

Settings must use a Raohane-native registry and Raohane-native pages.

Primary pages currently expected:

- Home
- Appearance
- Bar & Island
- Control Center
- Effects / Motion
- Media
- Hyprland
- System

Do not expose old shell-family selectors or obsolete Niri/iNiR settings.

Settings should provide live previews when feasible instead of presenting every option as a generic list of Material cards.

## Launcher

The launcher should support keyboard-first operation:

- type to search
- Up / Down selection
- Enter to launch
- Escape to close

Longer-term it may also expose commands/actions, but application launching must remain fast and predictable.

## Hyprland integration

- Hyprland only.
- Use `hyprctl` or Quickshell's Hyprland integration where appropriate.
- Do not add Niri socket detection or Niri-specific behavior.
- Keep Raohane-generated Hyprland configuration isolated so installation does not overwrite the user's primary config.

Expected user binds include, where implemented:

- `SUPER + /` — Hotkey Assistant
- `SUPER + SHIFT + M` — Game Media Overlay

## File and naming rules

For new code:

- prefer `Raohane*` names for primary surfaces
- keep new primary UI under `modules/raohane/`
- do not add new `inir`, `niri`, `waffle`, or `ricelin` names
- use `raohane` for cache/state/service/IPC names where migration allows

Do not mass-rename blindly. Preserve working backend behavior until each migration is verified.

## Quality gates

Before considering an implementation complete:

1. run `./scripts/raohane-audit.sh` when present
2. run shell syntax checks for changed scripts (`bash -n`)
3. verify all `qmldir` entries point to existing files
4. verify local `import qs...` modules resolve
5. search primary UI for forbidden legacy identity strings
6. avoid new QML singleton registration mistakes
7. avoid a single missing QML type cascading into the whole shell
8. keep the shell launchable even if optional services such as BlueZ are unavailable

If Quickshell/qmllint is unavailable in the environment, perform static checks and state the limitation clearly.

## Implementation discipline

- Prefer small coherent refactors over broad blind rewrites.
- Preserve functionality while replacing visual architecture.
- Do not claim a feature works unless its execution path exists end-to-end.
- Do not hide runtime errors with catch-all fallbacks unless the fallback is intentionally designed.
- Keep UI state ownership explicit.
- Avoid duplicate global state when one service already owns the state.
- Do not poll external commands when a native Quickshell service/event source is available.

## Collaboration workflow

### ChatGPT / architecture lead

Expected responsibilities:

- product architecture
- UX direction
- design-system decisions
- decomposition of large migrations
- review of Codex pull requests
- identifying legacy debt and migration boundaries

### Codex / implementation agent

Expected responsibilities:

- implement scoped tasks from this contract and issue/PR descriptions
- perform repository-wide refactors when requested
- run available tests/audits
- keep changes reviewable
- explain unresolved runtime limitations in PR summaries

For substantial changes, prefer a branch and pull request rather than committing directly to `main`.

## Current priority

The current priority is to make Raohane visually and architecturally independent before adding a large number of new features.

Order of work:

1. Bar + Context Island quality
2. Control Center and native detail pages
3. Settings native pages and previews
4. Launcher quality
5. OSD / notification surfaces
6. legacy backend removal
7. polish, motion, performance and accessibility

The litmus test is simple: a user should not be able to look at Raohane and identify it as a lightly reskinned iNiR shell.
