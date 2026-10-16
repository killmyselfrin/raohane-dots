# Raohane Welcome mascot

`welcome-mascot.svg` is used exclusively as a static illustration on the
Raohane Welcome screen. It is **not** a remote image, a background service,
or a runtime dependency.

- **Source file:** [Cute-girl.svg](https://github.com/cyanidecupcake/openclipart-svg/blob/e9da54c346f38ad9b67e43efb688beb783d106f8/svg/unsorted/Cute-girl.svg), archived from Openclipart.
- **Collection:** [Openclipart](https://openclipart.org/).
- **Licence:** [CC0 1.0 / public domain](https://openclipart.org/faq).
- **Provenance:** original SVG geometry is retained, without remote resource references. The Raohane layout, decoration and text are implemented separately in QML.

**Asset repair:** The source snapshot was already truncated inside its last SVG
path. The incomplete trailing path was discarded and the open SVG group/root
were closed. All complete drawing paths were retained. The CI now parses the
SVG as XML to prevent shipping malformed artwork again.

This provenance note is kept even though Openclipart does not require
attribution. Replace the asset with another appropriately licensed original
if the product mascot art direction changes.
