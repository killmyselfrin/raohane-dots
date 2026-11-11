# Starter wallpapers, record card and appearance settings

Historical validation of the first increment. The final pack contains 60
bundled wallpapers and defaults to the Path forest photograph; see
`assets/wallpapers/README.md` and `BAR-WELCOME-PACK-VALIDATION.md`.

The offline pack in `assets/wallpapers` contains three original SVG landscapes,
licensed with the project: Nocturne, Cedar and Solstice. These are vector artwork,
not photographs. Empty wallpaper settings now render Nocturne; explicit user
paths and per-monitor choices retain precedence. With no user directory set,
the wallpaper gallery browses the bundled pack. The payload validator requires
all three files, and the staging audit exercises rejection of a missing fallback.

The Classic media widget now has circular album art with record grooves and a
real playback-progress rim, title/artist/player identity, seek and transport
controls. Its expanded layout uses the existing RaohaneLyrics service and lyric
viewport (including timestamp seeking), a refresh action and an Album view.
Small saved widget sizes keep the transport layout and omit the lyric section;
new free-layout defaults allocate 360 px. No fake waveform or second player is
introduced. The Canvas loads only current art, releases old images, and uses
existing playback updates rather than a continuous rotation/render timer.

Theme settings put the current wallpaper and starter choices first, then the
user folder, searchable compact palette cards and existing Style Studio sliders.
User preset save/import/export remain available further down the same scroll.

## Validation

- Parsed all changed QML with Qt6 qmlformat; qmldir audit passed.
- Theme library, source lineage and runtime payload audits passed.
- Payload staging rejected a missing Nocturne asset and passed after restoration.
- XML parsing verified the SVG assets and absence of external resources/scripts.
- At 1920×1080 on the virtual Wayland diagnostic output, the gallery displayed
  three items; changing to Cedar through the existing service persisted its path
  in native.json and remained selected after restarting Quickshell.
- The record image rendered with a circular clip and progress rim. Test MPRIS
  transport calls delivered Pause/Next/Previous to the test player.
- The lyric viewport was exercised with original synthetic lyric lines injected
  only into the installed diagnostic runtime, not product sources. The media
  screenshot is a test fixture, not proof of successful online lyric retrieval.
- Native runtime smoke still fails on the previously observed RaohanePrivacy
  undefined bindings under Quickshell 0.3.2/Qt6.11.2. No errors from the new
  Canvas, lyric viewport or Theme Catalog were observed.
- The umbrella audit retains its baseline desktop-widget Loader.source failure.
  Wallpaper Studio audit also retains its pre-existing exact-string assertion
  expecting `sourcePath === ...`; the baseline source uses a guarded `!==` path.
  Those unrelated checks were not weakened.

Real Hyprland focus/input, hardware rendering, high-DPI and playback/online
lyrics against a real player still require target-session validation. The
cloud screenshots use Sway/pixman with Qt software rendering.
