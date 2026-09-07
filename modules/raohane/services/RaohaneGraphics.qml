pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool checking: false
    property bool updating: false
    property string status: "idle"
    property string updateStatus: "idle"
    property string gpuSummary: ""
    property string driverSummary: ""
    property string packageSummary: ""
    property string checkSource: ""
    property bool checkFresh: false
    property bool updateAvailable: false
    property int updateCount: 0
    property string updateCommand: ""
    property string notes: ""
    property string errorText: ""
    property string updateErrorText: ""
    property string updateResultText: ""
    property double lastCheckMs: 0

    readonly property int minimumAutomaticCheckInterval: 10 * 60 * 1000
    readonly property string probeScript: Quickshell.shellPath("scripts/graphics-driver-check.py")
    readonly property bool canUpdate: root.updateAvailable
        && !root.checking
        && !root.updating
        && root.status !== "error"

    function checkNow(force = false): void {
        if (probe.running || root.updating)
            return

        const now = Date.now()
        if (!force && root.lastCheckMs > 0
                && now - root.lastCheckMs < root.minimumAutomaticCheckInterval)
            return

        root.errorText = ""
        root.checking = true
        probe.command = ["python3", root.probeScript, "--json"]
        probe.running = true
    }

    function updateNow(): void {
        if (!root.canUpdate || updater.running)
            return

        root.updateErrorText = ""
        root.updateResultText = ""
        root.updateStatus = "running"
        root.updating = true

        // Arch-family systems do not support partial upgrades. Execute only the
        // root-owned pacman binary through Polkit; never run a user-writable
        // helper as root and never choose/switch the user's driver family.
        updater.command = ["pkexec", "/usr/bin/pacman", "-Syu", "--noconfirm"]
        updater.running = true
    }

    function consumePayload(payload: string): void {
        try {
            const lines = String(payload ?? "").trim().split("\n").filter(line => line.trim().length > 0)
            if (lines.length === 0)
                throw new Error("empty graphics payload")

            const data = JSON.parse(lines[lines.length - 1])
            if (!data.ok) {
                root.status = "error"
                root.errorText = String(data.error ?? qsTr("Graphics check failed"))
                return
            }

            root.status = String(data.status ?? "unknown")
            root.gpuSummary = String(data.gpu_summary ?? "")
            root.checkSource = String(data.check_source ?? "")
            root.checkFresh = Boolean(data.check_fresh)
            root.updateAvailable = Boolean(data.update_available)
            root.updateCommand = String(data.update_command ?? "")

            const drivers = Array.isArray(data.active_drivers) ? data.active_drivers.map(value => String(value)) : []
            const version = String(data.driver_version ?? "")
            root.driverSummary = drivers.length > 0 ? drivers.join(" + ") : qsTr("Driver unknown")
            if (version.length > 0)
                root.driverSummary += qsTr(" · NVIDIA %1").arg(version)

            const updates = Array.isArray(data.updates) ? data.updates : []
            root.updateCount = updates.length
            const visibleUpdates = updates.slice(0, 3).map(update => {
                const name = String(update.name ?? "")
                const candidate = String(update.candidate ?? "")
                return candidate.length > 0 ? `${name} → ${candidate}` : name
            }).filter(value => value.length > 0)
            if (updates.length > 3)
                visibleUpdates.push(qsTr("+%1 more").arg(updates.length - 3))
            root.packageSummary = visibleUpdates.join(" · ")

            const noteItems = Array.isArray(data.notes) ? data.notes.map(value => String(value)) : []
            root.notes = noteItems.join(" ")
            root.lastCheckMs = Date.now()
        } catch (error) {
            root.status = "error"
            root.errorText = qsTr("Could not read graphics driver information")
        }
    }

    function summarizeUpdateOutput(payload: string): string {
        const lines = String(payload ?? "")
            .split("\n")
            .map(line => line.trim())
            .filter(line => line.length > 0)
        return lines.length > 0 ? lines.slice(-2).join(" · ") : ""
    }

    Process {
        id: probe

        stdout: StdioCollector {
            onStreamFinished: root.consumePayload(text)
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
            if (exitCode !== 0 && root.errorText.length === 0) {
                root.status = "error"
                root.errorText = qsTr("Graphics driver check failed")
            }
        }
    }

    Process {
        id: updater

        stdout: StdioCollector {
            onStreamFinished: {
                const summary = root.summarizeUpdateOutput(text)
                if (summary.length > 0)
                    root.updateResultText = summary
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                const value = String(text ?? "").trim()
                if (value.length > 0)
                    root.updateErrorText = value.split("\n").pop()
            }
        }

        onExited: (exitCode, exitStatus) => {
            root.updating = false

            if (exitCode === 0) {
                root.updateStatus = "success"
                root.updateErrorText = ""
                root.lastCheckMs = 0
                Qt.callLater(() => root.checkNow(true))
                return
            }

            if (exitCode === 126 || exitCode === 127) {
                root.updateStatus = "cancelled"
                if (root.updateErrorText.length === 0)
                    root.updateErrorText = qsTr("Administrator authorization was cancelled or denied")
                return
            }

            root.updateStatus = "error"
            if (root.updateErrorText.length === 0)
                root.updateErrorText = qsTr("Driver update failed with exit code %1").arg(exitCode)
        }
    }
}
