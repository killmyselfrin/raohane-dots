# Raohane wallpaper collections

The main collection is 20 anime images, 20 nature landscapes and 20 abstract
wallpapers. Nature contains 20 photographs, including forests, mountains, coasts and lakes.

- `nature/`: 9 unmodified KDE photographs and 11 masterbutler photographs from Linux Mint Maya, with original credits and licenses.
- `abstract/`: 12 unmodified KDE artworks and 8 original Raohane SVG compositions.
- Online anime: 20 mixed character/scenery images curated from
  `orangci/walls-catppuccin-mocha`. `online-anime.json` pins the original URLs and
  SHA-256 hashes. They are downloaded into a user's own collection, not bundled
  or relicensed as Raohane source. The collector does not supply individual
  artist licenses; original artwork rights remain with their creators.
- `anime/`: 20 additional original vector illustrations for an offline fallback,
  mixing original characters and scenery. These are not the downloaded anime set.
- The three SVG files at the root are the earlier starter backgrounds. Empty
  wallpaper settings now fall back to the bundled forest photograph Path; saved
  paths are preserved. The gallery defaults to the Nature collection.

To import the internet anime set into an existing installation:

```bash
python3 scripts/import-anime-wallpapers.py \
  --output "$HOME/.local/share/raohane/wallpapers/anime" \
  --register-config "$HOME/.config/raohane/native.json"
```

The config argument is optional and requires an existing config. Registration
adds a named collection, preserving other preferences. Existing files with
unexpected hashes are never overwritten. Downloads use TLS, pinned hashes,
image decoding and a minimum Full HD size check. Theme settings' Anime category
uses the registered collection when present, otherwise the offline illustrations.

Per-file provenance for the bundled artwork is in `catalog.json`; original KDE
license texts are under `licenses/`. KDE images retain CC-BY-SA-4.0, CC-BY-2.0 or LGPLv3
as declared per file. Original Raohane vectors use GPL-3.0-or-later. They contain
no external resources, fonts, scripts or third-party franchise characters.
`sources/generate-originals.py` reproduces the original vector collection.

Verify the bundled pack with `python3 scripts/wallpaper-pack-audit.py`.
