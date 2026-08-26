pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import QtQml
import Quickshell

import qs
import qs.modules.common
import qs.modules.raohane.config

Singleton {
    id: root

    property bool syncing: false
    property bool syncingState: false
    property bool initialized: false

    function load(): void {}

    function seedNativeFromLegacy(): void {
        if (!RaohaneConfig.ready || !Config.ready || root.initialized)
            return

        root.syncing = true

        if (RaohaneConfig.wallpaperPath.length === 0)
            RaohaneConfig.wallpaperPath = Config.options?.background?.wallpaperPath ?? ""
        if (RaohaneConfig.lockWallpaperPath.length === 0)
            RaohaneConfig.lockWallpaperPath = Config.options?.background?.lockWall ?? ""

        RaohaneConfig.wallpaperPreview = Config.options?.background?.enableWallpaperPreview ?? RaohaneConfig.wallpaperPreview
        RaohaneConfig.wallpaperHideWhenFullscreen = Config.options?.background?.hideWhenFullscreen ?? RaohaneConfig.wallpaperHideWhenFullscreen
        RaohaneConfig.wallpaperColumns = Config.options?.wallpaperSelector?.columns ?? RaohaneConfig.wallpaperColumns
        RaohaneConfig.wallpaperChangeInterval = Config.options?.wallpaperSelector?.changeInterval ?? RaohaneConfig.wallpaperChangeInterval

        const legacyOverviewColumns = Config.options?.overview?.columns ?? RaohaneConfig.overviewColumns
        const legacyOverviewRows = Config.options?.overview?.rows ?? Math.ceil(RaohaneConfig.overviewWorkspaceCount / legacyOverviewColumns)
        RaohaneConfig.overviewColumns = legacyOverviewColumns
        RaohaneConfig.overviewWorkspaceCount = Math.max(2, legacyOverviewColumns * legacyOverviewRows)

        if (Config.options?.dock) {
            RaohaneConfig.dockEnabled = Config.options.dock.enable ?? RaohaneConfig.dockEnabled
            RaohaneConfig.dockAutoHide = Config.options.dock.hoverToReveal ?? RaohaneConfig.dockAutoHide
            RaohaneConfig.dockPinned = Config.options.dock.pinnedOnStartup ?? RaohaneConfig.dockPinned
            RaohaneConfig.dockHeight = Config.options.dock.height ?? RaohaneConfig.dockHeight
            RaohaneConfig.dockPinnedApps = Array.from(Config.options.dock.pinnedApps ?? [])
        }

        RaohaneConfig.barBottom = Config.options?.bar?.bottom ?? RaohaneConfig.barBottom
        RaohaneConfig.osdTimeout = Config.options?.osd?.timeout ?? RaohaneConfig.osdTimeout
        RaohaneConfig.colorTemperature = Config.options?.light?.night?.colorTemperature ?? RaohaneConfig.colorTemperature
        RaohaneConfig.nightLightAutomatic = Config.options?.light?.night?.automatic ?? RaohaneConfig.nightLightAutomatic

        RaohaneConfig.networkCommand = Config.options?.apps?.network ?? RaohaneConfig.networkCommand
        RaohaneConfig.networkEthernetCommand = Config.options?.apps?.networkEthernet ?? RaohaneConfig.networkEthernetCommand
        RaohaneConfig.bluetoothCommand = Config.options?.apps?.bluetooth ?? RaohaneConfig.bluetoothCommand
        if (RaohaneConfig.taskManagerCommand.length === 0)
            RaohaneConfig.taskManagerCommand = Config.options?.apps?.taskManager ?? ""
        if (RaohaneConfig.changePasswordCommand === "passwd") {
            const legacyCommand = Config.options?.apps?.changePassword ?? ""
            if (legacyCommand.length > 0)
                RaohaneConfig.changePasswordCommand = legacyCommand
        }

        RaohaneConfig.quickSliderBrightness = Config.options?.sidebar?.quickSliders?.showBrightness ?? RaohaneConfig.quickSliderBrightness
        RaohaneConfig.quickSliderVolume = Config.options?.sidebar?.quickSliders?.showVolume ?? RaohaneConfig.quickSliderVolume
        RaohaneConfig.quickSliderMic = Config.options?.sidebar?.quickSliders?.showMic ?? RaohaneConfig.quickSliderMic

        root.syncing = false
        root.initialized = true
        root.pushNativeToLegacy()
    }

    function pushNativeToLegacy(): void {
        if (root.syncing || !Config.ready || !RaohaneConfig.ready)
            return

        root.syncing = true

        if (Config.options?.background) {
            Config.options.background.wallpaperPath = RaohaneConfig.wallpaperPath
            Config.options.background.lockWall = RaohaneConfig.lockWallpaperPath
            Config.options.background.enableWallpaperPreview = RaohaneConfig.wallpaperPreview
            Config.options.background.hideWhenFullscreen = RaohaneConfig.wallpaperHideWhenFullscreen
        }
        if (Config.options?.wallpaperSelector) {
            Config.options.wallpaperSelector.columns = RaohaneConfig.wallpaperColumns
            Config.options.wallpaperSelector.changeInterval = RaohaneConfig.wallpaperChangeInterval
        }
        if (Config.options?.overview) {
            Config.options.overview.columns = RaohaneConfig.overviewColumns
            Config.options.overview.rows = Math.ceil(RaohaneConfig.overviewWorkspaceCount / RaohaneConfig.overviewColumns)
        }
        if (Config.options?.dock) {
            Config.options.dock.enable = RaohaneConfig.dockEnabled
            Config.options.dock.hoverToReveal = RaohaneConfig.dockAutoHide
            Config.options.dock.pinnedOnStartup = RaohaneConfig.dockPinned
            Config.options.dock.height = RaohaneConfig.dockHeight
            Config.options.dock.pinnedApps = RaohaneConfig.dockPinnedApps
        }
        if (Config.options?.bar)
            Config.options.bar.bottom = RaohaneConfig.barBottom
        if (Config.options?.osd)
            Config.options.osd.timeout = RaohaneConfig.osdTimeout
        if (Config.options?.light?.night) {
            Config.options.light.night.colorTemperature = RaohaneConfig.colorTemperature
            Config.options.light.night.automatic = RaohaneConfig.nightLightAutomatic
        }
        if (Config.options?.apps) {
            Config.options.apps.network = RaohaneConfig.networkCommand
            Config.options.apps.networkEthernet = RaohaneConfig.networkEthernetCommand
            Config.options.apps.bluetooth = RaohaneConfig.bluetoothCommand
            if (RaohaneConfig.taskManagerCommand.length > 0)
                Config.options.apps.taskManager = RaohaneConfig.taskManagerCommand
            if (RaohaneConfig.changePasswordCommand.length > 0)
                Config.options.apps.changePassword = RaohaneConfig.changePasswordCommand
        }
        if (Config.options?.sidebar?.quickSliders) {
            Config.options.sidebar.quickSliders.showBrightness = RaohaneConfig.quickSliderBrightness
            Config.options.sidebar.quickSliders.showVolume = RaohaneConfig.quickSliderVolume
            Config.options.sidebar.quickSliders.showMic = RaohaneConfig.quickSliderMic
        }

        root.syncing = false
    }

    function pullLegacyWallpaper(): void {
        if (root.syncing || !RaohaneConfig.ready)
            return
        root.syncing = true
        RaohaneConfig.wallpaperPath = Config.options?.background?.wallpaperPath ?? ""
        RaohaneConfig.lockWallpaperPath = Config.options?.background?.lockWall ?? ""
        RaohaneConfig.wallpaperPreview = Config.options?.background?.enableWallpaperPreview ?? true
        RaohaneConfig.wallpaperHideWhenFullscreen = Config.options?.background?.hideWhenFullscreen ?? true
        root.syncing = false
    }

    function pullLegacyWallpaperSelector(): void {
        if (root.syncing || !RaohaneConfig.ready)
            return
        root.syncing = true
        RaohaneConfig.wallpaperColumns = Config.options?.wallpaperSelector?.columns ?? 4
        RaohaneConfig.wallpaperChangeInterval = Config.options?.wallpaperSelector?.changeInterval ?? 0
        root.syncing = false
    }

    function pullLegacyOverview(): void {
        if (root.syncing || !RaohaneConfig.ready)
            return
        root.syncing = true
        const columns = Config.options?.overview?.columns ?? 3
        const rows = Config.options?.overview?.rows ?? 2
        RaohaneConfig.overviewColumns = columns
        RaohaneConfig.overviewWorkspaceCount = Math.max(2, columns * rows)
        root.syncing = false
    }

    function pullLegacyDock(): void {
        if (root.syncing || !RaohaneConfig.ready)
            return
        root.syncing = true
        RaohaneConfig.dockEnabled = Config.options?.dock?.enable ?? true
        RaohaneConfig.dockAutoHide = Config.options?.dock?.hoverToReveal ?? true
        RaohaneConfig.dockPinned = Config.options?.dock?.pinnedOnStartup ?? false
        RaohaneConfig.dockHeight = Config.options?.dock?.height ?? 68
        RaohaneConfig.dockPinnedApps = Array.from(Config.options?.dock?.pinnedApps ?? [])
        root.syncing = false
    }

    function pullLegacyShellChrome(): void {
        if (root.syncing || !RaohaneConfig.ready)
            return
        root.syncing = true
        RaohaneConfig.barBottom = Config.options?.bar?.bottom ?? false
        RaohaneConfig.osdTimeout = Config.options?.osd?.timeout ?? 1000
        RaohaneConfig.quickSliderBrightness = Config.options?.sidebar?.quickSliders?.showBrightness ?? true
        RaohaneConfig.quickSliderVolume = Config.options?.sidebar?.quickSliders?.showVolume ?? true
        RaohaneConfig.quickSliderMic = Config.options?.sidebar?.quickSliders?.showMic ?? false
        root.syncing = false
    }

    function pullLegacyDisplay(): void {
        if (root.syncing || !RaohaneConfig.ready)
            return
        root.syncing = true
        RaohaneConfig.colorTemperature = Config.options?.light?.night?.colorTemperature ?? 5000
        RaohaneConfig.nightLightAutomatic = Config.options?.light?.night?.automatic ?? true
        root.syncing = false
    }

    function pullLegacyApps(): void {
        if (root.syncing || !RaohaneConfig.ready)
            return
        root.syncing = true
        RaohaneConfig.networkCommand = Config.options?.apps?.network ?? "nm-connection-editor"
        RaohaneConfig.networkEthernetCommand = Config.options?.apps?.networkEthernet ?? "nm-connection-editor"
        RaohaneConfig.bluetoothCommand = Config.options?.apps?.bluetooth ?? "blueman-manager"
        RaohaneConfig.taskManagerCommand = Config.options?.apps?.taskManager ?? ""
        RaohaneConfig.changePasswordCommand = Config.options?.apps?.changePassword ?? "passwd"
        root.syncing = false
    }

    function pullLegacyTransientState(): void {
        if (root.syncingState)
            return
        root.syncingState = true
        RaohaneState.wallpaperSelectorOpen = GlobalStates.wallpaperSelectorOpen
        RaohaneState.wallpaperSelectorTarget = GlobalStates.wallpaperSelectorTarget ?? "wallpaper"
        RaohaneState.overviewOpen = GlobalStates.overviewOpen
        root.syncingState = false
    }

    function pushNativeTransientState(): void {
        if (root.syncingState)
            return
        root.syncingState = true
        GlobalStates.wallpaperSelectorOpen = RaohaneState.wallpaperSelectorOpen
        GlobalStates.wallpaperSelectorTarget = RaohaneState.wallpaperSelectorTarget
        GlobalStates.overviewOpen = RaohaneState.overviewOpen
        root.syncingState = false
    }

    Connections {
        target: RaohaneConfig
        function onReloaded(): void { root.seedNativeFromLegacy() }
        function onWallpaperPathChanged(): void { root.pushNativeToLegacy() }
        function onLockWallpaperPathChanged(): void { root.pushNativeToLegacy() }
        function onWallpaperPreviewChanged(): void { root.pushNativeToLegacy() }
        function onWallpaperHideWhenFullscreenChanged(): void { root.pushNativeToLegacy() }
        function onWallpaperColumnsChanged(): void { root.pushNativeToLegacy() }
        function onWallpaperChangeIntervalChanged(): void { root.pushNativeToLegacy() }
        function onOverviewWorkspaceCountChanged(): void { root.pushNativeToLegacy() }
        function onOverviewColumnsChanged(): void { root.pushNativeToLegacy() }
        function onDockEnabledChanged(): void { root.pushNativeToLegacy() }
        function onDockAutoHideChanged(): void { root.pushNativeToLegacy() }
        function onDockPinnedChanged(): void { root.pushNativeToLegacy() }
        function onDockHeightChanged(): void { root.pushNativeToLegacy() }
        function onDockPinnedAppsChanged(): void { root.pushNativeToLegacy() }
        function onBarBottomChanged(): void { root.pushNativeToLegacy() }
        function onOsdTimeoutChanged(): void { root.pushNativeToLegacy() }
        function onColorTemperatureChanged(): void { root.pushNativeToLegacy() }
        function onNightLightAutomaticChanged(): void { root.pushNativeToLegacy() }
        function onNetworkCommandChanged(): void { root.pushNativeToLegacy() }
        function onNetworkEthernetCommandChanged(): void { root.pushNativeToLegacy() }
        function onBluetoothCommandChanged(): void { root.pushNativeToLegacy() }
        function onTaskManagerCommandChanged(): void { root.pushNativeToLegacy() }
        function onChangePasswordCommandChanged(): void { root.pushNativeToLegacy() }
        function onQuickSliderBrightnessChanged(): void { root.pushNativeToLegacy() }
        function onQuickSliderVolumeChanged(): void { root.pushNativeToLegacy() }
        function onQuickSliderMicChanged(): void { root.pushNativeToLegacy() }
    }

    Connections {
        target: RaohaneState
        function onWallpaperSelectorOpenChanged(): void { root.pushNativeTransientState() }
        function onWallpaperSelectorTargetChanged(): void { root.pushNativeTransientState() }
        function onOverviewOpenChanged(): void { root.pushNativeTransientState() }
    }

    Connections {
        target: Config
        function onReadyChanged(): void {
            if (Config.ready)
                root.seedNativeFromLegacy()
        }
    }

    Connections {
        target: Config.options?.background ?? null
        function onWallpaperPathChanged(): void { root.pullLegacyWallpaper() }
        function onLockWallChanged(): void { root.pullLegacyWallpaper() }
        function onEnableWallpaperPreviewChanged(): void { root.pullLegacyWallpaper() }
        function onHideWhenFullscreenChanged(): void { root.pullLegacyWallpaper() }
    }

    Connections {
        target: Config.options?.wallpaperSelector ?? null
        function onColumnsChanged(): void { root.pullLegacyWallpaperSelector() }
        function onChangeIntervalChanged(): void { root.pullLegacyWallpaperSelector() }
    }

    Connections {
        target: Config.options?.overview ?? null
        function onColumnsChanged(): void { root.pullLegacyOverview() }
        function onRowsChanged(): void { root.pullLegacyOverview() }
    }

    Connections {
        target: Config.options?.dock ?? null
        function onEnableChanged(): void { root.pullLegacyDock() }
        function onHoverToRevealChanged(): void { root.pullLegacyDock() }
        function onPinnedOnStartupChanged(): void { root.pullLegacyDock() }
        function onHeightChanged(): void { root.pullLegacyDock() }
        function onPinnedAppsChanged(): void { root.pullLegacyDock() }
    }

    Connections {
        target: Config.options?.bar ?? null
        function onBottomChanged(): void { root.pullLegacyShellChrome() }
    }

    Connections {
        target: Config.options?.osd ?? null
        function onTimeoutChanged(): void { root.pullLegacyShellChrome() }
    }

    Connections {
        target: Config.options?.sidebar?.quickSliders ?? null
        function onShowBrightnessChanged(): void { root.pullLegacyShellChrome() }
        function onShowVolumeChanged(): void { root.pullLegacyShellChrome() }
        function onShowMicChanged(): void { root.pullLegacyShellChrome() }
    }

    Connections {
        target: Config.options?.light?.night ?? null
        function onColorTemperatureChanged(): void { root.pullLegacyDisplay() }
        function onAutomaticChanged(): void { root.pullLegacyDisplay() }
    }

    Connections {
        target: Config.options?.apps ?? null
        function onNetworkChanged(): void { root.pullLegacyApps() }
        function onNetworkEthernetChanged(): void { root.pullLegacyApps() }
        function onBluetoothChanged(): void { root.pullLegacyApps() }
        function onTaskManagerChanged(): void { root.pullLegacyApps() }
        function onChangePasswordChanged(): void { root.pullLegacyApps() }
    }

    Connections {
        target: GlobalStates
        function onWallpaperSelectorOpenChanged(): void { root.pullLegacyTransientState() }
        function onWallpaperSelectorTargetChanged(): void { root.pullLegacyTransientState() }
        function onOverviewOpenChanged(): void { root.pullLegacyTransientState() }
    }

    Component.onCompleted: {
        root.seedNativeFromLegacy()
        root.pullLegacyTransientState()
    }
}
