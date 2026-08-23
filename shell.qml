//@ pragma UseQApplication
//@ pragma ShellId raohane
// DISABLED: webapps — requires quickshell-webengine rebuild, re-enable when ready
//-@ pragma EnableQtWebEngineQuick
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma DefaultEnv QT_LOGGING_RULES=quickshell.dbus.properties=false
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma DefaultEnv QS_DROP_EXPENSIVE_FONTS=1
// Launcher keeps QT_SCALE_FACTOR=1; shell scaling lives in appearance.typography.sizeScale
// DISABLED: webapps — requires quickshell-webengine rebuild
//-@ pragma Env QTWEBENGINE_CHROMIUM_FLAGS=--disable-features=ThirdPartyCookieBlocking,StorageAccessAPI

import qs.modules.common
import qs.modules.raohane

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

ShellRoot {
    id: root

    readonly property bool disableHotReload: Quickshell.env("RAOHANE_DISABLE_HOT_RELOAD") === "1"
        || Quickshell.env("RAOHANE_DISABLE_HOT_RELOAD") === "true"

    function _log(msg: string): void {
        if (Quickshell.env("QS_DEBUG") === "1") console.log(msg);
    }

    // Force singleton instantiation — startup-critical only
    property var _idleService: Idle
    property var _powerProfilePersistence: PowerProfilePersistence
    property var _devNavigationService: DevNavigation
    property var _shellEditSessionService: ShellEditSession
    // Acquire org.kde.StatusNotifierWatcher before graphical-session.target
    // releases XDG autostart applications. The systemd unit uses Type=dbus.
    property var _trayService: TrayService
    property var _globalActionsService

    // Deferred singletons — initialized after first frame to reduce boot contention
    // Tier 3: T+500ms (display/interaction services)
    property var _gameModeService
    property var _windowPreviewService
    property var _weatherService
    property var _voiceSearchService
    property var _fontSyncService
    property var _cavaThemeService
    // Screen Time must exist for the whole enabled session, not only after its
    // sidebar page is first opened. It is explicitly materialized after the
    // first frame and when the user enables tracking later.
    property var _screenTimeService
    function _ensureScreenTimeService(): void {
        if (GlobalStates.deferredPanelsReady
                && (Config.options?.sidebar?.screenTime?.enable ?? false))
            root._screenTimeService = ScreenTime
    }
    // Tier 4: T+1500ms (background features - updates, sync, content services)
    property var _shellUpdatesService
    property var _autostartService
    property var _calendarSyncService
    property var _todoService
    property var _notepadService

    // Boot phase timing (ms since epoch). Written to ~/.cache/raohane/last-boot.json
    // when the deferred phase finishes. `raohane status` reads this back to show users
    // exactly where their startup time goes — systemd → qs launch → QML completed →
    // Config ready → shell entry → deferred services. Useful for triaging "15-20s startup"
    // reports without asking the user to run journalctl.
    property real _bootCompletedAt: 0
    property real _bootConfigReadyAt: 0
    property real _bootShellEntryAt: 0
    property real _bootDeferredAt: 0
    readonly property string _bootCachePath: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/raohane/last-boot.json"

    Component.onCompleted: {
        root._bootCompletedAt = Date.now();
        console.info("[Boot] T+0ms: Component.onCompleted (shell.qml ready)");
        Quickshell.watchFiles = !disableHotReload;
        
        // Tier 0: startup-critical singletons (no delay)
        root._log("[Boot] Tier 0: startup-critical singletons");
        FirstRunExperience.load();
        ConflictKiller.load();
        // Force MemoryPressureService instantiation for IPC (#164)
        void MemoryPressureService.enabled;
        // Same reason: GlobalActions owns the `globalActions` IPC target and is
        // otherwise only constructed when the command palette first opens, so
        // scripts and keybinds got "Target not found" until then. Tier 0 also
        // keeps the gap after a config reload as short as every other handler's.
        root._globalActionsService = GlobalActions;
        DevNavigation.registerSettingsPages(RaohaneSettingsRegistry.pages);
        
        // Reset shell entry state (hot-reload may preserve singletons)
        GlobalStates.shellEntryReady = false;
        GlobalStates.deferredPanelsReady = false;
        
        if (Config.ready) {
            root._bootConfigReadyAt = Date.now();
            console.info("[Boot] T+" + (root._bootConfigReadyAt - root._bootCompletedAt) + "ms: Config.ready (immediate)");
            // Config was already ready before this root was (re)built (hot-reload / preserved
            // singletons). onReadyChanged won't fire, so apply theme + icons here too,
            // otherwise the shell comes up with stale/unthemed colors and icons.
            Qt.callLater(() => ThemeService.applyCurrentTheme());
            Qt.callLater(() => IconThemeService.ensureInitialized());
            shellEntryTimer.start();
        }
    }

    // Shell entry animation: panels start hidden, slide in after a brief delay
    // 200ms is enough for LazyLoader panels to be created on warm cache;
    // on cold boot the progressive slide-in is better UX than extra blank time
    // Tier 1-2: Implicit — UI-critical services load with panels (Audio, Battery, etc.)
    Timer {
        id: shellEntryTimer
        interval: Appearance.animationsEnabled ? 200 : 0
        repeat: false
        onTriggered: {
            if (!root._bootShellEntryAt) root._bootShellEntryAt = Date.now();
            console.info("[Boot] T+" + (root._bootShellEntryAt - root._bootCompletedAt) + "ms: shellEntryReady (first frame)");
            GlobalStates.shellEntryReady = true;
            deferredInitTimer.start();
        }
    }

    // Deferred initialization: load non-critical services and panels after the first frame
    // is rendered, spreading startup work over time to reduce the boot contention burst
    // Tier 3: T+500ms — display/interaction services needed soon after first frame
    Timer {
        id: deferredInitTimer
        interval: 500
        repeat: false
        onTriggered: {
            root._log("[Boot] T+" + (Date.now() - root._bootCompletedAt) + "ms: Tier 3 (display/interaction)");
            root._gameModeService = GameMode;
            root._weatherService = Weather;
            root._voiceSearchService = VoiceSearch;
            root._fontSyncService = FontSyncService;
            root._cavaThemeService = CavaTheme;
            Hyprsunset.load();
            GlobalStates.deferredPanelsReady = true;
            root._ensureScreenTimeService();
            // Boot greeting: show once per session (singleton preserves bootGreetingDone across hot-reload)
            if (!GlobalStates.bootGreetingDone && (Config.options?.bootGreeting?.enable ?? true)) {
                GlobalStates.bootGreetingOpen = true;
            }
            if (!root._bootDeferredAt) {
                root._bootDeferredAt = Date.now();
            }
            // Kick off Tier 4 loading
            lateFeaturesTimer.start();
        }
    }

    Connections {
        target: Config
        function onConfigChanged(): void {
            root._ensureScreenTimeService()
        }
    }

    // Tier 4: T+1500ms — background features that can wait (updates, sync, content)
    // These services do background work (network requests, file I/O) that doesn't affect UX
    property real _bootLateFeaturesAt: 0
    Timer {
        id: lateFeaturesTimer
        interval: 1000  // +1000ms after Tier 3 = T+1500ms total
        repeat: false
        onTriggered: {
            root._log("[Boot] T+" + (Date.now() - root._bootCompletedAt) + "ms: Tier 4 (background features)");
            root._shellUpdatesService = ShellUpdates;
            root._autostartService = Autostart;
            root._calendarSyncService = CalendarSync;
            root._todoService = Todo;
            root._notepadService = Notepad;
            root._bootLateFeaturesAt = Date.now();
            root._writeBootPhase();
        }
    }

    // Persist boot phase timestamps so `raohane status` can report startup breakdown
    // without asking the user to run journalctl. Only written once per boot — hot-reloads
    // overwrite (which is intentional, latest run is what matters for diagnostics).
    function _writeBootPhase(): void {
        if (!root._bootCompletedAt) return;
        const data = {
            componentCompletedAt: Math.floor(root._bootCompletedAt),
            configReadyAt: Math.floor(root._bootConfigReadyAt),
            shellEntryAt: Math.floor(root._bootShellEntryAt),
            deferredReadyAt: Math.floor(root._bootDeferredAt),
            lateFeaturesAt: Math.floor(root._bootLateFeaturesAt),
            // Deltas for easier analysis
            deltas: {
                configReady: Math.floor(root._bootConfigReadyAt - root._bootCompletedAt),
                shellEntry: Math.floor(root._bootShellEntryAt - root._bootConfigReadyAt),
                deferred: Math.floor(root._bootDeferredAt - root._bootShellEntryAt),
                lateFeatures: Math.floor(root._bootLateFeaturesAt - root._bootDeferredAt)
            },
            shellPid: 0,
            writtenAt: Math.floor(Date.now())
        };
        bootPhaseWriter.setText(JSON.stringify(data, null, 2));
    }

    FileView {
        id: bootPhaseWriter
        path: root._bootCachePath
        printErrors: false
    }

    Connections {
        target: Config
        function onReadyChanged() {
            if (Config.ready) {
                if (!root._bootConfigReadyAt) {
                    root._bootConfigReadyAt = Date.now();
                    console.info("[Boot] T+" + (root._bootConfigReadyAt - root._bootCompletedAt) + "ms: Config.ready (async)");
                }
                root._log("[Boot] Applying theme and icon theme");
                Qt.callLater(() => ThemeService.applyCurrentTheme());
                Qt.callLater(() => IconThemeService.ensureInitialized());
                // Kick off shell entry animation after panels have been created.
                // Tier 3 is scheduled by shellEntryTimer so its 500 ms delay is
                // measured from the first frame, not concurrently with it.
                shellEntryTimer.start();
                // Raohane 0.8 collapses the old family switcher into one shell identity.
                if ((Config.options?.panelFamily ?? "raohane") !== "raohane")
                    Config.setNestedValue("panelFamily", "raohane")
                if ((Config.options?.appearance?.globalStyle ?? "material") === "inir")
                    Config.setNestedValue("appearance.globalStyle", "raohane")

                // Remove primary legacy panel identifiers from upgraded configs.
                // Their Raohane replacements are loaded directly and do not use enabledPanels.
                const legacyPrimaryPanels = ["iiBar", "iiSidebarRight", "iiOverview", "iiSidebarLeft", "iiShellUpdate"]
                const configuredPanels = [...(Config.options?.enabledPanels ?? [])]
                const cleanedPanels = configuredPanels.filter(p => !legacyPrimaryPanels.includes(p))
                if (cleanedPanels.length !== configuredPanels.length)
                    Config.setNestedValue("enabledPanels", cleanedPanels)

                // Only reset enabledPanels if it's empty or undefined (first run / corrupted config)
                if (!Config.options?.enabledPanels || Config.options.enabledPanels.length === 0) {
                    const family = "raohane"
                    if (root.families.includes(family)) {
                        Config.setNestedValue("enabledPanels", root.panelFamilies[family])
                    }
                }
                root.migrateEnabledPanels();
            }
        }
    }

    // Migrate enabledPanels for users upgrading from older versions
    property bool _migrationDone: false
    function migrateEnabledPanels() {
        if (_migrationDone) return;
        _migrationDone = true;

        const family = "raohane";
        let panels = [...(Config.options?.enabledPanels ?? [])];
        let changed = false;

        // 0.8 namespace migration: active panel ids no longer use the old ii
        // family. Preserve the user's enabled/disabled choices where a direct
        // Raohane equivalent exists and drop surfaces that Raohane replaced.
        const legacyPanelMap = ({
            "iiBackground": "raohaneBackground",
            "iiBackdrop": "raohaneBackdrop",
            "iiLock": "raohaneLock",
            "iiCheatsheet": "raohaneHotkeys",
            "iiNotificationPopup": "raohaneNotifications",
            "iiOnScreenDisplay": "raohaneOsd",
            "iiOnScreenKeyboard": "raohaneKeyboard",
            "iiOverlay": "raohaneOverlay",
            "iiPolkit": "raohanePolkit",
            "iiRegionSelector": "raohaneRegionSelector",
            "iiScreenCorners": "raohaneScreenCorners",
            "iiSessionScreen": "raohaneSession",
            "iiTilingOverlay": "raohaneTiling",
            "iiWallpaperSelector": "raohaneWallpaperSelector",
            "iiWallpaperLauncher": "raohaneWallpaperLauncher",
            "iiCoverflowSelector": "raohaneWallpaperCoverflow",
            "iiClipboard": "raohaneClipboard",
            "iiRecordingOsd": "raohaneRecordingOsd",
            "iiMascotCompanion": "raohaneMascot"
        })
        const removedLegacyPanels = [
            "iiBar", "iiVerticalBar", "iiSidebarRight", "iiSidebarLeft", "iiOverview", "iiDock", "raohaneDock",
            "iiControlPanel", "iiDashboard", "iiMediaControls", "iiWorkspaceStrip",
            "iiShellUpdate", "iiBootGreeting"
        ]
        const originalPanels = [...panels]
        panels = panels
            .map(p => legacyPanelMap[p] ?? p)
            .filter(p => !removedLegacyPanels.includes(p))
            .filter((p, i, a) => a.indexOf(p) === i)
        if (JSON.stringify(panels) !== JSON.stringify(originalPanels))
            changed = true

        // Only add genuinely NEW panels (from updates), not panels the user deliberately disabled.
        // knownPanels tracks what the user has seen. If a panel is in knownPanels but not in
        // enabledPanels, the user removed it — don't re-add.
        const basePanels = root.panelFamilies[family] ?? [];
        let known = [...(Config.options?.knownPanels ?? [])]
            .map(p => legacyPanelMap[p] ?? p)
            .filter(p => !removedLegacyPanels.includes(p))
            .filter((p, i, a) => a.indexOf(p) === i);
        const isFirstRun = known.length === 0;

        if (!isFirstRun && JSON.stringify(known) !== JSON.stringify(Config.options?.knownPanels ?? []))
            Config.setNestedValue("knownPanels", known)

        if (isFirstRun) {
            // First boot with this logic — seed knownPanels with ALL families' panels.
            // This prevents re-adding panels that existing users already disabled,
            // including across family switches.
            const allPanels = [];
            for (const fam of root.families) {
                for (const p of (root.panelFamilies[fam] ?? [])) {
                    if (!allPanels.includes(p)) allPanels.push(p);
                }
            }
            Config.setNestedValue("knownPanels", allPanels);
        } else {
            // Subsequent boots: only add panels that are new (not in knownPanels)
            let knownChanged = false;
            for (const panel of basePanels) {
                if (!known.includes(panel)) {
                    // Genuinely new panel from an update
                    if (!panels.includes(panel)) {
                        root._log("[Shell] Adding new panel to enabledPanels: " + panel);
                        panels.push(panel);
                        changed = true;
                    }
                    known.push(panel);
                    knownChanged = true;
                }
            }
            if (knownChanged) {
                Config.setNestedValue("knownPanels", known);
            }
        }


        const legacyPinnedApps = ["org.gnome.Nautilus", "firefox", "foot"];
        const currentPinnedApps = Config.options?.dock?.pinnedApps ?? [];
        if (currentPinnedApps.length === legacyPinnedApps.length
                && currentPinnedApps.every((panel, idx) => panel === legacyPinnedApps[idx])) {
            root._log("[Shell] Migrating dock.pinnedApps default terminal from foot to kitty");
            Config.setNestedValue("dock.pinnedApps", ["org.gnome.Nautilus", "firefox", "kitty"])
        }

        if (changed)
            Config.setNestedValue("enabledPanels", panels)
    }

    // IPC target "bar" — registered once here (always loaded) instead of inside
    // Bar.qml / VerticalBar.qml. Both ii bars are instantiated together, so a
    // per-bar handler collided and Quickshell dropped one with a warning. All
    // three bars only toggle GlobalStates.barOpen, so a single shared handler is
    // owned by the Raohane root and shared by horizontal and compatibility bars.
    IpcHandler {
        target: "bar"
        function toggle(): void {
            GlobalStates.barOpen = !GlobalStates.barOpen
        }
        function close(): void {
            GlobalStates.barOpen = false
        }
        function open(): void {
            GlobalStates.barOpen = true
        }
    }

    // ii interaction routers stay resident with the root so commands remain
    // available while the heavier family panel tree is deferred.
    // Compatibility aliases for older keybinds. They resolve to Raohane-owned
    // surfaces instead of reviving removed legacy panels.
    IpcHandler {
        target: "controlPanel"
        function toggle(): void { GlobalStates.toggleControlCenter("") }
        function close(): void { GlobalStates.closeControlCenter() }
        function open(): void { GlobalStates.openControlCenter("") }
    }

    IpcHandler {
        target: "dashboard"
        function toggle(): void { GlobalStates.settingsOverlayOpen = !GlobalStates.settingsOverlayOpen }
        function close(): void { GlobalStates.settingsOverlayOpen = false }
        function open(): void { GlobalStates.settingsOverlayOpen = true }
    }

    IpcHandler {
        target: "sidebarLeft"
        function toggle(): void { GlobalStates.raohaneLauncherOpen = !GlobalStates.raohaneLauncherOpen }
        function close(): void { GlobalStates.raohaneLauncherOpen = false }
        function open(): void { GlobalStates.raohaneLauncherOpen = true }
        function expand(): void { GlobalStates.raohaneLauncherOpen = true }
        function compact(): void {}
        function status(): string { return JSON.stringify({ open: GlobalStates.raohaneLauncherOpen, replacement: "raohaneLauncher" }) }
        function detach(): void {}
        function attach(): void { GlobalStates.raohaneLauncherOpen = true }
    }

    IpcHandler {
        target: "sidebarRight"
        function toggle(): void { GlobalStates.toggleControlCenter("") }
        function close(): void { GlobalStates.closeControlCenter() }
        function open(): void { GlobalStates.openControlCenter("") }
    }

    IpcHandler {
        target: "mediaControls"
        function toggle(): void { GlobalStates.toggleControlCenter("") }
        function close(): void { GlobalStates.closeControlCenter() }
        function open(): void { GlobalStates.openControlCenter("") }
    }

    // Raohane owns one settings experience. The old Raohane window/rail/focus
    // split is intentionally bypassed so `raohane settings` always opens the
    // same Hyprland-first surface.
    IpcHandler {
        target: "controlCenter"
        function toggle(): void { GlobalStates.toggleControlCenter("") }
        function close(): void { GlobalStates.closeControlCenter() }
        function open(): void { GlobalStates.openControlCenter("") }
    }

    IpcHandler {
        target: "settings"
        function open(): void { GlobalStates.settingsOverlayOpen = true }
        function close(): void { GlobalStates.settingsOverlayOpen = false }
        function toggle(): void { GlobalStates.settingsOverlayOpen = !GlobalStates.settingsOverlayOpen }
    }

    // One owner for settingsNav, here rather than inside a chrome. Both overlay
    // layouts used to declare this target themselves; switching layouts leaves
    // the outgoing host alive for a moment, so Quickshell saw two registrations
    // and silently dropped one — the caller then hit whichever survived. Routing
    // through GlobalStates keeps the target valid no matter which chrome, or
    // none, is loaded.
    IpcHandler {
        target: "settingsNav"
        function page(index: int): void {
            GlobalStates.settingsOverlayRequestedPage = index
            GlobalStates.settingsOverlayOpen = true
        }
        function count(): int { return RaohaneSettingsRegistry.pages.length }
        function current(): int { return GlobalStates.settingsOverlayCurrentPage }
    }

    IpcHandler {
        target: "raohaneLauncher"
        function toggle(): void { GlobalStates.raohaneLauncherOpen = !GlobalStates.raohaneLauncherOpen }
        function open(): void { GlobalStates.raohaneLauncherOpen = true }
        function close(): void { GlobalStates.raohaneLauncherOpen = false }
    }

    IpcHandler {
        target: "raohaneMediaOverlay"
        function toggle(): void { GlobalStates.raohaneMediaOverlayOpen = !GlobalStates.raohaneMediaOverlayOpen }
        function open(): void { GlobalStates.raohaneMediaOverlayOpen = true }
        function close(): void { GlobalStates.raohaneMediaOverlayOpen = false }
    }

    LazyLoader {
        active: Config.ready
        component: RaohaneLauncher {}
    }

    LazyLoader {
        active: Config.ready
        component: RaohaneMediaOverlay {}
    }

    // Raohane Settings stays resident as a light Scope and constructs the
    // full-screen layer only while it is open.
    LazyLoader {
        active: Config.ready
        component: RaohaneSettings {}
    }

    // === Raohane window switcher ===
    // Hyprland-native: does not instantiate the legacy Niri switcher or preview cache.
    LazyLoader {
        active: Config.ready
        component: RaohaneAltSwitcher {}
    }

    // Compatibility surfaces are deferred so Raohane primary UI owns first paint.
    // Family-agnostic IPC routers. Both panel files used to instantiate their
    // own copy, so during a family switch — when the outgoing loader is still
    // being torn down — two instances existed and Quickshell dropped one
    // handler per target (region, tiling, wallpaperSelector, coverflowSelector).
    // One owner here is valid whichever family is loaded.
    LazyLoader { active: Config.ready; source: "modules/regionSelector/RegionSelectorRouter.qml" }
    LazyLoader { active: Config.ready; source: "modules/tilingOverlay/TilingOverlayRouter.qml" }
    LazyLoader { active: Config.ready; source: "modules/wallpaperSelector/WallpaperSelectorRouter.qml" }

    // Same reason as the routers: both panel files declared these, so every
    // old multi-host loading registered them twice; the root owns them now.
    // The four below were byte-identical in both files; only overview differs,
    // so it branches here instead of existing twice.
    IpcHandler {
        target: "osk"
        function toggle(): void { GlobalStates.oskOpen = !GlobalStates.oskOpen }
        function close(): void { GlobalStates.oskOpen = false }
        function open(): void { GlobalStates.oskOpen = true }
    }

    IpcHandler {
        target: "overlay"
        function toggle(): void { GlobalStates.overlayOpen = !GlobalStates.overlayOpen }
    }

    IpcHandler {
        target: "session"
        function toggle(): void { GlobalStates.sessionOpen = !GlobalStates.sessionOpen }
        function close(): void { GlobalStates.sessionOpen = false }
        function open(): void { GlobalStates.sessionOpen = true }
    }

    IpcHandler {
        target: "cheatsheet"
        function toggle(): void { GlobalStates.cheatsheetOpen = !GlobalStates.cheatsheetOpen }
        function close(): void { GlobalStates.cheatsheetOpen = false }
        function open(): void { GlobalStates.cheatsheetOpen = true }
    }

    IpcHandler {
        target: "clipboard"
        function open(): void { GlobalStates.clipboardOpen = true }
        function close(): void { GlobalStates.clipboardOpen = false }
        function toggle(): void { GlobalStates.clipboardOpen = !GlobalStates.clipboardOpen }
    }

    IpcHandler {
        target: "overview"
        function toggle(): void { GlobalStates.raohaneLauncherOpen = !GlobalStates.raohaneLauncherOpen }
        function close(): void { GlobalStates.raohaneLauncherOpen = false }
        function open(): void { GlobalStates.raohaneLauncherOpen = true }
        function toggleReleaseInterrupt(): void { GlobalStates.superReleaseMightTrigger = false }
        function clipboardToggle(): void { GlobalStates.clipboardOpen = !GlobalStates.clipboardOpen }
        function actionOpen(): void { GlobalStates.raohaneLauncherOpen = true }
    }


    // Raohane-owned primary surfaces. These no longer depend on iiBar or
    // iiSidebarRight identifiers; the legacy panel family only supplies
    // compatibility modules that have not been rewritten yet.
    LazyLoader {
        loading: Config.ready
        activeAsync: Config.ready
        component: RaohaneBar {}
    }

    LazyLoader {
        readonly property bool enabled: Config.ready && GlobalStates.deferredPanelsReady
        loading: enabled
        activeAsync: enabled
        component: RaohaneControlCenter {}
    }

    LazyLoader {
        loading: Config.ready
        activeAsync: Config.ready
        component: RaohaneCriticalPanels {}
    }

    LazyLoader {
        readonly property bool enabled: Config.ready && GlobalStates.deferredPanelsReady
        loading: enabled
        activeAsync: enabled
        component: RaohaneCompatibilityPanels {}
    }

    // Close confirmation dialog (always loaded, handles IPC)
    LazyLoader { active: Config.ready; source: "modules/closeConfirm/CloseConfirm.qml" }

    // Shared (always loaded via ToastManager)
    ToastManager {}

    // === Panel Families ===
    // Compatibility providers used by features that have not yet been rewritten.
    property list<string> families: ["raohane"]
    property var panelFamilies: ({
        "raohane": [
            // Transitional system providers. Every active identifier belongs to
            // Raohane; primary UI is loaded directly and is not listed here.
            "raohaneBackground", "raohaneBackdrop", "raohaneLock",
            "raohaneHotkeys", "raohaneNotifications", "raohaneOsd", "raohaneKeyboard",
            "raohaneOverlay", "raohanePolkit", "raohaneRegionSelector", "raohaneScreenCorners",
            "raohaneSession", "raohaneTiling", "raohaneWallpaperSelector",
            "raohaneWallpaperLauncher", "raohaneWallpaperCoverflow", "raohaneClipboard",
            "raohaneRecordingOsd", "raohaneMascot"
        ]
    })

    // Raohane is the only shell family. This compatibility IPC exists so old
    // keybinds do not fail, but every operation resolves to Raohane.
    function cyclePanelFamily() { Config.setNestedValue("panelFamily", "raohane") }
    function setPanelFamily(family: string) { Config.setNestedValue("panelFamily", "raohane") }

    IpcHandler {
        target: "panelFamily"
        function cycle(): void { root.cyclePanelFamily() }
        function set(family: string): void { root.setPanelFamily(family) }
    }

}
