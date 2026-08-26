# Raohane architecture

Raohane is a Hyprland + Quickshell shell built on the mature end4-pC / illogical-impulse technical foundation while product-facing surfaces are progressively rewritten as Raohane-native components.

## Ownership boundary

- `modules/raohane/` — Raohane-owned product UI and product-specific runtime state.
- `services/` — mature system/data integrations retained from the foundation until a verified replacement exists.
- `modules/common/` — shared configuration, appearance, models, widgets and utility infrastructure.
- `modules/ii/` — compatibility UI still used where Raohane has not reached feature parity.
- `panelFamilies/RaohaneFamily.qml` — composition boundary that decides which Raohane and compatibility surfaces are active.

The foundation synchronizer intentionally preserves `modules/raohane/` and `modules/common/Directories.qml`. Root `GlobalStates.qml`, services and most compatibility modules can be refreshed from upstream, so Raohane-only state must not be added to upstream-owned files.

## Active Raohane-native surfaces

- `RaohaneBar.qml` — active horizontal bar shell. It owns Raohane composition while reusing mature workspace, tray and system providers.
- `RaohaneContext.qml` — context state model backed by live MPRIS and active-window data plus transient Raohane events/privacy state.
- `RaohaneContextIsland.qml` — adaptive center surface used by the bar.
- `RaohaneLauncher.qml` — active launcher UI backed by the mature `LauncherSearch` provider.
- `RaohaneControlCenter.qml` — control-center shell over mature quick-toggle, notification, audio and system providers.
- `RaohaneSettings.qml` — Raohane settings shell currently hosting mature settings content during migration.
- `RaohaneMediaOverlay.qml` — floating media overlay for games/apps using the shared MPRIS controller.
- `RaohaneOsd.qml` — active volume, brightness and gamma OSD over mature Audio/Brightness/Hyprsunset providers.
- `RaohaneNotificationPopup.qml` — active notification popup over the mature notification server/history/actions backend.
- `RaohaneState.qml` — product-owned ephemeral state that must survive upstream foundation refreshes.

## Compatibility surfaces still active

The following remain foundation UI until a Raohane replacement reaches equivalent behavior:

- vertical bar
- workspace overview (launcher search itself already has a native Raohane surface)
- wallpaper/background and desktop widgets
- dock and lock screen
- capture/region selector, screen translator and recording overlay
- session/polkit, on-screen keyboard, left sidebar and supporting panels
- mature media controls remain loaded as a compatibility surface while the native game/media overlay is runtime-tested

Compatibility UI can consume the same services as Raohane UI. Replacing a visible surface does not require replacing its proven backend in the same change.

## Runtime

`shell.qml` is the root Quickshell configuration. Raohane's product runtime is Hyprland-only. It selects `RaohaneFamily` for the Raohane product and keeps `ii-upstream` as an explicit diagnostic fallback.

`GlobalStates.qml` remains foundation-owned cross-surface state. Raohane-only state lives in `modules/raohane/RaohaneState.qml` so an upstream foundation refresh cannot erase it.

Persistent settings are serialized into `~/.config/raohane/config.json` through the existing `Config.qml` `FileView`/`JsonAdapter` infrastructure. The configuration schema is still largely inherited; a dedicated Raohane configuration API is a migration target, not a completed boundary yet.

## Data flow

```text
Hyprland / Wayland / D-Bus / PipeWire / MPRIS
                    ↓
                 services/
                    ↓
       Config + foundation runtime state
                    ↓
          modules/common/ providers
                    ↓
     modules/raohane/ + compatibility UI
                    ↓
          panelFamilies/RaohaneFamily
                    ↓
                 shell.qml
```

Raohane-native components should consume mature services instead of reimplementing hardware/system discovery inside presentation files. Backends can then be replaced separately without redesigning the product UI again.

## Installation and dependencies

The installer writes an isolated `~/.config/hypr/raohane.conf`, exposes the `raohane` CLI and installs the `raohane.service` user service.

On Arch-based systems `./install-raohane.sh --deps` invokes the pinned illogical-impulse dependency bootstrap before installing the shell. GPU driver selection remains explicit and is not performed by that helper.

Useful diagnostics are exposed through `raohane doctor all`, `raohane doctor deps`, `raohane doctor services` and `raohane doctor graphics`.

## Runtime verification boundary

Static CI validates shell scripts, committed foundation structure, local QML module references, native-surface registration and the Raohane product boundary. It cannot prove compositor behavior.

A migration batch is not runtime-complete until tested in a real Hyprland + Quickshell session for:

- shell startup and restart behavior
- multi-monitor bar placement and input regions
- launcher keyboard focus/execution
- notification popup rendering/actions/timeouts
- volume/brightness/gamma OSD triggers
- media overlay behavior over fullscreen applications
- Settings and Control Center focus/dismiss behavior
- audio, network, Bluetooth, brightness and capture regressions

See `NOTICE-UPSTREAM.md` for retained backend provenance and licensing notes.
