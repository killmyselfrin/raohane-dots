pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import qs.modules.raohane.config

Singleton {
    id: root

    property bool automaticUpdates: true
    property bool preferenceReady: false
    property bool checking: false
    property bool applying: false
    property bool updateAvailable: false
    property string currentRevision: ""
    property string latestRevision: ""
    property string channel: "main"
    property string errorText: ""
    property string lastCheckedText: ""
    property bool autoApplyAfterCheck: false

    readonly property string preferencePath: RaohanePaths.join(RaohanePaths.stateDirectory, "updater-mode.state")
    readonly property string updaterScript: Quickshell.shellPath("scripts/update-raohane.py")
    readonly property string currentShortRevision: root.currentRevision.length >= 7 ? root.currentRevision.slice(0, 7) : root.currentRevision
    readonly property string latestShortRevision: root.latestRevision.length >= 7 ? root.latestRevision.slice(0, 7) : root.latestRevision

    function setAutomaticUpdates(value: bool): void {
        root.automaticUpdates = value
        if (root.preferenceReady)
            preferenceFile.setText(value ? "automatic\n" : "manual\n")
    }

    function checkNow(allowAutomaticApply = false): void {
        if (checkProcess.running || root.applying)
            return
        root.autoApplyAfterCheck = allowAutomaticApply
        root.errorText = ""
        root.checking = true
        checkProcess.running = true
    }

    function applyUpdate(): void {
        if (root.applying || root.checking || !root.updateAvailable || root.latestRevision.length !== 40)
            return
        root.errorText = ""
        root.applying = true
        const transactionId = `${root.latestShortRevision}-${Date.now()}`
        applyProcess.command = [
            "systemd-run",
            "--user",
            "--wait",
            "--pipe",
            "--collect",
            `--unit=raohane-update-${transactionId}`,
            "python3",
            root.updaterScript,
            "apply",
            "--revision",
            root.latestRevision
        ]
        applyProcess.running = true
    }

    function consumeCheckPayload(payload: string): void {
        try {
            const line = String(payload ?? "").trim().split("\n").filter(value => value.trim().length > 0).pop() ?? ""
            const data = JSON.parse(line)
            if (!data.ok) {
                root.errorText = String(data.error ?? qsTr("Update check failed"))
                return
            }
            root.currentRevision = String(data.current ?? "")
            root.latestRevision = String(data.latest ?? "")
            root.channel = String(data.channel ?? "main")
            root.updateAvailable = Boolean(data.available)
            root.lastCheckedText = Qt.formatDateTime(new Date(), "HH:mm")
            const persistedError = String(data.last_error ?? "")
            if (persistedError.length > 0)
                root.errorText = persistedError

            if (root.updateAvailable && root.automaticUpdates && root.autoApplyAfterCheck)
                Qt.callLater(root.applyUpdate)
        } catch (error) {
            root.errorText = qsTr("Could not read update information")
        }
    }

    Component.onCompleted: {
        ensureStateDirectory.running = true
        startupCheck.start()
        periodicCheck.start()
    }

    Process {
        id: ensureStateDirectory
        command: ["mkdir", "-p", RaohanePaths.stateDirectory]
        onExited: (exitCode, exitStatus) => {
            root.preferenceReady = exitCode === 0
            if (root.preferenceReady)
                preferenceFile.reload()
        }
    }

    FileView {
        id: preferenceFile
        path: root.preferencePath

        onLoaded: {
            root.preferenceReady = true
            root.automaticUpdates = preferenceFile.text().trim() !== "manual"
        }

        onLoadFailed: error => {
            if (!root.preferenceReady)
                return
            root.automaticUpdates = true
            preferenceFile.setText("automatic\n")
        }
    }

    // Keep login/startup warm-up free of network and git work. Manual checks
    // remain immediate; the automatic check begins only after the shell has had
    // enough time to settle and the user has started interacting with it.
    Timer {
        id: startupCheck
        interval: 90000
        repeat: false
        onTriggered: root.checkNow(true)
    }

    Timer {
        id: periodicCheck
        interval: 6 * 60 * 60 * 1000
        repeat: true
        onTriggered: root.checkNow(false)
    }

    Process {
        id: checkProcess
        command: ["python3", root.updaterScript, "check"]

        stdout: StdioCollector {
            onStreamFinished: root.consumeCheckPayload(text)
        }

        stderr: StdioCollector {
            onStreamFinished: {
                const value = String(text ?? "").trim()
                if (value.length > 0 && root.errorText.length === 0)
                    root.errorText = value.split("\n").pop()
            }
        }

        onExited: (exitCode, exitStatus) => {
            root.checking = false
            root.autoApplyAfterCheck = false
            if (exitCode !== 0 && root.errorText.length === 0)
                root.errorText = qsTr("Update check failed")
        }
    }

    Process {
        id: applyProcess

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = String(text ?? "").trim().split("\n").filter(value => value.trim().length > 0)
                if (lines.length === 0)
                    return
                try {
                    const data = JSON.parse(lines[lines.length - 1])
                    if (!data.ok)
                        root.errorText = String(data.error ?? qsTr("Update failed"))
                } catch (error) {
                    // The updater may write progress before its final JSON record.
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                const value = String(text ?? "").trim()
                if (value.length > 0 && root.errorText.length === 0)
                    root.errorText = value.split("\n").pop()
            }
        }

        onExited: (exitCode, exitStatus) => {
            root.applying = false
            if (exitCode !== 0 && root.errorText.length === 0)
                root.errorText = qsTr("Update installation failed")
            if (exitCode === 0)
                Qt.callLater(() => root.checkNow(false))
        }
    }
}
