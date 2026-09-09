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
- Bring Keyboard & Motion, Backup & Restore, Language and About onto the same 1.1 visual scale while preserving keybind, restore, locale and updater behavior.
- Complete a Control Center polish pass across the panel shell, runtime Quick Controls, device picker, notifications and notification cards without reintroducing duplicate audio or microphone controls.
- Rebalance Launcher search, mode chips, pinned applications, quick actions and result rows while preserving ranking, mode prefixes and execution semantics.
- Scale Wallpaper Selector navigation, gallery metadata and footer controls without changing preview, apply, random, directory or video behavior.
- Rework Overview / Spaces presentation across workspace cards and window rows while preserving O(1) workspace lookup, Hyprland dispatch and direct Wayland activation.
- Rebalance Media Overlay, lyrics presentation and transport controls while keeping MPRIS, seek, synced lyrics and lyrics-only rendering intact.
- Refine the native OSD without changing Context Island suppression or brightness/gamma/audio event routing.
- Rework Session Screen presentation while retaining the 10-second destructive-action confirmation and package/download warnings.
- Validate Lock Surface, Context Island, OSK, Task Manager, runtime Bar and Dock as already compatible with the 1.1 scale instead of creating cosmetic rewrites around security or density-sensitive behavior.
- Rebalance DropShelf panel/item geometry while preserving URI drag-and-drop, MIME payloads and open/reveal/copy/remove behavior.
- Rebalance the Polkit authentication dialog without changing the PolkitAgent request lifecycle, password masking, submit or cancel semantics.
- Rework the left navigation sidebar and desktop context menu around larger everyday controls while keeping the sidebar free of duplicate microphone/device selection UI.
- Rebalance Screen Translator panels and actions while preserving the capture → OCR → translation → JSON → clipboard pipeline.
- Reduce runtime overhead by keeping Left Sidebar audio refreshes inside the existing PipeWire cache and by replacing unnecessary login-shell probes in Game Mode and System Info with non-login shell execution.

## 1.0.0 — First stable release

- Add native configurable desktop widgets for clock/date, live context, system status and ambient copy, with a dedicated searchable Settings page and compact layout.
- Rework Control Center quick tiles into a roomier two-column composition with softer entrance and ambient motion.
- Make the Welcome reveal follow the shared motion scale and derive its tour count from the onboarding model.
- Remove the obsolete iNiR custom-widget SDK and example that referenced retired runtime namespaces.
- Correct active project links to `killmyselfrin/raohane-dots`.
- Remove obsolete Settings V1/V2 implementations and point architecture/CI validation at the sole active Settings V3 surface.
- Advance config and audit contracts to schema v11 for the native desktop-widget settings.
- Keep Desktop Widgets visible near the top of Settings navigation and expose a clear scroll indicator on shorter displays.
- Replace the wallpaper grid with a large horizontal snap carousel supporting mouse-wheel, touchpad and keyboard browsing while preserving folders, previews and video entries.
- Replace the placeholder desktop composition with a dedicated native widget module containing responsive clock, media/context, system and ambient cards.
- Guarantee widget stacking by separating wallpaper (`Background`) and widget (`Bottom`) layer-shell levels.
- Turn the Desktop Widgets settings page into a visual Widget Studio with a live composition preview and large per-widget controls.
- Give every native Settings section a consistent visual hero with identity, description and control count instead of opening on an anonymous flat list.
- Add native balanced/left/right desktop-widget compositions plus live scale and opacity controls, using Raohane-owned editor and composition APIs.
- Advance native configuration and integrity checks to schema v12 for persisted widget composition settings.
- Add a Raohane-owned theme catalog loader and deterministic CLI importer/exporter.
- Keep bundled product themes in Raohane-owned QML and user themes in `~/.config/raohane/themes.json`.
- Load user themes live in the existing Theme Library with validation and atomic writes.
- Replace the stale legacy flake with native Raohane packages plus NixOS and Home Manager modules.
- Complete the standalone runtime boundary and remove the final third-party palette catalog from the active theme system.
- Promote the committed product version from development builds to `1.0.0`.

## 0.10.0-dev — Standalone + Minimal Theme System

- Shift the active Raohane visual direction from cyber-noir/neon toward Japanese minimalism while preserving the established UI layout and interaction model.
- Add a native whole-shell theme engine driven by shared `RaohaneTheme` tokens and persisted through `RaohaneConfig.themePreset`.
- Add the Settings `Theme Library` with live miniature shell previews and instant preset application.
- Ship eight initial presets: `Zen Mist`, `Paper`, `Sakura`, `Matcha`, `Slate`, `Sand`, `Sumi` and `Midnight`.
- Make `Zen Mist` the default: warm off-white frosted glass, charcoal text, thin borders, quiet accents and restrained motion.
- Keep `Sumi` and `Midnight` as coherent dark minimalist alternatives instead of maintaining a separate dark-only UI implementation.
- Restyle Settings, Settings Home, Control Center, Launcher, Context Island, Dock, Media Overlay, notifications and Overview/Spaces around the shared minimalist surface hierarchy.
- Remove decorative neon halos and the hard-coded cyber-noir Quick Control palette from primary shell surfaces.
- Extend Settings/global-search, core-framework and visual audits so theme selection, catalog registration, persistence and minimalist shared-surface contracts cannot silently regress.
- Complete the source/static standalone migration boundary: the active shell, services, configuration framework and visible runtime are Raohane-owned, while remaining hardware/session validation stays explicit.
- Add an automated source-lineage/license audit that distinguishes removed upstream runtime dependencies from retained GPL/data/asset provenance.
- Add reproducible source release packaging from committed `HEAD`, version consistency checks and SHA-256 verification through the release-boundary CI workflow.
- Make the Raohane product runtime explicitly Hyprland-only while keeping `ii-upstream` as a diagnostic fallback family.
- Add `RaohaneState.qml` so product-only ephemeral state survives end4 foundation refreshes.
- Add `RaohanePrivacy.qml` over Quickshell PipeWire for live microphone, camera and screen-capture context.
- Wire Context Island to live MPRIS, active-window and privacy data.
- Activate a Raohane-native horizontal bar while retaining mature workspace, tray and system providers.
- Add a dedicated Raohane launcher over `LauncherSearch` with keyboard navigation and native IPC.
- Add a fullscreen-friendly Raohane media overlay over the mature MPRIS backend.
- Replace the visible volume/brightness/gamma OSD with `RaohaneOsd.qml` while retaining Audio, Brightness and Hyprsunset providers.
- Replace the visible notification popup with `RaohaneNotificationPopup.qml` while retaining the mature notification server, persistence, timers and actions backend.
- Add a shared native notification card and notification center used by the Raohane Control Center.
- Replace compatibility right-sidebar quick controls with `RaohaneQuickControls.qml`, including Wi-Fi, Bluetooth, Night Light, Game Mode, idle inhibition, EasyEffects and native brightness/audio/microphone sliders.
- Remove the quick-control `jq` probe by parsing Hyprland JSON directly in QML.
- Replace the top-level Settings compatibility shell with `RaohaneSettingsContent.qml`, a Hyprland-only Raohane navigation layer over the mature configuration pages.
- Add `RaohaneSettingsHome.qml` as the wallpaper-backed Control Deck home surface with live context/system state.
- Replace the visible wallpaper selector with `RaohaneWallpaperSelector.qml` while retaining the mature `Wallpapers` service, preview and background transition path.
- Replace the visible desktop context menu with `RaohaneDesktopMenu.qml` while retaining background click coordinates, DropShelf and wallpaper services.
- Expand the `raohane` CLI with `media`, `desktop`, `wallpaper`, random-wallpaper control and batch diagnostics for dependencies, services and graphics.
- Add `./install-raohane.sh --deps` and `--no-start`; dependency installation stays pinned and GPU-driver mutation remains explicit.
- Expand static CI/audit coverage for native-surface registration, desktop/control/settings ownership boundaries, IPC routing, Hyprland product boundaries and upstream-refresh safety.
- Treat static validation as a structural gate only; the batch still requires a real Hyprland + Quickshell runtime pass before merge/release.

## dev-0.1
- Created from Raohane base.
- Retained full Raohane settings/config architecture.
- Added Raohane compatibility launcher.
- Rebranded Settings window titles.
- Replaced sidebar media widget with a Raohane MPRIS/CAVA player.
- Added initial product direction for Living Theme, Game Media Overlay, Focus Scene, Context Island, app profiles, and Japanese visual presets.

## 0.4.2-dev
- Fix HyprlandData singleton registration in services/qmldir.
- Fix Hyprland workspace/window data access under Hyprland.
- Harden Background.qml against transient missing client data.
- Fix undefined boolean binding in Raohane Island media pulse.

## 0.9.0-dev — Context Foundation

- Turn Context Island into a priority-based state surface for recording, microphone/privacy, media and active-window context.
- Add reusable Raohane quick tiles and a seekable MPRIS media card.
- Rework Control Center with Wi-Fi, Bluetooth, Focus and Night Light tiles plus privacy state.
- Add keyboard selection and quick actions to the Raohane Launcher.
- Add wallpaper-backed Settings Control Deck home surface.
- Implement a real floating game media overlay and `SUPER + SHIFT + M` Hyprland binding.
- Expand the Raohane config namespace for Context Island, Control Center and gaming behavior.
- Keep old shell identity out of primary UI, launcher and installer while backend replacement continues incrementally.
- Extend `raohane-audit.sh` to validate primary QML/import/identity boundaries.
