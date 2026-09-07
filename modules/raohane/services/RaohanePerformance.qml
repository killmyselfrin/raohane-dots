pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io

Singleton {
    id: root

    property bool gameModeActive: false
    property bool busy: false
    property bool requestedGameMode: false
    property bool applyPending: false
    property string lastError: ""
    property string commandError: ""

    signal gameModeApplied(bool enabled)

    readonly property string modernGameModeExpression:
        "hl.config({ animations = { enabled = false }, decoration = { shadow = { enabled = false }, blur = { enabled = false }, rounding = 0 }, general = { gaps_in = 0, gaps_out = 0, border_size = 1 } })"

    function refreshGameMode(): void {
        if (gameModeProbe.running || gameModeCommand.running || legacyGameModeCommand.running)
            return
        root.busy = true
        gameModeProbe.running = true
    }

    function setGameMode(enabled: bool): void {
        if (root.busy || gameModeProbe.running || gameModeCommand.running || legacyGameModeCommand.running || root.gameModeActive === enabled)
            return

        root.busy = true
        root.requestedGameMode = enabled
        root.applyPending = true
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
        root.applyPending = false
        root.lastError = message.length > 0 ? message : qsTr("Hyprland rejected the performance-mode request")
        errorRefreshTimer.restart()
    }

    function finishProbe(parsed: bool): void {
        root.busy = false
        if (!parsed || !root.applyPending)
            return

        if (root.gameModeActive === root.requestedGameMode) {
            root.applyPending = false
            root.lastError = ""
            root.gameModeApplied(root.gameModeActive)
            return
        }

        root.applyPending = false
        root.lastError = qsTr("Hyprland did not apply the requested performance state")
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
        property bool parsed: false

        command: [
            "bash", "-lc",
            "hyprctl -j getoption animations.enabled 2>/dev/null || hyprctl -j getoption animations:enabled 2>/dev/null"
        ]

        onRunningChanged: {
            if (running)
                parsed = false
        }

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const payload = JSON.parse(String(text ?? "{}"))
                    const raw = payload.int ?? payload.bool ?? payload.value
                    root.gameModeActive = Number(raw) === 0 || raw === false
                    gameModeProbe.parsed = true
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
            if (exitCode !== 0 && root.lastError.length === 0)
                root.lastError = root.commandError.length > 0
                    ? root.commandError
                    : qsTr("Could not query Hyprland performance state")
            root.finishProbe(exitCode === 0 && gameModeProbe.parsed)
        }
    }

    Timer {
        id: settleTimer
        interval: 260
        repeat: false
        onTriggered: root.refreshGameMode()
    }

    Timer {
        id: errorRefreshTimer
        interval: 420
        repeat: false
        onTriggered: root.refreshGameMode()
    }

    Component.onCompleted: root.refreshGameMode()
}
