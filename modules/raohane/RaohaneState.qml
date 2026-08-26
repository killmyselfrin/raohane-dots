pragma Singleton

import QtQuick

// Raohane-owned cross-surface state. Product-specific transient state stays
// here; GlobalStates is only bridged while compatibility surfaces remain.
QtObject {
    property bool launcherOpen: false
    property bool mediaOverlayOpen: false
    property bool wallpaperSelectorOpen: false
    property string wallpaperSelectorTarget: "wallpaper"

    function closeTransientSurfaces(): void {
        launcherOpen = false
        mediaOverlayOpen = false
        wallpaperSelectorOpen = false
    }
}
