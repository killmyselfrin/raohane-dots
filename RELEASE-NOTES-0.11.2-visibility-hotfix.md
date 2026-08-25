# Raohane 0.11.2 Visibility Hotfix

This hotfix addresses a real first-run failure observed on a clean standalone Raohane installation: Quickshell reported `Configuration Loaded`, but no visible shell surfaces appeared.

## Root cause

The upstream configuration loader assumed a pre-existing illogical-impulse config file. On a clean Raohane install, `~/.config/raohane/config.json` does not exist yet. `Config.qml` wrote the default adapter to disk on `FileNotFound`, but it did not set `Config.ready = true` during that first process lifetime.

The active panel family is lazy-loaded behind `Config.ready`, so the first process could remain alive with zero visible panels until a second launch.

## Fixes

- Mark Config defaults ready immediately when creating a first-run config file.
- Mark Persistent defaults ready immediately when creating first-run state.
- Make `raohane` the canonical panel family identifier.
- Keep `ii` as a temporary compatibility alias so configs written by 0.11.0/0.11.1 continue to display the shell.
- Add runtime log lines for Config readiness and panel-family activation.
- Preserve the 0.11.1 runtime namespace fixes for generated theme, translation overlay, wallpaper/color scripts and persistent state.

## Expected first-run log

A successful visible startup should include lines similar to:

```text
[Raohane] Config ready; panel family: raohane
[Raohane] Loading panel family: raohane
```

A migrated 0.11.1 config may instead report `panel family: ii`; this remains supported by the compatibility alias.

## Safety

- No GPU driver changes.
- No overwrite of the main Hyprland config.
- Existing Raohane runtime is backed up by the installer before replacement.
- No bundled font binaries.
