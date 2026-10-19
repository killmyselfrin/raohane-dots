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

## Nocturne greeter (development)

The theme now uses Raohane's graphite/lavender glass palette, a locally bundled
mascot illustration, a gentle entrance transition and a fade on successful
authentication. The existing native SDDM username, password, session selector,
error handling, and power actions remain in place.

To show a selected desktop wallpaper on the login screen, reinstall the theme
with a readable image path:

```bash
scripts/install-sddm-theme.sh --background "$HOME/Pictures/wallpaper.png"
```

This **copies** the image into the system theme directory, because SDDM runs
before the desktop session and cannot reliably read files inside a user's home.
Whenever wallpaper changes, rerun the command to resync it. Without the option,
the theme uses its bundled background. For testing:

```bash
scripts/install-sddm-theme.sh --preview
```

**SDDM is a login greeter, not a session lock screen.** The same motion style can
be shared with Raohane's in-session lock surface, but unlock animation and
session-lock security require a separate implementation. Do not test greeter
changes by forcibly restarting SDDM from an active graphical session.
