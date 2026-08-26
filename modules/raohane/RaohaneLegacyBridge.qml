pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs
import qs.modules.raohane.config

Singleton {
    id: root

    property bool syncing: false
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

    Connections {
        target: RaohaneConfig
        function onReloaded(): void { root.seedNativeFromLegacy() }
        function onWallpaperPathChanged(): void { root.pushNativeToLegacy() }
        function onLockWallpaperPathChanged(): void { root.pushNativeToLegacy() }
        function onWallpaperPreviewChanged(): void { root.pushNativeToLegacy() }
        function onWallpaperHideWhenFullscreenChanged(): void { root.pushNativeToLegacy() }
        function onWallpaperColumnsChanged(): void { root.pushNativeToLegacy() }
        function onWallpaperChangeIntervalChanged(): void { root.pushNativeToLegacy() }
        function onColorTemperatureChanged(): void { root.pushNativeToLegacy() }
        function onTaskManagerCommandChanged(): void { root.pushNativeToLegacy() }
        function onChangePasswordCommandChanged(): void { root.pushNativeToLegacy() }
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
        target: Config.options?.light?.night ?? null
        function onColorTemperatureChanged(): void { root.pullLegacyDisplay() }
    }

    Connections {
        target: Config.options?.apps ?? null
        function onTaskManagerChanged(): void { root.pullLegacyApps() }
        function onChangePasswordChanged(): void { root.pullLegacyApps() }
    }

    Component.onCompleted: root.seedNativeFromLegacy()
}
