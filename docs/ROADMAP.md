# Raohane roadmap

The current release target is `1.3.0`. The release-candidate branch is `release/v1.3`; completed implementation history is recorded in the [changelog](../CHANGELOG.md).

Raohane is in release-polish mode. New experimental feature scope is intentionally deferred until the 1.3 stable release is complete.

## Current priorities

- Finish the static whole-shell UX audit across Settings, Media & OSD, Scenes, Context Island, Bar/Dock, session surfaces and secondary overlays.
- Keep Settings search/navigation complete for every user-facing studio or control without reintroducing duplicate controls.
- Remove stale release/version/documentation references and keep installer, updater, runtime payload and release metadata consistent.
- Preserve the existing native-service boundaries: presentation QML must not grow ad-hoc shell/process control paths where Raohane services already own the behavior.
- Keep the repository clean and release-focused: no temporary migration files, generated implementation notes or obsolete UI variants in the active runtime.
- Hold `VERSION` at a release-candidate value until the final real-session validation pass is accepted.

## Static release gates

The release candidate must keep the normal validation graph green, including:

- Raohane audit and runtime/source ownership boundaries.
- Release/package boundary and version consistency.
- QML singleton/runtime-root guards.
- Localization audit.
- Graphics-driver safety boundary.
- Scenes boundary.
- Media Overlay / Context Island boundary.

Static validation establishes source and integration consistency, not real-session release readiness.

## Final runtime validation

Real Hyprland testing is deliberately the final stage after static polish is complete. These checks remain open until evidence is recorded:

- [ ] Fresh Arch/CachyOS installation and upgrade from an existing Raohane installation.
- [ ] Long-running shell stability, repeated startup/restart, and Settings persistence.
- [ ] Horizontal/vertical Bar, Dock, Overview and focus/input behavior.
- [ ] Multi-monitor placement and fullscreen/game overlays, including all Media positions and Gaming auto-hide.
- [ ] NVIDIA rendering and at least one AMD/Intel validation path.
- [ ] Password/PAM, optional fingerprint unlock, Polkit authentication and session actions.
- [ ] Networking, Bluetooth, audio, microphone and display controls.
- [ ] Wallpapers, thumbnails, notifications and desktop widgets.
- [ ] MPRIS controls, player switching, seek, lyric lookup/synchronization and lyrics-only presentation.
- [ ] Context Island priority/handoff behavior for media, Scenes, privacy and recording.
- [ ] Task Manager refresh and process actions on disposable processes.
- [ ] Screenshots, gameplay recording, OCR, translation, OSK and DropShelf.
- [ ] Suspend, hibernate, logout, reboot and poweroff.

Use `raohane validate release --full` and follow the [release validation guide](RELEASE-VALIDATION.md). Unsupported hardware or untested behavior must remain explicitly incomplete; static checks alone do not establish runtime correctness.

## After 1.3

Feature planning resumes only after the 1.3 stable release is closed. At that point, new ideas should be evaluated against three rules: they must add a clear user benefit, integrate through Raohane-owned services/configuration, and avoid duplicating an existing shell surface.

The next feature cycle will be planned separately rather than keeping speculative features in the 1.3 release checklist. We can then rank new ideas by impact, implementation cost and how strongly they reinforce Raohane's identity instead of simply increasing feature count.
