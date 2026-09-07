pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io

Singleton {
    id: root

    property bool gameModeActive: false
    property bool busy: false
    property bool requestedGameMode: false
    property string lastError: ""
    property string commandError: ""

    readonly property string modernGameModeExpression:
        "hl.config({ animations = { enabled = false }, decoration = { shadow = { enabled = false }, blur = { enabled = false }, rounding = 0 }, general = { gaps_in = 0, gaps_out = 0, border_size = 1 } })"

    function refreshGameMode(): void {
        if (gameModeProbe.running)
            return
        gameModeProbe.running = true
    }

    function setGameMode(enabled: bool): void {
        if (root.busy || root.gameModeActive === enabled)
            return

        root.busy = true
        root.requestedGameMode = enabled
        root.lastError = ""
        root.commandError = ""

        if (enabled) {
            gameModeCommand.command = ["hyprctl", "eval", root.modernGameModeExpression]
        } else {
            gameModeCommand.command = ["hyprctl", "reload"]
        }
        gameModeCommand.running = true
    }

    function toggleGameMode(): void {
        root.setGameMode(!root.gameModeActive)
    }

    function commandSucceeded(): void {
        root.lastError = ""
        settleTimer.restart()
    }

    function commandFailed(message: string): void {
        root.busy = false
        root.lastError = message.length > 0 ? message : qsTr("Hyprland rejected the performance-mode request")
        root.refreshGameMode()
    }

    Process {
        id: gameModeCommand

        stderr: StdioCollector {
            onStreamFinished: {
                const value = String(text ?? "").trim()
                root.commandError = value.length > 0 ? value.split("\n").pop() : ""
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.commandSucceeded()
                return
            }

            // Hyprland <= 0.54 does not expose `hyprctl eval`. Keep the old
            // keyword path only as a compatibility fallback instead of making
            // the current 0.55+ runtime depend on deprecated hyprlang IPC.
            if (root.requestedGameMode && !legacyGameModeCommand.running) {
                root.commandError = ""
                legacyGameModeCommand.running = true
                return
            }

            root.commandFailed(root.commandError)
        }
    }

    Process {
        id: legacyGameModeCommand
        command: [
            "hyprctl", "--batch",
            "keyword animations:enabled 0; keyword decoration:shadow:enabled 0; keyword decoration:blur:enabled 0; keyword general:gaps_in 0; keyword general:gaps_out 0; keyword general:border_size 1; keyword decoration:rounding 0"
        ]

        stderr: StdioCollector {
            onStreamFinished: {
                const value = String(text ?? "").trim()
                root.commandError = value.length > 0 ? value.split("\n").pop() : ""
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0)
                root.commandSucceeded()
            else
                root.commandFailed(root.commandError)
        }
    }

    Process {
        id: gameModeProbe
        command: [
            "bash", "-lc",
            "hyprctl -j getoption animations.enabled 2>/dev/null || hyprctl -j getoption animations:enabled 2>/dev/null"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const payload = JSON.parse(String(text ?? "{}"))
                    const raw = payload.int ?? payload.bool ?? payload.value
                    root.gameModeActive = Number(raw) === 0 || raw === false
                    root.lastError = ""
                } catch (error) {
                    root.lastError = qsTr("Could not read Hyprland animation state")
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                const value = String(text ?? "").trim()
                if (value.length > 0)
                    root.commandError = value.split("\n").pop()
            }
        }

        onExited: (exitCode, exitStatus) => {
            root.busy = false
            if (exitCode !== 0 && root.lastError.length === 0)
                root.lastError = root.commandError.length > 0
                    ? root.commandError
                    : qsTr("Could not query Hyprland performance state")
        }
    }

    Timer {
        id: settleTimer
        interval: 220
        repeat: false
        onTriggered: root.refreshGameMode()
    }

    Component.onCompleted: root.refreshGameMode()
}
