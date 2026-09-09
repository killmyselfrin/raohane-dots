# Raohane changelog

## 1.3.0-dev — Media experience

- Start the 1.3 feature cycle from stable 1.2.1 with a dedicated media/player redesign instead of extending the old stacked-card composition.
- Rebuild the default media overlay as a wide split now-playing deck: full-height artwork on the left and a dedicated information/control plane on the right.
- Make artwork part of the window geometry instead of nesting it inside another card, with artwork-derived accent used for status and reading emphasis.
- Promote title, artist and album into a clearer hierarchy and remove most tiny metadata from the primary player view.
- Integrate progress, transport, optional MPRIS volume and native Raise Player action into the information deck while preserving previous/play-next/seek semantics.
- Keep multi-player MPRIS cycling available without turning player selection into a separate surface.
- Rebuild Lyrics as a second mode of the same outer media surface: compact now-playing strip, clean lyric viewport and integrated footer transport instead of nested lyrics/transport cards.
- Remove lyric-line scale animation and animated color/style/opacity Behaviors so synced text remains a stable reading target; only the ListView position may move to recenter the current line.
- Preserve lyrics-only mode with high-contrast light text and a dark halo over arbitrary Wayland application content, plus artwork-derived active-line accent.
- Preserve click-to-seek, LRCLIB resolution and native `RaohaneMedia` MPRIS ownership without adding `playerctl` or presentation-layer shell processes.
- Add a dedicated Media Overlay boundary workflow protecting split-deck geometry, native MPRIS routing and stable lyric typography.

## 1.2.1 — Lyrics flow hotfix

- Fix lyrics-only rendering for plain LRCLIB lyrics so non-synced text stays readable instead of inheriting the distant-line fade intended for synced lyrics.
- Keep lyric delegates at a stable width and animate the inner text instead, preventing active synced lines from being clipped at the left or right edge.
- Use high-contrast light lyric text with a dark outline over arbitrary application content while retaining artwork-derived accent on the active synced line.
- Add top and bottom breathing room so the first and last timed lines can move into the same centered reading position as the rest of the song.
- Rework synced lyrics into a clearer karaoke stack with animated active-line scale, neighboring-line fade and smooth recentering while preserving click-to-seek behavior.

## 1.2.0 — Contextual shell

- Add the native `RaohaneScenes` subsystem with Balanced, Gaming, Focus and Work scenes persisted as runtime state outside the user's base configuration.
- Keep selected and effective scenes separate so automatic context switching can return to the user's chosen mode without overwriting persistent settings.
- Apply reversible runtime policies with baseline restoration for DND, Keep Awake and Game Mode instead of mutating `RaohaneConfig`.
- Add event-driven application scene switching from the active Wayland `appId`, with conservative Steam/gamescope defaults, manual-override behavior and up to 64 custom rules.
- Support explicit exact, prefix and contains application rules; user rules take precedence over built-ins and exact Balanced rules can be used as exclusions from broader matches.
- Add a Scene rail to runtime Quick Controls / Control Center with direct mode selection plus AUTO/MANUAL switching state.
- Add Settings → Scenes with active/selected state, automatic switching, current `appId`, protected built-in rules and an explicit exact/prefix/contains rule editor.
- Add a per-Scene Behavior Editor for Gaming, Focus and Work with persisted runtime-only DND, Keep Awake, Game Mode, Dock and motion-cadence overrides while keeping Balanced as the baseline restore mode.
- Add Launcher 2.0 scene commands and contextual `/ assign`, `/ auto`, `/ rule` and `/ scene` management without embedding shell commands in the Launcher backend.
- Replace Gaming Scene idle Quick Access with six live native actions: Microphone, Audio Output, Record Gameplay, Game Mode, DND and Media.
- Add native PipeWire output cycling through `RaohaneAudio` so Launcher can switch devices without directly invoking `wpctl`.
- Add the native `RaohaneRecorder` service over the validated recording script with fullscreen/region capture, audio, clean stop, external-session detection, elapsed time and IPC status.
- Evolve Context Island 2.0 with persistent gameplay recording, elapsed time, direct Stop control, scene-aware activity, and manual/automatic rule-reason feedback while preserving recording/privacy/media priority.
- Apply Scene `dockPolicy` as a temporary runtime overlay so Gaming/Focus can hide Dock and release its exclusive zone without rewriting dock preferences; hover/forced-open reveal remains available.
- Apply Scene `motionHint` as a temporary cadence overlay over the user's Style Studio motion scale: Gaming fast motion uses 0.72× duration, Focus quiet motion 0.82×, and Balanced/Work remain at 1.0×.
- Keep Game Mode responsible for expensive transform suppression and preserve the user's reduced-motion threshold independently of Scene cadence.
- Expose active scene, matched rule, effective policy and recorder state through runtime diagnostics.
- Require Scenes, Recorder and Settings Scenes in the validated runtime payload and expand the dedicated Scenes boundary workflow across persistence, rules, native actions, Context Island, Dock and Motion integration.
- Update fullscreen validation so Scene-aware Dock hiding preserves the independent fullscreen reveal, input and exclusive-zone boundary.
- Keep the stable updater on the official `main` channel; once 1.2 lands in `main`, existing stable installations detect it through the normal Check / Update now flow.

## 1.1.0 — Whole-shell polish

- Start the post-1.0 polish cycle while keeping the stable registry/router/config architecture intact.
- Increase Settings workspace breathing room and rebalance the global search/command chrome.
- Improve Settings navigation, page headers and profile affordances with more readable typography and spacing.
- Increase control-row hit areas and text hierarchy for toggles, numeric controls, choices and text inputs.
- Add explicit section scroll feedback and wider content geometry for long Settings pages.
- Rebalance Theme Library, user preset management, Style Studio, accent controls and Advanced Surfaces around the 1.1 Settings scale without changing theme/config semantics.
- Rework Widget Studio and its primary/secondary rail editor with a larger live preview, clearer composition controls and consistent scroll feedback.
- Bring Sakura ambience controls in Appearance onto the same typography, spacing and choice-button scale as the rest of Settings.
- Rebalance Bar & Dock Studio, horizontal/vertical layout editing and Settings-only bar/dock previews without changing runtime Bar or Dock geometry.
- Rebalance Quick Controls Studio preview, active/available tile lists, reorder actions and slider previews while preserving the quick-control layout model.
- Rework Displays presentation with a larger monitor canvas, clearer cards and safer Apply/Keep/Revert hierarchy while preserving monitor IPC and the timed rollback path.
- Rebalance Graphics & Drivers around larger hardware/status/update cards without changing Polkit, package filtering or driver-family safety.