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
    property bool sessionOpen: false
    property bool osdOpen: false
    property bool screenLocked: false
    property bool superDown: false

    property bool desktopMenuOpen: false
    property var desktopMenuScreen: null
    property real desktopMenuX: 0
    property real desktopMenuY: 0

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
        case "mediaOverlayOpen":
        case "mediaControlsOpen": // v10 config compatibility alias
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
        case "desktopMenuOpen":
            desktopMenuOpen = !desktopMenuOpen
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
        desktopMenuOpen = false
    }
}
