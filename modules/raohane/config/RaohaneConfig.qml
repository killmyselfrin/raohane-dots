pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property int schemaVersion: 11
    readonly property string configDirectory: RaohanePaths.configDirectory
    readonly property string filePath: RaohanePaths.nativeConfigFile

    property bool ready: false
    property bool loading: false
    property bool pendingInitialWrite: false

    property string wallpaperPath: ""
    property string lockWallpaperPath: ""
    property string wallpaperDirectory: ""
    property bool wallpaperPreview: true
    property int wallpaperColumns: 4
    property int wallpaperChangeInterval: 0
    property bool wallpaperHideWhenFullscreen: true
    property int wallpaperTransitionDuration: 650
    property real wallpaperDim: 0.06
    property real lockWallpaperDim: 0.28

    property int overviewWorkspaceCount: 6
    property int overviewColumns: 3

    property bool dockEnabled: true
    property bool dockAutoHide: true
    property bool dockPinned: false
    property bool dockExclusiveZone: false
    property int dockHeight: 68
    property int dockIconSize: 42
    property int dockBottomMargin: 9
    property var dockPinnedApps: []

    property bool barBottom: false
    property bool barVertical: false
    property bool barAutoHide: false
    property bool barAutoHidePushWindows: true
    property bool barShowOnSuper: false
    property int barShowOnSuperDelay: 140
    property var barScreenList: []
    property bool barShowDate: true

    property bool frameEnabled: false
    property int frameThickness: 4
    property string frameColor: "#000000"
    property bool frameBarSideVisible: true

    property int screenRoundingMode: 0
    property int screenCornerRadius: 22
    property bool deadPixelWorkaround: false
    property bool hotCornersEnabled: true
    property bool hotCornerValueScroll: true
    property bool hotCornerClickless: false
    property int hotCornerRegionWidth: 250
    property int hotCornerRegionHeight: 5
    property string hotCornerBottomLeftAction: "sidebarLeftOpen"
    property string hotCornerBottomRightAction: "sidebarRightOpen"
    property bool hotCornerVisualize: false
    property bool hotCornerClicklessEnd: true
    property int hotCornerVerticalOffset: 1

    property bool oskPinned: false
    property string oskLayout: "English (US)"

    property int osdTimeout: 1000

    property int colorTemperature: 5000
    property bool nightLightAutomatic: true

    property string networkCommand: "nm-connection-editor"
    property string networkEthernetCommand: "nm-connection-editor"
    property string bluetoothCommand: "blueman-manager"
    property string taskManagerCommand: ""
    property string changePasswordCommand: "passwd"

    property string profileDisplayName: ""
    property string profileAvatarPath: ""

    property bool quickSliderBrightness: true
    property bool quickSliderVolume: true
    property bool quickSliderMic: false

    property bool contextIslandEnabled: true
    property bool mediaOverlayEnabled: true
    property bool integrationMode: true
    property string themePreset: "zen-mist"
    property bool welcomeCompleted: false
    property var desktopWidgets: root.defaultDesktopWidgets()

    // Style Studio is persisted as one object so new visual controls can be
    // added without scattering a separate save signal across the config API.
    property var style: ({
        glassOpacity: 1.0,
        borderStrength: 1.0,
        radiusScale: 1.0,
        densityScale: 1.0,
        motionScale: 1.0,
        accentStrength: 1.0,
        accentMode: "theme",
        customAccent: "#657987",
        sheenEnabled: true,
        barScale: 1.0,
        dockHoverScale: 1.04,
        contextIslandScale: 1.0,
        contextIslandDetail: true,
        contextIslandIndicators: true,
        notificationScale: 1.0,
        notificationCompact: false,
        notificationBodyLines: 4
    })

    signal reloaded()
    signal saved()

    function defaultDesktopWidgets(): var {
        return [
            { id: "clock", type: "clock", screen: "", x: 0.045, y: 0.12 },
            { id: "context", type: "context", screen: "", x: 0.045, y: 0.46 }
        ]
    }

    function sanitizeDesktopWidgets(value): var {
        const input = Array.isArray(value) ? value : root.defaultDesktopWidgets()
        const allowedTypes = ["clock", "context", "media", "system"]
        const seen = {}
        const result = []
        for (let index = 0; index < input.length; index++) {
            const raw = input[index] && typeof input[index] === "object" ? input[index] : {}
            const type = String(raw.type ?? "")
            if (allowedTypes.indexOf(type) < 0)
                continue
            let id = String(raw.id ?? (type + "-" + index)).replace(/[^a-zA-Z0-9_-]/g, "-")
            if (id.length === 0)
                id = type + "-" + index
            while (seen[id])
                id += "-copy"
            seen[id] = true
            result.push({
                id: id,
                type: type,
                screen: String(raw.screen ?? ""),
                x: root.clampNumber(raw.x, 0, 0.92, 0.05),
                y: root.clampNumber(raw.y, 0, 0.90, 0.12)
            })
        }
        return result
    }

    function addDesktopWidget(type: string, screenName: string): void {
        const allowedTypes = ["clock", "context", "media", "system"]
        if (allowedTypes.indexOf(type) < 0)
            return
        const items = root.sanitizeDesktopWidgets(root.desktopWidgets).slice()
        const id = type + "-" + Date.now()
        const offset = Math.min(0.32, items.length * 0.035)
        items.push({ id: id, type: type, screen: String(screenName ?? ""), x: 0.08 + offset, y: 0.14 + offset })
        root.desktopWidgets = items
    }

    function removeDesktopWidget(id: string): void {
        root.desktopWidgets = root.sanitizeDesktopWidgets(root.desktopWidgets).filter(item => item.id !== id)
    }

    function moveDesktopWidget(id: string, x: real, y: real, screenName: string): void {
        const items = root.sanitizeDesktopWidgets(root.desktopWidgets).map(item => item.id === id ? {
            id: item.id,
            type: item.type,
            screen: String(screenName ?? item.screen),
            x: root.clampNumber(x, 0, 0.92, item.x),
            y: root.clampNumber(y, 0, 0.90, item.y)
        } : item)
        root.desktopWidgets = items
    }

    function resetDesktopWidgets(): void {
        root.desktopWidgets = root.defaultDesktopWidgets()
    }

    function defaultStyle(): var {
        return {
            glassOpacity: 1.0,
            borderStrength: 1.0,
            radiusScale: 1.0,
            densityScale: 1.0,
            motionScale: 1.0,
            accentStrength: 1.0,
            accentMode: "theme",
            customAccent: "#657987",
            sheenEnabled: true,
            barScale: 1.0,
            dockHoverScale: 1.04,
            contextIslandScale: 1.0,
            contextIslandDetail: true,
            contextIslandIndicators: true,
            notificationScale: 1.0,
            notificationCompact: false,
            notificationBodyLines: 4
        }
    }

    function clampNumber(value, minimum, maximum, fallback): real {
        const number = Number(value)
        if (isNaN(number))
            return fallback
        return Math.max(minimum, Math.min(maximum, number))
    }

    function sanitizeStyle(value): var {
        const input = value && typeof value === "object" ? value : {}
        const allowedModes = ["theme", "ink", "sakura", "matcha", "slate", "sand", "custom"]
        const requestedMode = String(input.accentMode ?? "theme")
        const requestedAccent = String(input.customAccent ?? "#657987")
        return {
            glassOpacity: root.clampNumber(input.glassOpacity, 0.55, 1.0, 1.0),
            borderStrength: root.clampNumber(input.borderStrength, 0.45, 1.5, 1.0),
            radiusScale: root.clampNumber(input.radiusScale, 0.7, 1.4, 1.0),
            densityScale: root.clampNumber(input.densityScale, 0.82, 1.18, 1.0),
            motionScale: root.clampNumber(input.motionScale, 0.0, 1.4, 1.0),
            accentStrength: root.clampNumber(input.accentStrength, 0.45, 1.5, 1.0),
            accentMode: allowedModes.indexOf(requestedMode) >= 0 ? requestedMode : "theme",
            customAccent: /^#[0-9a-fA-F]{6}$/.test(requestedAccent) ? requestedAccent : "#657987",
            sheenEnabled: input.sheenEnabled === undefined ? true : Boolean(input.sheenEnabled),
            barScale: root.clampNumber(input.barScale, 0.85, 1.15, 1.0),
            dockHoverScale: root.clampNumber(input.dockHoverScale, 1.0, 1.12, 1.04),
            contextIslandScale: root.clampNumber(input.contextIslandScale, 0.8, 1.25, 1.0),
            contextIslandDetail: input.contextIslandDetail === undefined ? true : Boolean(input.contextIslandDetail),
            contextIslandIndicators: input.contextIslandIndicators === undefined ? true : Boolean(input.contextIslandIndicators),
            notificationScale: root.clampNumber(input.notificationScale, 0.85, 1.15, 1.0),
            notificationCompact: input.notificationCompact === undefined ? false : Boolean(input.notificationCompact),
            notificationBodyLines: Math.round(root.clampNumber(input.notificationBodyLines, 1, 6, 4))
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
                changeInterval: root.wallpaperChangeInterval,
                hideWhenFullscreen: root.wallpaperHideWhenFullscreen,
                transitionDuration: root.wallpaperTransitionDuration,
                dim: root.wallpaperDim,
                lockDim: root.lockWallpaperDim
            },
            overview: {
                workspaceCount: root.overviewWorkspaceCount,
                columns: root.overviewColumns
            },
            dock: {
                enabled: root.dockEnabled,
                autoHide: root.dockAutoHide,
                pinned: root.dockPinned,
                exclusiveZone: root.dockExclusiveZone,
                height: root.dockHeight,
                iconSize: root.dockIconSize,
                bottomMargin: root.dockBottomMargin,
                pinnedApps: root.dockPinnedApps
            },
            bar: {
                bottom: root.barBottom,
                vertical: root.barVertical,
                autoHide: root.barAutoHide,
                autoHidePushWindows: root.barAutoHidePushWindows,
                showOnSuper: root.barShowOnSuper,
                showOnSuperDelay: root.barShowOnSuperDelay,
                screenList: root.barScreenList,
                showDate: root.barShowDate
            },
            frame: {
                enabled: root.frameEnabled,
                thickness: root.frameThickness,
                color: root.frameColor,
                barSideVisible: root.frameBarSideVisible
            },
            corners: {
                roundingMode: root.screenRoundingMode,
                radius: root.screenCornerRadius,
                deadPixelWorkaround: root.deadPixelWorkaround,
                enabled: root.hotCornersEnabled,
                valueScroll: root.hotCornerValueScroll,
                clickless: root.hotCornerClickless,
                regionWidth: root.hotCornerRegionWidth,
                regionHeight: root.hotCornerRegionHeight,
                bottomLeftAction: root.hotCornerBottomLeftAction,
                bottomRightAction: root.hotCornerBottomRightAction,
                visualize: root.hotCornerVisualize,
                clicklessEnd: root.hotCornerClicklessEnd,
                verticalOffset: root.hotCornerVerticalOffset
            },
            osk: {
                pinned: root.oskPinned,
                layout: root.oskLayout
            },
            osd: {
                timeout: root.osdTimeout
            },
            display: {
                colorTemperature: root.colorTemperature,
                nightAutomatic: root.nightLightAutomatic
            },
            apps: {
                network: root.networkCommand,
                networkEthernet: root.networkEthernetCommand,
                bluetooth: root.bluetoothCommand,
                taskManager: root.taskManagerCommand,
                changePassword: root.changePasswordCommand
            },
            profile: {
                displayName: root.profileDisplayName,
                avatarPath: root.profileAvatarPath
            },
            quickControls: {
                showBrightness: root.quickSliderBrightness,
                showVolume: root.quickSliderVolume,
                showMic: root.quickSliderMic
            },
            features: {
                contextIsland: root.contextIslandEnabled,
                mediaOverlay: root.mediaOverlayEnabled,
                integrationMode: root.integrationMode,
                themePreset: root.themePreset,
                welcomeCompleted: root.welcomeCompleted
            },
            desktop: {
                widgets: root.sanitizeDesktopWidgets(root.desktopWidgets)
            },
            style: root.sanitizeStyle(root.style)
        }
    }

    function assignIfPresent(object, key, setter): void {
        if (object && Object.prototype.hasOwnProperty.call(object, key))
            setter(object[key])
    }

    function applyDocument(document): void {
        root.loading = true

        const wallpaper = document?.wallpaper ?? {}
        const overview = document?.overview ?? {}
        const dock = document?.dock ?? {}
        const bar = document?.bar ?? {}
        const frame = document?.frame ?? {}
        const corners = document?.corners ?? {}
        const osk = document?.osk ?? {}
        const osd = document?.osd ?? {}
        const display = document?.display ?? {}
        const apps = document?.apps ?? {}
        const profile = document?.profile ?? {}
        const quickControls = document?.quickControls ?? {}
        const features = document?.features ?? {}
        const desktop = document?.desktop ?? {}
        const style = document?.style ?? root.defaultStyle()

        root.assignIfPresent(wallpaper, "path", value => root.wallpaperPath = String(value ?? ""))
        root.assignIfPresent(wallpaper, "lockPath", value => root.lockWallpaperPath = String(value ?? ""))
        root.assignIfPresent(wallpaper, "directory", value => root.wallpaperDirectory = String(value ?? ""))
        root.assignIfPresent(wallpaper, "preview", value => root.wallpaperPreview = Boolean(value))
        root.assignIfPresent(wallpaper, "columns", value => root.wallpaperColumns = Math.max(2, Math.min(8, Number(value) || 4)))
        root.assignIfPresent(wallpaper, "changeInterval", value => root.wallpaperChangeInterval = Math.max(0, Number(value) || 0))
        root.assignIfPresent(wallpaper, "hideWhenFullscreen", value => root.wallpaperHideWhenFullscreen = Boolean(value))
        root.assignIfPresent(wallpaper, "transitionDuration", value => root.wallpaperTransitionDuration = Math.max(0, Math.min(3000, Number(value) || 650)))
        root.assignIfPresent(wallpaper, "dim", value => root.wallpaperDim = Math.max(0, Math.min(0.8, Number(value) || 0)))
        root.assignIfPresent(wallpaper, "lockDim", value => root.lockWallpaperDim = Math.max(0, Math.min(0.9, Number(value) || 0)))

        root.assignIfPresent(overview, "workspaceCount", value => root.overviewWorkspaceCount = Math.max(2, Math.min(12, Number(value) || 6)))
        root.assignIfPresent(overview, "columns", value => root.overviewColumns = Math.max(1, Math.min(4, Number(value) || 3)))

        root.assignIfPresent(dock, "enabled", value => root.dockEnabled = Boolean(value))
        root.assignIfPresent(dock, "autoHide", value => root.dockAutoHide = Boolean(value))
        root.assignIfPresent(dock, "pinned", value => root.dockPinned = Boolean(value))
        root.assignIfPresent(dock, "exclusiveZone", value => root.dockExclusiveZone = Boolean(value))
        root.assignIfPresent(dock, "height", value => root.dockHeight = Math.max(48, Math.min(120, Number(value) || 68)))
        root.assignIfPresent(dock, "iconSize", value => root.dockIconSize = Math.max(26, Math.min(72, Number(value) || 42)))
        root.assignIfPresent(dock, "bottomMargin", value => root.dockBottomMargin = Math.max(0, Math.min(40, Number(value) || 0)))
        root.assignIfPresent(dock, "pinnedApps", value => root.dockPinnedApps = Array.isArray(value) ? value.map(item => String(item)) : [])

        root.assignIfPresent(bar, "bottom", value => root.barBottom = Boolean(value))
        root.assignIfPresent(bar, "vertical", value => root.barVertical = Boolean(value))
        root.assignIfPresent(bar, "autoHide", value => root.barAutoHide = Boolean(value))
        root.assignIfPresent(bar, "autoHidePushWindows", value => root.barAutoHidePushWindows = Boolean(value))
        root.assignIfPresent(bar, "showOnSuper", value => root.barShowOnSuper = Boolean(value))
        root.assignIfPresent(bar, "showOnSuperDelay", value => root.barShowOnSuperDelay = Math.max(0, Math.min(2000, Number(value) || 140)))
        root.assignIfPresent(bar, "screenList", value => root.barScreenList = Array.isArray(value) ? value.map(item => String(item)) : [])
        root.assignIfPresent(bar, "showDate", value => root.barShowDate = Boolean(value))

        root.assignIfPresent(frame, "enabled", value => root.frameEnabled = Boolean(value))
        root.assignIfPresent(frame, "thickness", value => root.frameThickness = Math.max(1, Math.min(24, Number(value) || 4)))
        root.assignIfPresent(frame, "color", value => root.frameColor = String(value || "#000000"))
        root.assignIfPresent(frame, "barSideVisible", value => root.frameBarSideVisible = Boolean(value))

        root.assignIfPresent(corners, "roundingMode", value => root.screenRoundingMode = Math.max(0, Math.min(2, Number(value) || 0)))
        root.assignIfPresent(corners, "radius", value => root.screenCornerRadius = Math.max(6, Math.min(96, Number(value) || 22)))
        root.assignIfPresent(corners, "deadPixelWorkaround", value => root.deadPixelWorkaround = Boolean(value))
        root.assignIfPresent(corners, "enabled", value => root.hotCornersEnabled = Boolean(value))
        root.assignIfPresent(corners, "valueScroll", value => root.hotCornerValueScroll = Boolean(value))
        root.assignIfPresent(corners, "clickless", value => root.hotCornerClickless = Boolean(value))
        root.assignIfPresent(corners, "regionWidth", value => root.hotCornerRegionWidth = Math.max(12, Math.min(600, Number(value) || 250)))
        root.assignIfPresent(corners, "regionHeight", value => root.hotCornerRegionHeight = Math.max(2, Math.min(80, Number(value) || 5)))
        root.assignIfPresent(corners, "bottomLeftAction", value => root.hotCornerBottomLeftAction = String(value ?? "sidebarLeftOpen"))
        root.assignIfPresent(corners, "bottomRightAction", value => root.hotCornerBottomRightAction = String(value ?? "sidebarRightOpen"))
        root.assignIfPresent(corners, "visualize", value => root.hotCornerVisualize = Boolean(value))
        root.assignIfPresent(corners, "clicklessEnd", value => root.hotCornerClicklessEnd = Boolean(value))
        root.assignIfPresent(corners, "verticalOffset", value => root.hotCornerVerticalOffset = Math.max(0, Math.min(40, Number(value) || 0)))

        root.assignIfPresent(osk, "pinned", value => root.oskPinned = Boolean(value))
        root.assignIfPresent(osk, "layout", value => root.oskLayout = String(value || "English (US)"))

        root.assignIfPresent(osd, "timeout", value => root.osdTimeout = Math.max(250, Math.min(10000, Number(value) || 1000)))

        root.assignIfPresent(display, "colorTemperature", value => root.colorTemperature = Math.max(1000, Math.min(10000, Number(value) || 5000)))
        root.assignIfPresent(display, "nightAutomatic", value => root.nightLightAutomatic = Boolean(value))

        root.assignIfPresent(apps, "network", value => root.networkCommand = String(value ?? ""))
        root.assignIfPresent(apps, "networkEthernet", value => root.networkEthernetCommand = String(value ?? ""))
        root.assignIfPresent(apps, "bluetooth", value => root.bluetoothCommand = String(value ?? ""))
        root.assignIfPresent(apps, "taskManager", value => root.taskManagerCommand = String(value ?? ""))
        root.assignIfPresent(apps, "changePassword", value => root.changePasswordCommand = String(value ?? "passwd"))

        root.assignIfPresent(profile, "displayName", value => root.profileDisplayName = String(value ?? ""))
        root.assignIfPresent(profile, "avatarPath", value => root.profileAvatarPath = String(value ?? ""))

        root.assignIfPresent(quickControls, "showBrightness", value => root.quickSliderBrightness = Boolean(value))
        root.assignIfPresent(quickControls, "showVolume", value => root.quickSliderVolume = Boolean(value))
        root.assignIfPresent(quickControls, "showMic", value => root.quickSliderMic = Boolean(value))

        root.assignIfPresent(features, "contextIsland", value => root.contextIslandEnabled = Boolean(value))
        root.assignIfPresent(features, "mediaOverlay", value => root.mediaOverlayEnabled = Boolean(value))
        root.assignIfPresent(features, "integrationMode", value => root.integrationMode = Boolean(value))
        root.assignIfPresent(features, "themePreset", value => root.themePreset = String(value || "zen-mist"))
        root.assignIfPresent(features, "welcomeCompleted", value => root.welcomeCompleted = Boolean(value))

        root.assignIfPresent(desktop, "widgets", value => root.desktopWidgets = root.sanitizeDesktopWidgets(value))

        root.style = root.sanitizeStyle(style)

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
        configFile.setText(JSON.stringify(root.snapshot(), null, 2) + "\n")
        root.pendingInitialWrite = false
        root.saved()
    }

    onWallpaperPathChanged: scheduleSave()
    onLockWallpaperPathChanged: scheduleSave()
    onWallpaperDirectoryChanged: scheduleSave()
    onWallpaperPreviewChanged: scheduleSave()
    onWallpaperColumnsChanged: scheduleSave()
    onWallpaperChangeIntervalChanged: scheduleSave()
    onWallpaperHideWhenFullscreenChanged: scheduleSave()
    onWallpaperTransitionDurationChanged: scheduleSave()
    onWallpaperDimChanged: scheduleSave()
    onLockWallpaperDimChanged: scheduleSave()
    onOverviewWorkspaceCountChanged: scheduleSave()
    onOverviewColumnsChanged: scheduleSave()
    onDockEnabledChanged: scheduleSave()
    onDockAutoHideChanged: scheduleSave()
    onDockPinnedChanged: scheduleSave()
    onDockExclusiveZoneChanged: scheduleSave()
    onDockHeightChanged: scheduleSave()
    onDockIconSizeChanged: scheduleSave()
    onDockBottomMarginChanged: scheduleSave()
    onDockPinnedAppsChanged: scheduleSave()
    onBarBottomChanged: scheduleSave()
    onBarVerticalChanged: scheduleSave()
    onBarAutoHideChanged: scheduleSave()
    onBarAutoHidePushWindowsChanged: scheduleSave()
    onBarShowOnSuperChanged: scheduleSave()
    onBarShowOnSuperDelayChanged: scheduleSave()
    onBarScreenListChanged: scheduleSave()
    onBarShowDateChanged: scheduleSave()
    onFrameEnabledChanged: scheduleSave()
    onFrameThicknessChanged: scheduleSave()
    onFrameColorChanged: scheduleSave()
    onFrameBarSideVisibleChanged: scheduleSave()
    onScreenRoundingModeChanged: scheduleSave()
    onScreenCornerRadiusChanged: scheduleSave()
    onDeadPixelWorkaroundChanged: scheduleSave()
    onHotCornersEnabledChanged: scheduleSave()
    onHotCornerValueScrollChanged: scheduleSave()
    onHotCornerClicklessChanged: scheduleSave()
    onHotCornerRegionWidthChanged: scheduleSave()
    onHotCornerRegionHeightChanged: scheduleSave()
    onHotCornerBottomLeftActionChanged: scheduleSave()
    onHotCornerBottomRightActionChanged: scheduleSave()
    onHotCornerVisualizeChanged: scheduleSave()
    onHotCornerClicklessEndChanged: scheduleSave()
    onHotCornerVerticalOffsetChanged: scheduleSave()
    onOskPinnedChanged: scheduleSave()
    onOskLayoutChanged: scheduleSave()
    onOsdTimeoutChanged: scheduleSave()
    onColorTemperatureChanged: scheduleSave()
    onNightLightAutomaticChanged: scheduleSave()
    onNetworkCommandChanged: scheduleSave()
    onNetworkEthernetCommandChanged: scheduleSave()
    onBluetoothCommandChanged: scheduleSave()
    onTaskManagerCommandChanged: scheduleSave()
    onChangePasswordCommandChanged: scheduleSave()
    onProfileDisplayNameChanged: scheduleSave()
    onProfileAvatarPathChanged: scheduleSave()
    onQuickSliderBrightnessChanged: scheduleSave()
    onQuickSliderVolumeChanged: scheduleSave()
    onQuickSliderMicChanged: scheduleSave()
    onContextIslandEnabledChanged: scheduleSave()
    onMediaOverlayEnabledChanged: scheduleSave()
    onIntegrationModeChanged: scheduleSave()
    onThemePresetChanged: scheduleSave()
    onWelcomeCompletedChanged: scheduleSave()
    onDesktopWidgetsChanged: scheduleSave()
    onStyleChanged: scheduleSave()

    Timer {
        id: saveTimer
        interval: 120
        repeat: false
        onTriggered: root.saveNow()
    }

    Timer {
        id: reloadTimer
        interval: 80
        repeat: false
        onTriggered: configFile.reload()
    }

    Process {
        id: ensureDirectory
        command: ["mkdir", "-p", root.configDirectory]
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                console.warn("[RaohaneConfig] Could not create config directory")
                root.ready = true
                return
            }
            configFile.reload()
        }
    }

    FileView {
        id: configFile
        path: root.filePath
        watchChanges: true

        onLoaded: root.parseAndApply(configFile.text())
        onFileChanged: reloadTimer.restart()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                root.ready = true
                root.pendingInitialWrite = true
                saveTimer.restart()
            } else {
                console.warn("[RaohaneConfig] Failed to load native config:", error)
                root.ready = true
            }
        }
    }

    Component.onCompleted: ensureDirectory.running = true
}
