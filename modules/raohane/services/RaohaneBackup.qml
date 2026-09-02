pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import qs.modules.raohane.config

Singleton {
    id: root

    property bool busy: false
    property bool lastSucceeded: false
    property string operation: ""
    property string lastPath: ""
    property string statusMessage: ""
    property string detailMessage: ""
    property string processOutput: ""

    signal completed(string operation, bool success, string path)

    function cleanPath(value): string {
        return RaohanePaths.cleanPath(value)
    }

    function suggestedFileName(): string {
        const now = new Date()
        const pad = value => String(value).padStart(2, "0")
        return `raohane-${now.getFullYear()}${pad(now.getMonth() + 1)}${pad(now.getDate())}-${pad(now.getHours())}${pad(now.getMinutes())}.raohane-backup`
    }

    function exportBackup(target): void {
        const clean = root.cleanPath(target)
        if (root.busy || clean.length === 0)
            return
        root.busy = true
        root.lastSucceeded = false
        root.operation = "export"
        root.lastPath = clean
        root.statusMessage = qsTr("Creating Raohane backup…")
        root.detailMessage = ""
        root.processOutput = ""
        worker.exec([
            "python3",
            Quickshell.shellPath("scripts/raohane-backup.py"),
            "export",
            "--output",
            clean
        ])
    }

    function restoreBackup(source): void {
        const clean = root.cleanPath(source)
        if (root.busy || clean.length === 0)
            return
        root.busy = true
        root.lastSucceeded = false
        root.operation = "restore"
        root.lastPath = clean
        root.statusMessage = qsTr("Restoring Raohane settings…")
        root.detailMessage = qsTr("A safety restore point is created before your current settings are replaced.")
        root.processOutput = ""
        worker.exec([
            "python3",
            Quickshell.shellPath("scripts/raohane-backup.py"),
            "restore",
            "--input",
            clean
        ])
    }

    function restartShell(): void {
        Quickshell.execDetached(["raohane", "restart"])
    }

    Process {
        id: worker

        stdout: StdioCollector {
            onStreamFinished: root.processOutput = text.trim()
        }

        onExited: (exitCode, exitStatus) => {
            root.busy = false
            root.lastSucceeded = exitCode === 0

            if (exitCode === 0) {
                if (root.operation === "export") {
                    root.statusMessage = qsTr("Backup created")
                    root.detailMessage = root.lastPath
                } else {
                    root.statusMessage = qsTr("Settings restored")
                    root.detailMessage = qsTr("Restart Raohane to ensure every restored service and monitor profile is reloaded.")
                }
            } else {
                root.statusMessage = root.operation === "export"
                    ? qsTr("Backup failed")
                    : qsTr("Restore failed")
                try {
                    const parsed = JSON.parse(root.processOutput)
                    root.detailMessage = String(parsed?.error ?? root.processOutput)
                } catch (error) {
                    root.detailMessage = root.processOutput.length > 0
                        ? root.processOutput
                        : qsTr("The backup tool exited with an error.")
                }
            }

            root.completed(root.operation, root.lastSucceeded, root.lastPath)
        }
    }
}
