# Raohane release validation

Raohane's source/static standalone boundary is automated. The remaining release gates depend on a real Hyprland/Wayland/PAM/GPU session and therefore must not be marked complete from CI alone.

## 1. Install the current main checkout

```bash
git checkout main
git pull --ff-only
./install-raohane.sh --deps
hyprctl reload
raohane restart
```

## 2. Run the full live release validator

From the source checkout:

```bash
./scripts/release-live-check.sh --full
```

The validator:

- verifies that it is running in a real Wayland + Hyprland session;
- checks the installed standalone Raohane payload;
- records shell/service state;
- records graphics-controller and NVIDIA driver information when available;
- records the real Hyprland monitor graph;
- records active-window/fullscreen evidence;
- runs the existing Phase 4 full live validator;
- asks for explicit fresh-install, GPU/render, multi-monitor and fullscreen/game observations that static tooling cannot infer safely.

`--full` can enter the real WlSessionLock/PAM path and interactive screenshot/OCR/translation flows through `phase4-live-check.sh --full`. Unlock normally and complete the on-screen region selections when requested.

Reports are saved by default under:

```text
~/.local/state/raohane/reports/release-validation-YYYYMMDD-HHMMSS.txt
```

A custom report location can be supplied:

```bash
./scripts/release-live-check.sh --full --report ~/raohane-release-test.txt
```

## 3. Result semantics

The script returns:

- `0` — all gates exercised by the run passed;
- `1` — at least one hard gate failed;
- `3` — no hard failure, but one or more release gates remain unvalidated/unsupported in that run.

For example, a single-monitor machine should produce a `PARTIAL` result for the multi-monitor gate rather than pretending that multi-monitor behavior passed.

## 4. Hardware coverage

One machine cannot close every hardware checkbox. A release candidate should retain reports from at least:

- one NVIDIA Hyprland system;
- one AMD or Intel graphics system (preferably both when available);
- one system with at least two active monitors;
- one system where fullscreen/game overlay behavior is exercised in a real fullscreen application.

The current repository deliberately keeps those roadmap items open until that evidence exists.

## 5. Source package after live validation

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

Verify the checksum before publishing:

```bash
cd dist
sha256sum -c Raohane-<VERSION>.tar.gz.sha256
```

Do not turn `0.10.0-dev` into a final release version or publish a non-development release solely because static CI is green. The real-session/hardware reports are a separate release gate.
