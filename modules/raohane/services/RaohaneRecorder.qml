pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool available: false
    property bool externalRecording: false
    property string lastError: ""
    property string captureMode: "fullscreen"
    property bool captureSound: true
    property double startedAtMs: 0
    property int elapsedSeconds: 0
    property string pendingError: ""

    readonly property string recorderScript: Quickshell.shellPath("scripts/videos/record.sh")
    readonly property bool ownedRecording: recordProcess.running
    readonly property bool recording: root.ownedRecording || root.externalRecording
    readonly property string elapsedText: root.formatElapsed(root.elapsedSeconds)

    signal captureStarted(string mode)
    signal captureStopped()

    function formatElapsed(seconds): string {
        const value = Math.max(0, Math.floor(Number(seconds) || 0))
        const minutes = Math.floor(value / 60)
        const remainder = value % 60
        return String(minutes).padStart(2, "0") + ":" + String(remainder).padStart(2, "0")
    }

    function refreshExternalState(): void {
        if (!stateProbe.running)
            stateProbe.running = true
    }

    function start(mode, sound): bool {
        if (root.recording || recordProcess.running)
            return false
        if (!root.available) {
            root.lastError = "wf-recorder is not installed"
            availabilityProbe.running = true
            return false
        }

        const requestedMode = String(mode ?? "fullscreen").trim().toLowerCase()
        if (requestedMode !== "fullscreen" && requestedMode !== "region")
            return false

        root.captureMode = requestedMode
        root.captureSound = sound === undefined ? true : Boolean(sound)
        root.lastError = ""
        root.pendingError = ""

        const command = [root.recorderScript]
        if (requestedMode === "fullscreen")
            command.push("--fullscreen")
        if (root.captureSound)
            command.push("--sound")
        recordProcess.command = command
        recordProcess.running = true
        return true
    }

    function startFullscreen(sound): bool {
        return root.start("fullscreen", sound)
    }

    function startRegion(sound): bool {
        return root.start("region", sound)
    }

    function stop(): bool {
        if (!root.recording)
            return false
        Quickshell.execDetached(["pkill", "-INT", "-x", "wf-recorder"])
        return true
    }

    function toggleFullscreen(sound): bool {
        return root.recording ? root.stop() : root.startFullscreen(sound)
    }

    onOwnedRecordingChanged: {
        if (root.ownedRecording) {
            root.externalRecording = false
            root.startedAtMs = Date.now()
            root.elapsedSeconds = 0
            root.captureStarted(root.captureMode)
            return
        }

        if (root.startedAtMs > 0)
            root.captureStopped()
        root.startedAtMs = 0
        root.elapsedSeconds = 0
        Qt.callLater(root.refreshExternalState)
    }

    Process {
        id: availabilityProbe
        command: ["bash", "-c", "command -v wf-recorder >/dev/null 2>&1"]
        onExited: (exitCode, exitStatus) => root.available = exitCode === 0
    }

    Process {
        id: stateProbe
        command: ["pgrep", "-x", "wf-recorder"]
        onExited: (exitCode, exitStatus) => {
            root.externalRecording = exitCode === 0 && !root.ownedRecording
        }
    }

    Process {
        id: recordProcess

        stderr: StdioCollector {
            onStreamFinished: {
                const lines = String(text ?? "").trim().split("\n").filter(line => line.trim().length > 0)
                root.pendingError = lines.length > 0 ? lines[lines.length - 1] : ""
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0 && root.pendingError.length > 0)
                root.lastError = root.pendingError
            else if (exitCode === 0)
                root.lastError = ""
            root.pendingError = ""
        }
    }

    Timer {
        id: elapsedTimer
        interval: 1000
        repeat: true
        running: root.ownedRecording
        onTriggered: root.elapsedSeconds = Math.max(0, Math.floor((Date.now() - root.startedAtMs) / 1000))
    }

    Timer {
        id: externalProbeTimer
        interval: 1600
        repeat: true
        running: root.externalRecording && !root.ownedRecording
        onTriggered: root.refreshExternalState()
    }

    IpcHandler {
        target: "recorder"

        function status(): string {
            return JSON.stringify({
                available: root.available,
                recording: root.recording,
                owned: root.ownedRecording,
                mode: root.captureMode,
                sound: root.captureSound,
                elapsed: root.elapsedSeconds,
                error: root.lastError
            })
        }

        function fullscreen(): string {
            return root.startFullscreen(true) ? "started" : (root.recording ? "already-recording" : "unavailable")
        }

        function region(): string {
            return root.startRegion(true) ? "started" : (root.recording ? "already-recording" : "unavailable")
        }

        function stop(): string {
            return root.stop() ? "stopping" : "not-recording"
        }

        function toggle(): string {
            return root.toggleFullscreen(true) ? (root.recording ? "stopping" : "started") : "unavailable"
        }
    }

    Component.onCompleted: {
        availabilityProbe.running = true
        stateProbe.running = true
    }
}
