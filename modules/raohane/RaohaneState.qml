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
    property bool screenLocked: false
    property bool superDown: false

    function closeTransientSurfaces(): void {
        launcherOpen = false
        mediaOverlayOpen = false
        wallpaperSelectorOpen = false
        overviewOpen = false
        controlCenterOpen = false
    }
}
