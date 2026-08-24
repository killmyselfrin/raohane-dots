# Raohane system/dependency upstream

The imported `pctrade/end4-pC` Quickshell tree is not a complete standalone operating environment. Upstream explicitly expects `end-4/dots-hyprland` / illogical-impulse to already be installed and running.

Raohane therefore pins the system/dependency upstream separately.

## Pinned system baseline

- Repository: `https://github.com/end-4/dots-hyprland`
- Pinned commit: `42d0aae17b744a38cd05c9044c189bfc9b13869a`
- Commit timestamp: `2026-08-15T03:34:42Z`
- Commit subject: `feat(install): add dinit init system support (#3584)`
- License: GPL-3.0

## What is retained for migration

A source snapshot is vendored under `upstream/illogical-impulse-system/` for controlled migration of the system layer. It includes the upstream setup/diagnose tooling, package/install data, licenses, and dotfile/system configuration sources needed to understand dependencies and runtime integration.

This vendored source is a migration/reference foundation. Raohane will progressively adapt it into Raohane-owned installer, doctor, Hyprland integration and package profiles rather than running blind search/replace over upstream files.

## Rules

- Keep exact upstream SHA recorded.
- Preserve upstream licenses and notices.
- Do not bundle font binaries; represent fonts as packages/dependencies instead.
- Do not silently install/replace GPU drivers.
- Do not overwrite a user's main Hyprland configuration destructively.
- Do not shrink dependency coverage merely to make the manifest shorter.
