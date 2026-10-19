# Raohane SDDM

The canonical theme is `display-manager/sddm/raohane`. Both installer names
now use this source; the retired `login/sddm/raohane` copy must not return.

The three-column layout pairs clock/power cards with a centered circular avatar
and login form, and a session picker on the right.
Raohane supplies the graphite/lavender palette, keyboard-accessible controls,
masked password, pending/error states and reduced-motion option.

## Preview and install

Run as your normal desktop user:

```bash
bash scripts/install-login-theme.sh --preview
bash scripts/install-login-theme.sh
```

`scripts/install-sddm-theme.sh` remains an alias with the same options.
`--background /path/to/image.png` overrides automatic desktop wallpaper detection.
`--enable` explicitly enables SDDM; normal installation does not change services.

Installation selects Raohane in `/etc/sddm.conf.d/99-raohane-theme.conf` and
`/etc/sddm.conf` (backed up once to `/etc/sddm.conf.raohane.bak` if present).
It removes older Raohane drop-ins. The selected desktop wallpaper is copied
to `/var/cache/raohane-login/wallpaper`, readable before user login. Existing
shell wallpaper synchronization keeps this cache updated. Video wallpapers use
a still frame when ffmpeg is available. Preview uses a separate user cache.

Set `ReduceMotion=true` in the installed theme's `theme.conf.user` under
`[General]` to disable transitions. The greeter uses system fonts.

## Verification

`bash scripts/sddm-theme-audit.sh` checks install/authentication contracts.
`python3 scripts/test-sddm-theme.py` additionally exercises the actual QML with
mock SDDM models using PySide6 (test dependency only). This does not test PAM.

Before merging: test the Qt 6 SDDM greeter on the target machine, wrong/correct
passwords, account/session selection, keyboard focus and actual wallpaper.
SDDM is the pre-session login screen; it does not replace the shell lock screen.
Do not restart SDDM from an active desktop to preview a theme.


The installer copies the login owner's `~/.face.icon` when available; otherwise
a neutral avatar is used. `Avatar` in the theme configuration selects this image.
The decorative character has been removed. The remembered account is used for
authentication without displaying its name; when no account is remembered, it resolves the selected or first user from
SDDM’s user model. No username input or decorative text card is displayed.

### Visual refinement

The login area uses a single password capsule with an integrated arrow action,
a smaller circular avatar and no visible account label. Side cards share
one radius, subtle borders and consistent line icons. Translucency is static;
there are no blur passes or decorative background animation loops.

![Offscreen Qt preview](../../docs/previews/sddm-nocturne.png)

This preview is rendered from the actual QML with mock SDDM models and the
bundled fallback images; it is not a screenshot from a live SDDM/PAM session.
