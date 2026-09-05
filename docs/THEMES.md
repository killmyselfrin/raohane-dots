# Raohane theme format

Raohane themes are data-only JSON palettes. They do not load QML, shell code, commands, services, or runtime files from another desktop shell.

The Settings **Themes** page can save the current effective palette as a user preset, import a JSON theme, export the selected theme, and remove user-owned presets. User presets are stored in:

```text
~/.config/raohane/themes.json
```

The file is watched by `RaohaneThemeLibrary`, so valid catalog changes are picked up without maintaining a second theme database.

## Single-theme file

A portable exported theme is one JSON object:

```json
{
  "id": "user-nocturne-blue",
  "name": "Nocturne Blue",
  "description": "My Raohane palette",
  "tone": "Custom · Dark",
  "dark": true,
  "source": "user",
  "background": "#080a14",
  "backgroundElevated": "#0d1020",
  "surface": "#dc111524",
  "surfaceRaised": "#ef171c2e",
  "surfaceDeep": "#f3070912",
  "surfaceSubtle": "#921c2237",
  "surfaceHover": "#e9232a44",
  "surfacePressed": "#ef2c3553",
  "border": "#3a59627f",
  "borderStrong": "#6a7b86aa",
  "borderFaint": "#2059627f",
  "highlight": "#40ffffff",
  "text": "#f2f1fa",
  "textMuted": "#aaa9bd",
  "textFaint": "#73758c",
  "accent": "#aa91ff",
  "accentSecondary": "#8b7bd8",
  "accentBlue": "#899dff",
  "success": "#7fd7aa",
  "warning": "#d7b26e",
  "critical": "#e5889a",
  "info": "#8eb8ff"
}
```

`id` is normalized to a lowercase slug. `name` is required for a useful UI label. `description`, `tone`, `dark`, and `source` are metadata. Every color token must be a six- or eight-digit hexadecimal color. Eight-digit colors use the same alpha-first representation already used by Raohane's bundled catalogs, for example `#dc111524`.

The required native color tokens are:

```text
background
backgroundElevated
surface
surfaceRaised
surfaceDeep
surfaceSubtle
surfaceHover
surfacePressed
border
borderStrong
borderFaint
highlight
text
textMuted
textFaint
accent
accentSecondary
accentBlue
success
warning
critical
info
```

Theme presets intentionally contain colors only. Geometry, density, motion, Dock sizing, notification density, and other Style Studio values remain in `~/.config/raohane/native.json` and are not silently bundled into a color theme.

## Catalog file

Raohane also accepts a catalog wrapper when importing:

```json
{
  "schemaVersion": 1,
  "presets": [
    { "id": "example-a", "name": "Example A", "...": "..." },
    { "id": "example-b", "name": "Example B", "...": "..." }
  ]
}
```

Each entry is validated with the same native token rules as a single-theme file. Imported presets are merged by `id`; importing the same `id` again updates that user preset atomically.

## CLI

The Settings UI and CLI share `scripts/theme-catalog.py`, so they use the same validation and atomic catalog writes.

```bash
raohane theme list
raohane theme import ~/Downloads/nocturne-blue.json
raohane theme import-serpantinum /path/to/serpantinum/themes
raohane theme export user-nocturne-blue ~/Downloads/nocturne-blue.json
raohane theme remove user-nocturne-blue
```

The UI additionally uses internal `upsert-json` and `export-json` tool commands to pass an already materialized native palette to the same backend. Those commands do not bypass validation.

## Serpantinum palettes

`theme-catalog.py` can convert Serpantinum palette JSON into Raohane's native color-token schema. Only palette data is adopted. Serpantinum runtime QML, services, shell code, and configuration ownership are never loaded by Raohane.
