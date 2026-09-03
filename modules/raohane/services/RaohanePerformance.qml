pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool gameModeActive: false
    property bool busy: false

    function refreshGameMode(): void {
        if (!gameModeProbe.running)
            gameModeProbe.running = true
    }

    function setGameMode(enabled: bool): void {
        if (root.busy || root.gameModeActive === enabled)
            return

        root.busy = true
        root.gameModeActive = enabled
        if (enabled) {
            Quickshell.execDetached([
                "hyprctl", "--batch",
                "keyword animations:enabled 0; keyword decoration:shadow:enabled 0; keyword decoration:blur:enabled 0; keyword general:gaps_in 0; keyword general:gaps_out 0; keyword general:border_size 1; keyword decoration:rounding 0; keyword general:allow_tearing 1"
            ])
        } else {
            Quickshell.execDetached(["hyprctl", "reload"])
        }
        settleTimer.restart()
    }

    function toggleGameMode(): void {
        root.setGameMode(!root.gameModeActive)
    }

    Process {
        id: gameModeProbe
        command: ["hyprctl", "getoption", "animations:enabled", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.gameModeActive = Number(JSON.parse(text).int) === 0
                } catch (error) {
                    root.gameModeActive = false
                }
                root.busy = false
            }
        }
        onExited: root.busy = false
    }

    Timer {
        id: settleTimer
        interval: 180
        repeat: false
        onTriggered: root.refreshGameMode()
    }
}
