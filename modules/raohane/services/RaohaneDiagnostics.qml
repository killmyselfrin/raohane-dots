pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool running: false
    property bool hasResult: false
    property bool lastOk: false
    property string lastOutput: ""
    property string lastCheckedText: ""
    property string errorText: ""
    property string pendingStdout: ""
    property string pendingStderr: ""

    readonly property string smokeScript: Quickshell.shellPath("scripts/runtime-smoke-check.sh")
    readonly property string status: root.running ? "running"
        : !root.hasResult ? "idle"
        : root.lastOk ? "pass" : "attention"

    function runSmoke(): void {
        if (smokeProcess.running)
            return
        root.running = true
        root.errorText = ""
        root.pendingStdout = ""
        root.pendingStderr = ""
        smokeProcess.running = true
    }

    function finishRun(exitCode: int): void {
        const stdoutText = String(root.pendingStdout ?? "").trim()
        const stderrText = String(root.pendingStderr ?? "").trim()
        const combined = [stdoutText, stderrText].filter(value => value.length > 0).join("\n")

        root.running = false
        root.hasResult = true
        root.lastOk = exitCode === 0
        root.lastOutput = combined
        root.errorText = root.lastOk ? "" : (stderrText.length > 0 ? stderrText.split("\n").pop() : qsTr("Runtime smoke check failed"))
        root.lastCheckedText = Qt.formatDateTime(new Date(), "HH:mm")
    }

    Process {
        id: smokeProcess
        command: ["bash", root.smokeScript]

        stdout: StdioCollector {
            onStreamFinished: root.pendingStdout = text
        }

        stderr: StdioCollector {
            onStreamFinished: root.pendingStderr = text
        }

        onExited: (exitCode, exitStatus) => Qt.callLater(() => root.finishRun(exitCode))
    }
}
