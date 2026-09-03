pragma Singleton

import QtQuick

// Single source of truth for Raohane shell surfaces.
//
// The registry deliberately describes product semantics rather than concrete
// QML instances. RaohaneState owns ephemeral values, while individual surface
// components remain responsible for their presentation and compositor-facing
// window geometry. Surface lifetime is declarative: `resident` surfaces stay
// instantiated for global entrypoints, while `on-demand` surfaces exist only
// while their state is open.
QtObject {
    id: root

    readonly property var definitions: ({
        "launcher": {
            stateProperty: "launcherOpen",
            kind: "primary",
            component: "RaohaneLauncher",
            role: "launcher",
            layer: "overlay",
            placement: "center",
            loadPolicy: "resident"
        },
        "wallpaper": {
            stateProperty: "wallpaperSelectorOpen",
            kind: "primary",
            component: "RaohaneWallpaperSelector",
            role: "picker",
            layer: "overlay",
            placement: "fill",
            loadPolicy: "resident"
        },
        "overview": {
            stateProperty: "overviewOpen",
            kind: "primary",
            component: "RaohaneOverview",
            role: "overview",
            layer: "overlay",
            placement: "fill",
            loadPolicy: "resident"
        },
        "controlCenter": {
            stateProperty: "controlCenterOpen",
            kind: "primary",
            component: "RaohaneControlCenter",
            role: "system-panel",
            layer: "overlay",
            placement: "bar-adjacent",
            loadPolicy: "resident"
        },
        "leftSidebar": {
            stateProperty: "leftSidebarOpen",
            kind: "primary",
            component: "RaohaneSidebarLeft",
            role: "sidebar",
            layer: "overlay",
            placement: "left",
            loadPolicy: "resident"
        },
        "overlay": {
            stateProperty: "overlayOpen",
            kind: "primary",
            component: "RaohaneOverlay",
            role: "overlay",
            layer: "overlay",
            placement: "fill",
            loadPolicy: "resident"
        },
        "screenTranslator": {
            stateProperty: "screenTranslatorOpen",
            kind: "primary",
            component: "RaohaneScreenTranslator",
            role: "tool",
            layer: "overlay",
            placement: "fill",
            loadPolicy: "resident"
        },
        "settings": {
            stateProperty: "settingsOpen",
            kind: "primary",
            component: "RaohaneSettings",
            role: "settings",
            layer: "overlay",
            placement: "center",
            loadPolicy: "resident"
        },
        "displaySettings": {
            stateProperty: "displaySettingsOpen",
            kind: "primary",
            component: "RaohaneDisplaySettings",
            role: "settings",
            layer: "overlay",
            placement: "center",
            loadPolicy: "on-demand"
        },
        "welcome": {
            stateProperty: "welcomeOpen",
            kind: "primary",
            component: "RaohaneWelcome",
            role: "onboarding",
            layer: "overlay",
            placement: "center",
            loadPolicy: "on-demand"
        },
        "session": {
            stateProperty: "sessionOpen",
            kind: "primary",
            component: "RaohaneSessionScreen",
            role: "session",
            layer: "overlay",
            placement: "fill",
            loadPolicy: "resident"
        },
        "taskManager": {
            stateProperty: "taskManagerOpen",
            kind: "primary",
            component: "RaohaneTaskManager",
            role: "system-tool",
            layer: "overlay",
            placement: "center",
            loadPolicy: "resident"
        },
        "desktopMenu": {
            stateProperty: "desktopMenuOpen",
            kind: "primary",
            component: "RaohaneDesktopMenu",
            role: "context-menu",
            layer: "overlay",
            placement: "pointer",
            loadPolicy: "resident"
        },
        "mediaOverlay": {
            stateProperty: "mediaOverlayOpen",
            kind: "transient",
            component: "RaohaneMediaOverlay",
            role: "media",
            layer: "overlay",
            placement: "contextual",
            loadPolicy: "resident",
            closePrimaryOnOpen: false
        },
        "regionSelector": {
            stateProperty: "regionSelectorOpen",
            kind: "transient",
            component: "RaohaneRegionSelector",
            role: "capture",
            layer: "overlay",
            placement: "fill",
            loadPolicy: "resident",
            closePrimaryOnOpen: true
        },
        "osk": {
            stateProperty: "oskOpen",
            kind: "transient",
            component: "RaohaneOnScreenKeyboard",
            role: "input",
            layer: "overlay",
            placement: "bottom",
            loadPolicy: "resident",
            closePrimaryOnOpen: false
        },
        "osd": {
            stateProperty: "osdOpen",
            kind: "transient",
            component: "RaohaneOsd",
            role: "osd",
            layer: "overlay",
            placement: "contextual",
            loadPolicy: "resident",
            closePrimaryOnOpen: false
        }
    })

    readonly property var primarySurfaceIds: [
        "launcher",
        "wallpaper",
        "overview",
        "controlCenter",
        "leftSidebar",
        "overlay",
        "screenTranslator",
        "settings",
        "displaySettings",
        "welcome",
        "session",
        "taskManager",
        "desktopMenu"
    ]

    readonly property var transientSurfaceIds: [
        "mediaOverlay",
        "regionSelector",
        "osk",
        "osd"
    ]

    readonly property var actionAliases: ({
        "sidebarLeftOpen": "leftSidebar",
        "sidebarRightOpen": "controlCenter",
        "overviewOpen": "overview",
        "wallpaperSelectorOpen": "wallpaper",
        "mediaOverlayOpen": "mediaOverlay",
        "mediaControlsOpen": "mediaOverlay",
        "overlayOpen": "overlay",
        "regionSelectorOpen": "regionSelector",
        "screenTranslatorOpen": "screenTranslator",
        "oskOpen": "osk",
        "sessionOpen": "session",
        "taskManagerOpen": "taskManager",
        "desktopMenuOpen": "desktopMenu"
    })

    function normalizeId(value: string): string {
        if (!value)
            return ""
        if (root.definitions[value] !== undefined)
            return value
        return root.actionAliases[value] ?? ""
    }

    function definition(value: string): var {
        const id = root.normalizeId(value)
        if (!id)
            return null
        return root.definitions[id] ?? null
    }

    function stateProperty(value: string): string {
        const metadata = root.definition(value)
        return metadata && metadata.stateProperty ? metadata.stateProperty : ""
    }

    function isPrimary(value: string): bool {
        const metadata = root.definition(value)
        return !!metadata && metadata.kind === "primary"
    }

    function isTransient(value: string): bool {
        const metadata = root.definition(value)
        return !!metadata && metadata.kind === "transient"
    }

    function isKnown(value: string): bool {
        return root.definition(value) !== null
    }
}
