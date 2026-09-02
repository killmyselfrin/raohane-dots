# Raohane SDDM greeter

This theme is the pre-session companion to the Raohane lock screen. It uses SDDM's native `userModel`, `sessionModel` and authentication proxy, so every session installed in the system session directories is exposed by the session picker without hard-coding Hyprland, Niri or another compositor.

Install it from the repository root:

```bash
scripts/install-sddm-theme.sh
```

Install it and explicitly make SDDM the enabled display manager:

```bash
scripts/install-sddm-theme.sh --enable
```

Preview without changing the active theme when the SDDM greeter binary is available:

```bash
scripts/install-sddm-theme.sh --preview
```

The installer writes only `/usr/share/sddm/themes/raohane` and `/etc/sddm.conf.d/raohane-theme.conf`. `--enable` is intentionally separate because changing display managers is a system-level choice.
