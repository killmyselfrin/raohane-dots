pragma Singleton
pragma ComponentBehavior: Bound

import QtCore
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property int schemaVersion: 1
    readonly property string configDirectory: root.cleanPath(StandardPaths.standardLocations(StandardPaths.ConfigLocation)[0] ?? "") + "/raohane"
    readonly property string filePath: configDirectory + "/native.json"

    property bool ready: false
    property bool loading: false

    // Raohane-owned settings. Compatibility settings remain in Config.qml
    // until their corresponding UI/backend boundary is migrated.
    property string wallpaperPath: ""
    property string lockWallpaperPath: ""
    property string wallpaperDirectory: ""
    property bool wallpaperPreview: true
    property int wallpaperColumns: 4
    property int wallpaperChangeInterval: 0

    property int colorTemperature: 5000

    property string taskManagerCommand: ""
    property string changePasswordCommand: "passwd"

    property bool contextIslandEnabled: true
    property bool mediaOverlayEnabled: true
    property bool integrationMode: true

    signal reloaded()
    signal saved()

    function cleanPath(value): string {
        if (value === null || value === undefined)
            return ""
        let path = value.toString()
        if (path.startsWith("file://"))
            path = path.substring(7)
        try {
            return decodeURIComponent(path)
        } catch (error) {
            return path
        }
    }

    function snapshot(): var {
        return {
            schemaVersion: root.schemaVersion,
            wallpaper: {
                path: root.wallpaperPath,
                lockPath: root.lockWallpaperPath,
                directory: root.wallpaperDirectory,
                preview: root.wallpaperPreview,
                columns: root.wallpaperColumns,
                changeInterval: root.wallpaperChangeInterval
            },
            display: {
                colorTemperature: root.colorTemperature
            },
            apps: {
                taskManager: root.taskManagerCommand,
                changePassword: root.changePasswordCommand
            },
            features: {
                contextIsland: root.contextIslandEnabled,
                mediaOverlay: root.mediaOverlayEnabled,
                integrationMode: root.integrationMode
            }
        }
    }

    function assignIfPresent(object, key, setter): void {
        if (object && Object.prototype.hasOwnProperty.call(object, key))
            setter(object[key])
    }

    function applyDocument(document): void {
        root.loading = true

        const wallpaper = document?.wallpaper ?? {}
        const display = document?.display ?? {}
        const apps = document?.apps ?? {}
        const features = document?.features ?? {}

        root.assignIfPresent(wallpaper, "path", value => root.wallpaperPath = String(value ?? ""))
        root.assignIfPresent(wallpaper, "lockPath", value => root.lockWallpaperPath = String(value ?? ""))
        root.assignIfPresent(wallpaper, "directory", value => root.wallpaperDirectory = String(value ?? ""))
        root.assignIfPresent(wallpaper, "preview", value => root.wallpaperPreview = Boolean(value))
        root.assignIfPresent(wallpaper, "columns", value => root.wallpaperColumns = Math.max(2, Math.min(8, Number(value) || 4)))
        root.assignIfPresent(wallpaper, "changeInterval", value => root.wallpaperChangeInterval = Math.max(0, Number(value) || 0))

        root.assignIfPresent(display, "colorTemperature", value => root.colorTemperature = Math.max(1000, Math.min(10000, Number(value) || 5000)))

        root.assignIfPresent(apps, "taskManager", value => root.taskManagerCommand = String(value ?? ""))
        root.assignIfPresent(apps, "changePassword", value => root.changePasswordCommand = String(value ?? "passwd"))

        root.assignIfPresent(features, "contextIsland", value => root.contextIslandEnabled = Boolean(value))
        root.assignIfPresent(features, "mediaOverlay", value => root.mediaOverlayEnabled = Boolean(value))
        root.assignIfPresent(features, "integrationMode", value => root.integrationMode = Boolean(value))

        root.loading = false
        root.ready = true
        root.reloaded()
    }

    function parseAndApply(text: string): void {
        try {
            const parsed = JSON.parse(text)
            if (parsed && typeof parsed === "object") {
                root.applyDocument(parsed)
                return
            }
        } catch (error) {
            console.warn("[RaohaneConfig] Invalid native config, keeping defaults:", error)
        }

        root.ready = true
        root.scheduleSave()
    }

    function scheduleSave(): void {
        if (!root.loading && root.ready)
            saveTimer.restart()
    }

    function saveNow(): void {
        Quickshell.execDetached(["mkdir", "-p", root.configDirectory])
        configFile.setText(JSON.stringify(root.snapshot(), null, 2) + "\n")
        root.saved()
    }

    onWallpaperPathChanged: scheduleSave()
    onLockWallpaperPathChanged: scheduleSave()
    onWallpaperDirectoryChanged: scheduleSave()
    onWallpaperPreviewChanged: scheduleSave()
    onWallpaperColumnsChanged: scheduleSave()
    onWallpaperChangeIntervalChanged: scheduleSave()
    onColorTemperatureChanged: scheduleSave()
    onTaskManagerCommandChanged: scheduleSave()
    onChangePasswordCommandChanged: scheduleSave()
    onContextIslandEnabledChanged: scheduleSave()
    onMediaOverlayEnabledChanged: scheduleSave()
    onIntegrationModeChanged: scheduleSave()

    Timer {
        id: saveTimer
        interval: 120
        repeat: false
        onTriggered: root.saveNow()
    }

    Timer {
        id: initialLoadTimer
        interval: 60
        repeat: false
        onTriggered: configFile.reload()
    }

    FileView {
        id: configFile
        path: root.filePath
        watchChanges: true

        onLoaded: root.parseAndApply(configFile.text())
        onFileChanged: initialLoadTimer.restart()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                root.ready = true
                root.saveNow()
            } else {
                console.warn("[RaohaneConfig] Failed to load native config:", error)
                root.ready = true
            }
        }
    }

    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", root.configDirectory])
        initialLoadTimer.start()
    }
}
