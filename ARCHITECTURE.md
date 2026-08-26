# Raohane architecture

Raohane is a Hyprland + Quickshell shell built on the mature end4-pC / illogical-impulse technical foundation while product-facing surfaces are progressively rewritten as Raohane-native components.

## Ownership boundary

- `modules/raohane/` — Raohane-owned product UI and product-specific runtime state.
- `services/` — mature system/data integrations retained from the foundation until a verified replacement exists.
- `modules/common/` — shared configuration, appearance, models, widgets and utility infrastructure.
- `modules/ii/` — compatibility UI still used where Raohane has not reached feature parity.
- `panelFamilies/RaohaneFamily.qml` — composition boundary that decides which Raohane and compatibility surfaces are active.

The foundation synchronizer intentionally preserves `modules/raohane/` and `modules/common/Directories.qml`. Root `GlobalStates.qml`, services and most compatibility modules can be refreshed from upstream, so Raohane-only state must not be added to upstream-owned files.

## Primary surfaces

### Raohane-native

- `RaohaneContext.qml` — context state model backed by live MPRIS and active-window data plus transient Raohane events/privacy state.
- `RaohaneContextIsland.qml` — adaptive context presentation.
- `RaohaneControlCenter.qml` — Raohane control-center shell over mature quick-toggle, notification, audio and system providers.
- `RaohaneSettings.qml` — Raohane settings shell currently hosting the mature settings content.
- `RaohaneMediaOverlay.qml` — floating media overlay for games/apps using the shared MPRIS controller.
- `RaohaneBar.qml` — experimental Raohane bar implementation; not yet the production bar because it does not have full feature parity.

### Compatibility surfaces still active

- production bar / vertical bar
- launcher / overview and search
- notifications popup and OSD
- wallpaper/background system
- dock, lock screen, capture/region selector, session/polkit and supporting panels

These stay active until a Raohane-native replacement reaches runtime feature parity.

## Runtime

`shell.qml` is the root Quickshell configuration. It selects `RaohaneFamily` for the Raohane product and keeps `ii-upstream` as an explicit diagnostic fallback.

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

## Integration

The product target is Hyprland. The installer writes an isolated `~/.config/hypr/raohane.conf`, exposes the `raohane` CLI and installs the `raohane.service` user service.

Current primary shortcuts installed by Raohane include launcher, settings, control center and `SUPER + SHIFT + M` for the Raohane media overlay.

See `NOTICE-UPSTREAM.md` for retained backend provenance and licensing notes.
