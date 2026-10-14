# Raohane roadmap — stabilization and design polish

This document tracks work **after the 1.2.1 baseline**. `VERSION` is the
authoritative installed version; see [CHANGELOG](../CHANGELOG.md) for shipped
features. The pending 1.3 release candidate is not a validated stable release.

## P0 — Make daily use predictable

- [ ] Reproduce and profile CPU/RSS growth in long sessions (static and video
  wallpapers, music, opening/closing Settings and Overview, gaming/fullscreen).
  Use `raohane doctor performance` at idle and while the problem is visible,
  together with `raohane validate smoke`. Record machine specs and elapsed time.
- [ ] Confirm horizontal **and** vertical Bar reappear after fullscreen exit,
  workspace moves, display hotplug, suspend/resume, and display reconfiguration.
  The compositor-facing layer window should not be needlessly destroyed.
- [ ] Confirm no duplicated Quickshell instances after repeated service restart,
  user login, upgrades, and crash recovery.
- [ ] Exercise Settings persistence, single-owner Wi-Fi/Bluetooth/audio controls,
  and application launchers without QML binding loops or stale state.
- [ ] Test NVIDIA and integrated/AMD hardware and multi-monitor layouts,
  including mixed scaling and game fullscreen.
- [ ] Keep background work demand-driven. Destroy expensive hidden views; pause
  video decoding in fullscreen when configured; don't poll for data already
  exposed by native Quickshell subscriptions.
- [ ] Validate update recovery and rollback; avoid installing unvalidated
  `main` commits without an explicit user opt-in.

### P0 acceptance gate

Collect real Hyprland evidence for at least one extended idle session and one
session with repeated launcher/Settings/Control Center/Overview opens, wallpaper
changes, and fullscreen transitions. Save CPU/RSS snapshots and Quickshell logs.
Run `raohane validate release --full` **only in an appropriate test session**:
its optional exercises may lock the screen or use capture/PAM. No critical QML
runtime errors, restart loops, disappearing bars, or unexpectedly persistent
heavy background tasks. CI syntax/boundary checks alone are not sufficient.

## P1 — Consistent Raohane Nocturne UI

- [ ] Apply the existing shared surface, spacing, typography, accent and motion
  tokens consistently across Bar, Context Island, Settings, Control Center,
  Launcher, Overview, Wallpaper Selector, Media and Notifications.
- [ ] Keep one clearly owned control for every system function. Avoid duplicate
  volume/microphone/Wi-Fi tiles or copies of the same autohide/date setting.
- [ ] Make Settings navigation fast and compact, with responsive layouts,
  accessible contrast, clear focus, meaningful previews and no duplicate rails.
- [ ] Tune the floating Bar and Context Island for crowded layouts and smaller
  displays. Preserve vertical mode, keyboard/screen-reader affordances, and
  user-customizable module ordering.
- [ ] Tune animations for responsiveness and respect reduced-motion and Gaming
  policies. Favor quiet borders and translucent surfaces over heavy glow layers.
- [ ] Validate all visual changes with screenshots from a real session at 1080p,
  a smaller resolution and one high-DPI/multi-monitor setup.

Avoid competing edits to in-progress Settings ownership work until its open
pull requests are resolved.

## P2 — Features worth adding, after P0/P1

These are **ideas**, not claimed shipped capabilities. Check existing Settings
and service contracts before adding any new control.

- Wallpaper palette extraction integrated with the existing central theme and
  matugen configuration, with preview/revert and user-preset preservation.
- Workspace labels/app icons and clearer window identity within Overview and Bar,
  without continuous screenshot capture or extra background polling.
- Context Island transient feedback for device connections, screen sharing,
  transfer progress and nonintrusive resource warnings.
- Per-Scene refinements for live performance/audio/notification presets, without
  rewriting the user's normal preferences when a scene ends.
- Bounded, opt-in process CPU/RAM history in Task Manager, with explicit sample
  interval and memory cap; optional vendor GPU metrics behind capability checks.
- Better keyboard-first Launcher actions and cross-surface focus behavior.

## Release validation

The following require live evidence and remain **open** until tested:

- [ ] Fresh Arch installation and upgrade; Nix runtime packaging.
- [ ] Sustained shell performance and repeatable restarts.
- [ ] Horizontal/vertical Bar, Dock, Overview, overlays and focus.
- [ ] Mixed-DPI/multi-monitor and fullscreen/Gaming.
- [ ] NVIDIA and AMD/Intel rendering.
- [ ] Lock/PAM, optional fingerprint, Polkit, suspend and logout.
- [ ] Network, Bluetooth, audio, microphones and display changes.
- [ ] Wallpapers (including videos), notifications, thumbnails and MPRIS/lyrics.
- [ ] Recording, OCR/translation, clipboard, OSK and DropShelf.
- [ ] Update check/manual install/explicit automatic install and recovery.

Use [release validation](RELEASE-VALIDATION.md) for the exercise procedure.
