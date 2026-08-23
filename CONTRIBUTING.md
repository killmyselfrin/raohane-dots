# Contributing to Raohane

Raohane targets Hyprland + Quickshell and keeps a strict boundary between product UI and compatibility/backend code.

Before submitting a change:

1. Keep new user-facing surfaces under `modules/raohane/`.
2. Avoid reintroducing alternate compositor or shell-family UI into primary runtime.
3. Preserve GPL-3.0 notices for retained derivative code.
4. Run `./scripts/raohane-audit.sh`.
5. Test the shell under a real Hyprland + Quickshell session and include the first relevant runtime log on failure.
