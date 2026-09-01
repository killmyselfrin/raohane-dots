pragma Singleton

import QtQuick

// Raohane-owned cross-surface state. All ephemeral product state lives here;
// the active runtime has no legacy global-state bridge.
QtObject {
    property bool launcherOpen: false
    property bool mediaOverlayOpen: false
    property bool wallpaperSelectorOpen: false
    property string wallpaperSelectorTarget: "wallpaper"
    property bool overviewOpen: false

    property bool barOpen: true
    property bool controlCenterOpen: false
    property bool leftSidebarOpen: false
    property bool overlayOpen: false
    property bool regionSelectorOpen: false
    property bool screenTranslatorOpen: false
    property bool oskOpen: false
    property bool settingsOpen: false
    property string settingsPage: ""
    property bool welcomeOpen: false
    property bool sessionOpen: false
    property bool taskManagerOpen: false
    property bool osdOpen: false
    property bool screenLocked: false
    property bool superDown: false

    property bool desktopMenuOpen: false
    property var desktopMenuScreen: null
    property real desktopMenuX: 0
    property real desktopMenuY: 0

    function primaryOpen(name: string): bool {
        switch (name) {
        case "launcher": return launcherOpen
        case "wallpaper": return wallpaperSelectorOpen
        case "overview": return overviewOpen
        case "controlCenter": return controlCenterOpen
        case "leftSidebar": return leftSidebarOpen
        case "overlay": return overlayOpen
        case "screenTranslator": return screenTranslatorOpen
        case "settings": return settingsOpen
        case "welcome": return welcomeOpen
        case "session": return sessionOpen
        case "taskManager": return taskManagerOpen
        case "desktopMenu": return desktopMenuOpen
        default: return false
        }
    }

    function closePrimarySurfaces(except: string): void {
        if (except !== "launcher") launcherOpen = false
        if (except !== "wallpaper") wallpaperSelectorOpen = false
        if (except !== "overview") overviewOpen = false
        if (except !== "controlCenter") controlCenterOpen = false
        if (except !== "leftSidebar") leftSidebarOpen = false
        if (except !== "overlay") overlayOpen = false
        if (except !== "screenTranslator") screenTranslatorOpen = false
        if (except !== "settings") settingsOpen = false
        if (except !== "welcome") welcomeOpen = false
        if (except !== "session") sessionOpen = false
        if (except !== "taskManager") taskManagerOpen = false
        if (except !== "desktopMenu") desktopMenuOpen = false
    }

    function setPrimaryOpen(name: string, open: bool): void {
        if (open)
            closePrimarySurfaces(name)

        switch (name) {
        case "launcher": launcherOpen = open; break
        case "wallpaper": wallpaperSelectorOpen = open; break
        case "overview": overviewOpen = open; break
        case "controlCenter": controlCenterOpen = open; break
        case "leftSidebar": leftSidebarOpen = open; break
        case "overlay": overlayOpen = open; break
        case "screenTranslator": screenTranslatorOpen = open; break
        case "settings": settingsOpen = open; break
        case "welcome": welcomeOpen = open; break
        case "session": sessionOpen = open; break
        case "taskManager": taskManagerOpen = open; break
        case "desktopMenu": desktopMenuOpen = open; break
        default:
            console.warn("[RaohaneState] Unknown primary surface:", name)
            break
        }
    }

    function togglePrimary(name: string): void {
        const nextOpen = !primaryOpen(name)
        if (nextOpen)
            setPrimaryOpen(name, true)
        else
            setPrimaryOpen(name, false)
    }

    function toggleAction(name: string): void {
        if (!name || name === "none")
            return

        switch (name) {
        case "sidebarLeftOpen":
            togglePrimary("leftSidebar")
            break
        case "sidebarRightOpen":
            togglePrimary("controlCenter")
            break
        case "overviewOpen":
            togglePrimary("overview")
            break
        case "wallpaperSelectorOpen":
            togglePrimary("wallpaper")
            break
        case "mediaOverlayOpen":
        case "mediaControlsOpen": // v10 config compatibility alias
            mediaOverlayOpen = !mediaOverlayOpen
            break
        case "overlayOpen":
            togglePrimary("overlay")
            break
        case "regionSelectorOpen": {
            const opening = !regionSelectorOpen
            if (opening)
                closePrimarySurfaces("")
            regionSelectorOpen = opening
            break
        }
        case "screenTranslatorOpen":
            togglePrimary("screenTranslator")
            break
        case "oskOpen":
            oskOpen = !oskOpen
            break
        case "sessionOpen":
            togglePrimary("session")
            break
        case "taskManagerOpen":
            togglePrimary("taskManager")
            break
        case "desktopMenuOpen":
            togglePrimary("desktopMenu")
            break
        default:
            console.warn("[RaohaneState] Unknown transient action:", name)
            break
        }
    }

    function closeTransientSurfaces(): void {
        closePrimarySurfaces("")
        mediaOverlayOpen = false
        regionSelectorOpen = false
        oskOpen = false
        osdOpen = false
    }
}
