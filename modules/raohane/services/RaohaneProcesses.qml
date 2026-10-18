pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var processes: []
    property bool busy: false
    property string errorText: ""
    property real memoryUsedMiB: 0
    property real memoryTotalMiB: 0
    property real loadOne: 0
    property int cpuCount: 1
    property int generation: 0
    property double lastRefreshMs: 0
    property bool forceNextRefresh: false
    property bool sessionActive: false
    property bool snapshotReceived: false

    readonly property int minimumRefreshInterval: 2800
    readonly property real memoryUsage: memoryTotalMiB > 0 ? memoryUsedMiB / memoryTotalMiB : 0

    // Process data is collected directly from Linux procfs by
    // scripts/process-snapshot.py. /proc/meminfo and full command lines are
    // read there as well so Task Manager can diagnose Raohane itself and
    // distinguish browser/helper process roles without spawning procps tools.

    // The process list includes full command lines and is only useful while
    // Task Manager is visible. Release it on any primary-surface transition;
    // do not leave the last procfs snapshot resident for the whole session.
    function beginSession(): void {
        if (root.sessionActive)
            return

        root.sessionActive = true
        root.lastRefreshMs = 0
        root.refresh()
    }

    function endSession(): void {
        if (!root.sessionActive)
            return

        root.sessionActive = false
        refreshDelay.stop()
        root.forceNextRefresh = false
        root.lastRefreshMs = 0
        root.processes = []
        root.generation += 1
        root.memoryUsedMiB = 0
        root.memoryTotalMiB = 0
        root.loadOne = 0
        root.cpuCount = 1
        root.busy = false
        root.errorText = ""
        // An already-running snapshot may finish shortly after dismissal.
        // applySnapshot() checks sessionActive so that late output is ignored.
    }

    function refresh(): void {
        if (!root.sessionActive || snapshotProbe.running)
            return

        const now = Date.now()
        if (!root.forceNextRefresh
                && root.lastRefreshMs > 0
                && now - root.lastRefreshMs < root.minimumRefreshInterval)
            return

        root.forceNextRefresh = false
        root.lastRefreshMs = now
        root.busy = true
        root.errorText = ""
        root.snapshotReceived = false
        snapshotProbe.running = true
    }

    function applySnapshot(payload: string): void {
        if (!root.sessionActive)
            return

        const rows = []
        const lines = String(payload ?? "").split("\n")
        let hasStatistics = false

        for (const rawLine of lines) {
            const line = rawLine.trim()
            if (line.length === 0)
                continue

            const fields = line.split("\t")
            if (fields[0] === "@STAT") {
                if (fields.length < 5)
                    continue
                hasStatistics = true
                root.memoryUsedMiB = Math.max(0, Number(fields[1] ?? 0))
                root.memoryTotalMiB = Math.max(0, Number(fields[2] ?? 0))
                root.loadOne = Math.max(0, Number(fields[3] ?? 0))
                root.cpuCount = Math.max(1, Number(fields[4] ?? 1))
                continue
            }

            if (fields.length < 8)
                continue

            const pid = Number(fields[0])
            if (!Number.isFinite(pid) || pid <= 1)
                continue

            rows.push({
                pid: pid,
                ppid: Math.max(0, Number(fields[1] ?? 0)),
                user: String(fields[2] ?? ""),
                cpu: Math.max(0, Number(fields[3] ?? 0)),
                memoryPercent: Math.max(0, Number(fields[4] ?? 0)),
                rssMiB: Math.max(0, Number(fields[5] ?? 0) / 1024),
                elapsedSeconds: Math.max(0, Number(fields[6] ?? 0)),
                command: String(fields[7] ?? "process"),
                commandLine: String(fields[8] ?? fields[7] ?? "process")
            })
        }

        // A successful exit without the @STAT header is not a valid snapshot.
        // Keep the last good data until a complete replacement arrives.
        if (!hasStatistics)
            return

        root.processes = rows
        root.generation += 1
        root.snapshotReceived = true
        root.busy = false
    }

    function signalProcesses(pids, signalName: string): void {
        if (!Array.isArray(pids) || pids.length === 0)
            return

        const safe = []
        for (const value of pids) {
            const pid = Number(value)
            if (Number.isInteger(pid) && pid > 1)
                safe.push(String(pid))
        }
        if (safe.length === 0)
            return

        const signal = signalName === "KILL" ? "KILL" : "TERM"
        Quickshell.execDetached(["kill", "-" + signal].concat(safe))
        root.forceNextRefresh = true
        refreshDelay.restart()
    }

    function terminate(pids): void { root.signalProcesses(pids, "TERM") }
    function forceKill(pids): void { root.signalProcesses(pids, "KILL") }

    Timer {
        id: refreshDelay
        interval: 350
        repeat: false
        onTriggered: root.refresh()
    }

    Process {
        id: snapshotProbe
        running: false
        command: [
            "python3",
            Quickshell.shellPath("scripts/process-snapshot.py")
        ]

        stdout: StdioCollector {
            onStreamFinished: root.applySnapshot(text)
        }

        onExited: (exitCode, exitStatus) => {
            // Quickshell may finish a process without emitting a usable
            // stdout snapshot. Clear busy for both success and failure.
            root.busy = false
            if (!root.sessionActive)
                return
            if (exitCode !== 0 || !root.snapshotReceived)
                root.errorText = qsTr("Unable to read the process table.")
        }
    }
}
