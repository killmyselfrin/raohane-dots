import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.raohane.config

Item {
    id: root

    property bool active: true
    property bool rerunRequested: false
    readonly property string scriptPath: Quickshell.shellPath("scripts/sync-login-wallpaper.sh")

    visible: false
    width: 0
    height: 0

    function requestSync(): void {
        if (!root.active || !RaohaneConfig.ready || RaohaneConfig.wallpaperPath.length === 0)
            return
        if (syncProcess.running) {
            root.rerunRequested = true
            return
        }
        syncProcess.exec(["bash", root.scriptPath, RaohaneConfig.wallpaperPath])
    }

    Timer {
        id: syncTimer
        interval: 120
        repeat: false
        onTriggered: root.requestSync()
    }

    Process {
        id: syncProcess
        onExited: (exitCode, exitStatus) => {
            if (root.rerunRequested) {
                root.rerunRequested = false
                syncTimer.restart()
            }
        }
    }

    Connections {
        target: RaohaneConfig
        function onWallpaperPathChanged(): void {
            syncTimer.restart()
        }
        function onReadyChanged(): void {
            if (RaohaneConfig.ready)
                syncTimer.restart()
        }
    }

    Component.onCompleted: syncTimer.restart()
}
