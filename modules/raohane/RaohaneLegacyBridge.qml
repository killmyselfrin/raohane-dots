pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs
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

        RaohaneConfig.colorTemperature = Config.options?.light?.night?.colorTemperature ?? RaohaneConfig.colorTemperature

        if (RaohaneConfig.taskManagerCommand.length === 0)
            RaohaneConfig.taskManagerCommand = Config.options?.apps?.taskManager ?? ""
        if (RaohaneConfig.changePasswordCommand === "passwd") {
            const legacyCommand = Config.options?.apps?.changePassword ?? ""
            if (legacyCommand.length > 0)
                RaohaneConfig.changePasswordCommand = legacyCommand
        }

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
        if (Config.options?.light?.night)
            Config.options.light.night.colorTemperature = RaohaneConfig.colorTemperature
        if (Config.options?.apps) {
            if (RaohaneConfig.taskManagerCommand.length > 0)
                Config.options.apps.taskManager = RaohaneConfig.taskManagerCommand
            if (RaohaneConfig.changePasswordCommand.length > 0)
                Config.options.apps.changePassword = RaohaneConfig.changePasswordCommand
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

    function pullLegacyDisplay(): void {
        if (root.syncing || !RaohaneConfig.ready)
            return
        root.syncing = true
        RaohaneConfig.colorTemperature = Config.options?.light?.night?.colorTemperature ?? 5000
        root.syncing = false
    }

    function pullLegacyApps(): void {
        if (root.syncing || !RaohaneConfig.ready)
            return
        root.syncing = true
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
        function onColorTemperatureChanged(): void { root.pushNativeToLegacy() }
        function onTaskManagerCommandChanged(): void { root.pushNativeToLegacy() }
        function onChangePasswordCommandChanged(): void { root.pushNativeToLegacy() }
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
        target: Config.options?.light?.night ?? null
        function onColorTemperatureChanged(): void { root.pullLegacyDisplay() }
    }

    Connections {
        target: Config.options?.apps ?? null
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
