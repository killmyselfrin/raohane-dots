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
    property string lastThemeId: ""
    property string statusMessage: ""
    property string detailMessage: ""
    property string processOutput: ""

    signal completed(string operation, bool success, string themeId, string path)

    function cleanPath(value): string {
        return RaohanePaths.cleanPath(value)
    }

    function begin(nextOperation: string, themeId: string, path: string, status: string): bool {
        if (root.busy)
            return false
        root.busy = true
        root.lastSucceeded = false
        root.operation = nextOperation
        root.lastThemeId = themeId
        root.lastPath = path
        root.statusMessage = status
        root.detailMessage = ""
        root.processOutput = ""
        return true
    }

    function command(args): var {
        return [
            "python3",
            Quickshell.shellPath("scripts/theme-catalog.py"),
            "--catalog",
            RaohanePaths.themeCatalogFile
        ].concat(args)
    }

    function importTheme(source): void {
        const clean = root.cleanPath(source)
        if (clean.length === 0 || !root.begin("import", "", clean, qsTr("Importing theme…")))
            return
        worker.exec(root.command(["import", clean]))
    }

    function savePreset(preset): void {
        if (!preset || typeof preset !== "object")
            return
        const themeId = String(preset.id ?? "")
        if (!root.begin("save", themeId, "", qsTr("Saving theme preset…")))
            return
        worker.exec(root.command(["upsert-json", JSON.stringify(preset)]))
    }

    function exportPreset(preset, destination): void {
        if (!preset || typeof preset !== "object")
            return
        const clean = root.cleanPath(destination)
        if (clean.length === 0)
            return
        const themeId = String(preset.id ?? "")
        if (!root.begin("export", themeId, clean, qsTr("Exporting theme…")))
            return
        worker.exec(root.command(["export-json", JSON.stringify(preset), clean]))
    }

    function removePreset(themeId: string): void {
        const cleanId = String(themeId ?? "").trim()
        if (cleanId.length === 0 || !root.begin("remove", cleanId, "", qsTr("Removing theme…")))
            return
        worker.exec(root.command(["remove", cleanId]))
    }

    Process {
        id: worker

        stdout: StdioCollector {
            onStreamFinished: root.processOutput = text.trim()
        }

        onExited: (exitCode, exitStatus) => {
            root.busy = false
            root.lastSucceeded = exitCode === 0

            if (root.lastSucceeded) {
                switch (root.operation) {
                case "import":
                    root.statusMessage = qsTr("Theme imported")
                    root.detailMessage = root.lastPath
                    break
                case "save":
                    root.statusMessage = qsTr("Theme preset saved")
                    root.detailMessage = root.lastThemeId
                    break
                case "export":
                    root.statusMessage = qsTr("Theme exported")
                    root.detailMessage = root.lastPath
                    break
                case "remove":
                    root.statusMessage = qsTr("Theme removed")
                    root.detailMessage = root.lastThemeId
                    break
                }
            } else {
                root.statusMessage = qsTr("Theme operation failed")
                root.detailMessage = root.processOutput.length > 0
                    ? root.processOutput
                    : qsTr("The theme tool exited with an error.")
            }

            root.completed(root.operation, root.lastSucceeded, root.lastThemeId, root.lastPath)
        }
    }
}
