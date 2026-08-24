# Raohane

Raohane is a Hyprland + Quickshell desktop shell.

## Foundation strategy

Raohane now uses `pctrade/end4-pC` as the technical foundation rather than only as a visual/architectural reference.

Upstream chain:

- `pctrade/end4-pC`
- `end-4/dots-hyprland` / illogical-impulse

The goal is to retain the mature system coverage, integrations, package/dependency model, services, settings infrastructure, widgets, notifications, OSD, media stack, and shell completeness of that foundation while progressively transforming the product into Raohane.

Do not perform a shallow copy-and-rebrand. Preserve functionality first, then migrate identity and UX in controlled phases.

## Licensing and attribution

- Preserve GNU GPLv3 licensing for covered derivative work.
- Keep upstream copyright/license notices intact where required.
- Maintain a clear `NOTICE-UPSTREAM.md` / credits section documenting end4-pC and illogical-impulse origins.
- Mark Raohane-modified files/releases as modified where appropriate.
- Do not remove third-party notices for assets, shaders, integrations, or copied components.

## Architecture

- Hyprland only for the Raohane product target.
- Quickshell/QML UI.
- end4-pC/illogical-impulse backend and UI modules may be retained during migration when they provide working functionality.
- New or rewritten Raohane-native surfaces should live under `modules/raohane/` where practical.
- Do not introduce new Niri-specific product work.
- Migrate old naming/config namespaces incrementally instead of deleting working subsystems prematurely.
- Preserve working package/service integrations until a Raohane-native replacement is verified at runtime.

## Design direction

Raohane visual identity:

- Japanese minimalism
- dark translucent glass
- floating surfaces/islands
- purple / magenta accents
- wallpaper/media-aware accents where useful
- Context Island as a signature surface
- smooth organic motion
- dense but readable information hierarchy

end4-pC may now be reused as source foundation under GPLv3, but the final user-facing design should become recognizably Raohane rather than a simple renamed clone.

## Migration priorities

1. Import/synchronize the full end4-pC foundation and verify it launches unchanged.
2. Bring over the full upstream dependency/install coverage required by the imported features.
3. Preserve and verify Settings, bar, launcher, notifications, OSD, media, network, Bluetooth, audio, portals, power, capture, widgets, and supporting services.
4. Integrate Raohane hardware/bootstrap improvements: GPU detection, driver planning, display/refresh-rate management, doctor diagnostics.
5. Introduce Raohane design tokens and branding without breaking existing functionality.
6. Rebuild primary surfaces progressively: Bar + Context Island, Control Center, Settings, Launcher/Overview, Notifications/OSD.
7. Remove obsolete upstream identity/config paths only after their Raohane replacements work in a real Hyprland session.

## Runtime rule

A migration task is not complete only because QML parses or static checks pass.

For UI/runtime changes verify when possible:

- `qs -c raohane` starts
- Settings opens
- launcher opens
- control/system surfaces open
- notifications/OSD still work
- media works
- network/Bluetooth/audio backends still work
- no critical QML runtime errors
- no duplicate Quickshell instances or conflicting services

If the implementation environment cannot run Hyprland/Quickshell, state that explicitly in the PR and provide exact target-session tests.

## Package/dependency rule

Do not reduce the imported upstream package model to a small hand-written list. Audit all retained features and preserve their runtime/build dependencies. Group dependencies by subsystem and distinguish required, optional, AUR/manual, hardware-specific, and service requirements.

GPU driver mutation must remain explicit and architecture-aware; never silently replace a working GPU driver.

## Before finishing

Run:

./scripts/raohane-audit.sh

Also run `bash -n` on touched shell scripts and validate `qmldir`/local QML imports.

Do not bundle font files in Raohane archives. Fonts may be installed as distribution packages.
