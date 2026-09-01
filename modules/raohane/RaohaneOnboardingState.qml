pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.modules.raohane.config

QtObject {
    id: root

    property bool ready: false
    property bool stateDirectoryReady: false
    property bool completed: false
    property bool active: false
    property int step: 0
    readonly property int totalSteps: 11

    signal finished()

    function maybeShowWelcome(): void {
        if (!root.ready || root.completed || root.active || RaohaneState.screenLocked)
            return
        Qt.callLater(() => RaohaneState.setPrimaryOpen("welcome", true))
    }

    function writeState(value: string): void {
        if (root.stateDirectoryReady)
            stateFile.setText(value)
    }

    function markCompleted(): void {
        root.completed = true
        root.writeState("completed\n")
    }

    function closeTourSurfaces(): void {
        RaohaneState.closePrimarySurfaces("")
        RaohaneState.mediaOverlayOpen = false
    }

    function applyStep(): void {
        if (!root.active)
            return

        root.closeTourSurfaces()

        switch (root.step) {
        case 0: // Bar
        case 1: // Dock
            break
        case 2: // Launcher
            RaohaneState.setPrimaryOpen("launcher", true)
            break
        case 3: // Control Center
            RaohaneState.setPrimaryOpen("controlCenter", true)
            break
        case 4: // Left sidebar
            RaohaneState.setPrimaryOpen("leftSidebar", true)
            break
        case 5: // Overview
            RaohaneState.setPrimaryOpen("overview", true)
            break
        case 6: // Wallpaper selector
            RaohaneState.wallpaperSelectorTarget = "wallpaper"
            RaohaneState.setPrimaryOpen("wallpaper", true)
            break
        case 7: // Settings
            RaohaneState.settingsPage = "themes"
            RaohaneState.setPrimaryOpen("settings", true)
            break
        case 8: // Context Island
            break
        case 9: // Session screen
            RaohaneState.setPrimaryOpen("session", true)
            break
        case 10: // Finish
            break
        default:
            console.warn("[RaohaneOnboarding] Unknown step:", root.step)
            break
        }
    }

    function start(): void {
        RaohaneState.setPrimaryOpen("welcome", false)
        root.active = true
        root.step = 0
        root.applyStep()
    }

    function replay(): void {
        root.start()
    }

    function next(): void {
        if (!root.active)
            return
        if (root.step >= root.totalSteps - 1) {
            root.complete()
            return
        }
        root.step += 1
        root.applyStep()
    }

    function previous(): void {
        if (!root.active || root.step <= 0)
            return
        root.step -= 1
        root.applyStep()
    }

    function complete(): void {
        root.active = false
        root.closeTourSurfaces()
        root.markCompleted()
        root.finished()
    }

    function skip(): void {
        root.complete()
    }

    function reset(): void {
        root.active = false
        root.step = 0
        root.completed = false
        root.closeTourSurfaces()
        root.writeState("")
        RaohaneState.setPrimaryOpen("welcome", true)
    }

    Process {
        id: ensureStateDirectory
        command: ["mkdir", "-p", RaohanePaths.stateDirectory]

        onExited: (exitCode, exitStatus) => {
            root.stateDirectoryReady = exitCode === 0
            if (!root.stateDirectoryReady) {
                console.warn("[RaohaneOnboarding] Could not prepare state directory")
                root.ready = true
                root.completed = false
                root.maybeShowWelcome()
                return
            }
            stateFile.reload()
        }
    }

    FileView {
        id: stateFile
        path: RaohanePaths.welcomeStateFile

        onLoaded: {
            if (!root.stateDirectoryReady)
                return
            root.completed = stateFile.text().trim() === "completed"
            root.ready = true
            root.maybeShowWelcome()
        }

        onLoadFailed: error => {
            if (!root.stateDirectoryReady)
                return
            if (error !== FileViewError.FileNotFound)
                console.warn("[RaohaneOnboarding] Could not read onboarding state:", error)
            root.completed = false
            root.ready = true
            root.maybeShowWelcome()
        }
    }

    Connections {
        target: RaohaneState

        function onScreenLockedChanged(): void {
            if (RaohaneState.screenLocked) {
                if (root.active)
                    root.closeTourSurfaces()
                return
            }

            if (root.active)
                root.applyStep()
            else
                root.maybeShowWelcome()
        }
    }

    Component.onCompleted: ensureStateDirectory.running = true
}
