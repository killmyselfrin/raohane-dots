# Raohane release validation

Raohane's standalone source/runtime boundary is automated. A stable release still depends on evidence from a **real Hyprland / Wayland / PAM / GPU session**, so those gates must never be marked complete from CI alone.

## 1. Install the release candidate

From an existing checkout:

```bash
git checkout main
git pull --ff-only
./install-raohane.sh --deps
hyprctl reload
raohane restart
```

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

The release validator now runs three layers.

### Installed-runtime integrity

It verifies that the installed payload contains the current standalone product, including:

- `RaohaneFamily` and the native module graph;
- native Task Manager + process service;
- Command Deck / Overlay;
- native MPRIS + Lyrics service;
- `lyrics-resolve.py`;
- product, Phase 4 and release live validators;
- strict runtime-payload validation after pruning.

### Current product live probe

`product-live-check.sh` performs non-destructive runtime checks against the running shell:

- reads the live `RaohaneRuntimeProbe` snapshot;
- opens the native Task Manager through IPC;
- waits for a real current-user process snapshot;
- closes Task Manager and confirms coordinator state returns to closed;
- opens/closes the fullscreen Command Deck through IPC;
- inspects current MPRIS/Lyrics runtime state;
- treats resolver/network/timeout failures as hard product failures when an active player is available;
- treats a legitimate `not-found` lyrics result or lack of an active MPRIS player as incomplete evidence rather than inventing a pass.

The same product probe is also run by the default non-interactive release validator:

```bash
raohane validate release
```

### Phase 4 + interactive release gates

`--full` additionally runs:

```bash
phase4-live-check.sh --full
```

That sequence exercises the real vertical Bar, Lock/PAM path, screenshot/capture flow and screen translation path. It can enter `WlSessionLock`; unlock normally. Capture/translation checks use real region selection and must be completed on screen.

The release validator then asks for human confirmation of the parts that cannot be judged reliably from scripts:

- clean/fresh installation context;
- visible graphics/render stability;
- native Task Manager presentation and safe End/Force-stop UX;
- correct lyrics for a known LRCLIB-supported track, including synchronization when synced LRC is available;
- multi-monitor placement/focus when at least two outputs are present;
- fullscreen/game behavior for Bar/Dock, Command Deck and Media Overlay.

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

## 5. Recommended manual pass

After the automated sequence, verify the normal product flow once on the same installed build:

1. Bar and Context Island in normal applications.
2. Vertical Bar mode and Super reveal.
3. Dock pinned/running apps, focus cycling, middle-click, pin/unpin and autohide.
4. Spaces / Overview workspace and individual-window activation.
5. Launcher app search plus `/`, `>`, `=` and `:` modes.
6. Control Center: Wi-Fi, Bluetooth, audio, microphone, brightness/night light and notifications.
7. Settings: Theme Library, global search and several live-persisted controls.
8. Wallpaper image/video preview, apply and random/slideshow behavior.
9. Notification popup, history and actions.
10. OSD for audio/display changes.
11. Media controls with at least one native MPRIS player and one browser MPRIS source.
12. Lyrics with a known supported track; confirm the correct artist/title is selected and synced lines follow playback.
13. Native Task Manager search/sort/process details; test graceful End on a disposable process.
14. Command Deck in a normal workspace and in a real fullscreen application.
15. Screenshot/OCR/translation/recording.
16. OSK and DropShelf.
17. Lock/password, fingerprint if configured, and Polkit authentication.
18. Session actions/warnings.

## 6. Hardware coverage

One machine cannot close every release checkbox. A release candidate should retain reports from at least:

- one NVIDIA Hyprland system;
- one AMD or Intel graphics system (preferably both over time);
- one system with at least two active monitors;
- one real fullscreen/game workload;
- one system capable of exercising password/PAM lock;
- fingerprint hardware when fingerprint support is advertised as validated.

Unsupported hardware should remain marked **partial**, not silently treated as passed.

## 7. Source package after live validation

After the relevant live gates pass and the release commit is clean:

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

`0.10.0-dev` must remain a development version until the required real-session reports are collected. Static CI proves source/integration/release boundaries; it cannot substitute for compositor, PAM, GPU, monitor or fullscreen evidence.
