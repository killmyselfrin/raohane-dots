# Raohane roadmap

The current release target is `0.10.0`. Completed implementation history is recorded in the [changelog](../CHANGELOG.md); this page tracks remaining work.

## Current priorities

- Diagnose increasing CPU or memory use during long sessions, including video wallpapers.
- Fix the reported disappearance of the horizontal bar and verify its fullscreen/reveal behavior.
- Diagnose the reported Log out failure and verify session actions.
- Finish consistent styling and remove duplicate controls across shell surfaces.

## Release validation

These checks require a real Hyprland session and remain open until evidence is recorded:

- [ ] Fresh Arch installation and upgrade from an existing installation.
- [ ] Long-running shell stability, repeated startup/restart, and Settings persistence.
- [ ] Horizontal/vertical bar, dock, overview, and focus/input behavior.
- [ ] Multi-monitor placement and fullscreen/game overlays.
- [ ] NVIDIA and AMD/Intel rendering.
- [ ] Password/PAM, optional fingerprint unlock, and Polkit authentication.
- [ ] Networking, Bluetooth, audio, microphone, and display controls.
- [ ] Wallpapers, thumbnails, notifications, and their interactions.
- [ ] MPRIS controls and lyric lookup/synchronization with browser and native players.
- [ ] Task Manager refresh and process actions on disposable processes.
- [ ] Screenshots, recording, OCR, translation, OSK, and DropShelf.
- [ ] Suspend, hibernate, logout, reboot, and poweroff.

Use `raohane validate release --full` and follow the [release validation guide](RELEASE-VALIDATION.md). Unsupported hardware or untested behavior must remain marked as incomplete. Static checks alone do not establish release readiness.

## Later work

These are candidates rather than scheduled release commitments:

- Theme preview/revert, wallpaper palette extraction, automatic light/dark policy, and per-surface styling.
- Lyrics offset controls, private lyrics, EasyEffects controls, and demand-driven audio visualization.
- Scenes that coordinate theme, wallpaper, audio, notifications, and performance settings; start with manual activation.
- Capture-aware policies for notes, clipboard previews, translations, and selected notifications. Validate protection with the actual capture path.
- Bounded CPU/RAM history, process trees, hardware-specific GPU metrics, optional network metrics, and process priority controls.
- Workspace names/icons, Scene associations, and application restoration rules.
- Context Island events for device changes, capture/privacy state, task completion, and temporary resource warnings.
