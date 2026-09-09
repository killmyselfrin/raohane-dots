# Raohane release validation

Raohane's standalone source/runtime boundary is automated, but a stable release still depends on evidence from a **real Hyprland / Wayland / PAM / GPU session**. Static CI must never be presented as proof that compositor, hardware or authentication behavior works on a real machine.

The current candidate is `1.3.0-rc1` on `release/v1.3`. Live validation is the **final stage** after static release polish is complete.

## 1. Install the exact release candidate

Do not validate 1.3 from `main` while the release candidate is still isolated on its release branch.

From an existing checkout:

```bash
git fetch origin
git switch release/v1.3
git pull --ff-only
./install-raohane.sh --deps
hyprctl reload
raohane restart
```

Confirm the candidate before collecting evidence:

```bash
cat VERSION
raohane status
```

`VERSION` must match the candidate being validated.

For runtime debugging, stop the user service and run Quickshell in the foreground:

```bash
raohane stop
raohane run
```

## 2. Run the full validator

Use the installed CLI:

```bash
raohane validate release --full
```

From a source checkout the same validator can be invoked directly:

```bash
./scripts/release-live-check.sh --full
```

The release validator combines installed-runtime integrity, current-product probes and interactive gates.

### Installed-runtime integrity

It verifies that the installed payload contains the current standalone Raohane product, including:

- the native Raohane module/service graph;
- Bar/Dock, Settings, Scenes and Context Island surfaces;
- native Task Manager + process service;
- native MPRIS + Lyrics service and `lyrics-resolve.py`;
- Media Overlay and its current configuration boundary;
- product/release live validators;
- strict runtime-payload validation after pruning.

### Current product live probe

`product-live-check.sh` performs non-destructive checks against the running shell. It reads the runtime probe, exercises supported IPC routes and records whether live product state can be observed without inventing a pass when evidence is unavailable.

A missing active MPRIS player, unavailable hardware path or legitimate lyrics `not-found` result is **incomplete evidence**, not a successful validation of that feature.

The safe non-interactive release probe remains:

```bash
raohane validate release
```

### Interactive release gates

`--full` additionally runs the interactive release path, including Phase 4 checks where supported. Some gates require real user interaction and may enter secure/session surfaces. Follow the prompts on screen and unlock/cancel normally.

The final pass must verify the parts scripts cannot judge reliably:

- visible rendering and animation stability;
- multi-monitor placement/focus where multiple outputs are available;
- fullscreen/game behavior for Bar, Dock, Media Overlay and Context Island;
- all four normal/Gaming Media positions and Gaming auto-hide;
- authentication/session behavior;
- correct MPRIS/lyrics behavior with real players.

## 3. Useful validation modes

Safe environment + current product probe:

```bash
raohane validate release
```

Safe product probe plus Phase 4 runtime probe:

```bash
raohane validate release --phase4
```

Complete interactive release run:

```bash
raohane validate release --full
```

Raw current-product probe only:

```bash
~/.config/quickshell/raohane/scripts/product-live-check.sh
```

## 4. Reports and result codes

Reports are saved by default under:

```text
~/.local/state/raohane/reports/release-validation-YYYYMMDD-HHMMSS.txt
```

A custom report path can be supplied:

```bash
raohane validate release --full --report ~/raohane-release-test.txt
```

Result codes:

- `0` — every gate exercised by that run passed;
- `1` — at least one hard gate failed;
- `3` — no hard failure, but at least one required live gate remains unsupported/unvalidated.

For example, a single-monitor machine must produce a partial multi-monitor result instead of claiming multi-monitor validation.

## 5. Recommended final manual pass

After the automated sequence, verify the normal product flow once on the same installed candidate:

1. Horizontal and vertical Bar, Context Island, Super reveal and fullscreen behavior.
2. Dock pinned/running apps, focus cycling, pin/unpin and auto-hide.
3. Spaces / Overview workspace and individual-window activation.
4. Launcher search plus `/`, `>`, `=` and `:` modes.
5. Control Center: Wi-Fi, Bluetooth, audio, microphone, brightness/night light, notifications and Scenes.
6. Settings: global search, Theme/Widget/Bar/Quick Control studios, Media Position Studio and several persisted controls.
7. Scene manual/automatic switching and application-rule behavior.
8. Wallpaper image/video preview, apply and random/slideshow behavior.
9. Notification popup/history/actions and OSD feedback.
10. Media Overlay with desktop and Gaming policies, seek, player switching, volume where supported and auto-hide.
11. Lyrics with a known LRCLIB-supported track; verify plain, synced and lyrics-only presentation.
12. Context Island priority/handoff for media, recording, privacy and Scene feedback.
13. Native Task Manager search/sort/process details; test graceful End only on a disposable process.
14. Screenshot, gameplay recording, OCR and translation.
15. OSK and DropShelf.
16. Lock/password, fingerprint if configured, and Polkit authentication.
17. Suspend, hibernate, logout, reboot and poweroff.

## 6. Hardware coverage

One machine cannot close every release checkbox. A release candidate should eventually retain evidence from at least:

- one NVIDIA Hyprland system;
- one AMD or Intel graphics system (preferably both over time);
- one system with at least two active monitors;
- one real fullscreen/game workload;
- one system capable of exercising password/PAM lock;
- fingerprint hardware when fingerprint support is advertised as validated.

Unsupported hardware remains **partial**, never silently passed.

## 7. Promote the candidate only after live validation

After the required live gates pass and the release branch is clean:

```bash
./scripts/source-lineage-audit.sh
./scripts/runtime-payload-audit.sh
./scripts/package-release.sh
```

The packager emits:

```text
dist/Raohane-<VERSION>.tar.gz
dist/Raohane-<VERSION>.tar.gz.sha256
```

Verify it before publishing:

```bash
cd dist
sha256sum -c Raohane-<VERSION>.tar.gz.sha256
```

Only after runtime acceptance should `VERSION` move from `1.3.0-rc1` to `1.3.0`, the changelog heading be promoted to stable, and the release candidate be merged/published. Static CI proves source, integration and release-boundary consistency; it cannot substitute for compositor, PAM, GPU, monitor or fullscreen evidence.
