# Theme payload compatibility

Raohane built-in themes are owned by `modules/raohane/RaohaneTheme.qml`.

This directory is intentionally kept as a compatibility bridge for early 1.1.x updater builds that required `defaults/themes` to exist in the source archive before they could install a newer runtime. It does not contain a second theme catalog and must not become a parallel source of theme definitions.

The directory may be removed only after the supported updater floor no longer validates the legacy `defaults/themes` path.
