pragma Singleton

import QtQuick

// Raohane-owned cross-surface state. Product-specific transient state stays
// here; GlobalStates is only bridged while compatibility surfaces remain.
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
    property bool sessionOpen: false
    property bool osdOpen: false
    property bool screenLocked: false
    property bool superDown: false

    function toggleAction(name: string): void {
        if (!name || name === "none")
            return

        switch (name) {
        case "sidebarLeftOpen":
            leftSidebarOpen = !leftSidebarOpen
            break
        case "sidebarRightOpen":
            controlCenterOpen = !controlCenterOpen
            break
        case "overviewOpen":
            overviewOpen = !overviewOpen
            break
        case "wallpaperSelectorOpen":
            wallpaperSelectorOpen = !wallpaperSelectorOpen
            break
        case "mediaControlsOpen":
            mediaOverlayOpen = !mediaOverlayOpen
            break
        case "overlayOpen":
            overlayOpen = !overlayOpen
            break
        case "regionSelectorOpen":
            regionSelectorOpen = !regionSelectorOpen
            break
        case "screenTranslatorOpen":
            screenTranslatorOpen = !screenTranslatorOpen
            break
        case "oskOpen":
            oskOpen = !oskOpen
            break
        case "sessionOpen":
            sessionOpen = !sessionOpen
            break
        default:
            console.warn("[RaohaneState] Unknown transient action:", name)
            break
        }
    }

    function closeTransientSurfaces(): void {
        launcherOpen = false
        mediaOverlayOpen = false
        wallpaperSelectorOpen = false
        overviewOpen = false
        controlCenterOpen = false
        leftSidebarOpen = false
        overlayOpen = false
        regionSelectorOpen = false
        screenTranslatorOpen = false
        oskOpen = false
        settingsOpen = false
        sessionOpen = false
        osdOpen = false
    }
}
