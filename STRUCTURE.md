# Raohane source structure

```text
shell.qml                         root Quickshell entry
GlobalStates.qml                  cross-surface runtime state
modules/raohane/                  Raohane-native product UI
modules/common/                   shared UI/config helpers
services/                         system integration services
scripts/raohane                   user CLI
scripts/raohane-audit.sh          static release audit
install-raohane.sh                Hyprland installer/update path
defaults/                         default configuration
assets/                           runtime assets
```

The migration rule is simple: new product-facing UI belongs in `modules/raohane/`. Compatibility providers may remain elsewhere only until their replacement is stable.
