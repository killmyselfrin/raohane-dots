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

    readonly property real memoryUsage: memoryTotalMiB > 0 ? memoryUsedMiB / memoryTotalMiB : 0

    function refresh(): void {
        if (snapshotProbe.running)
            return
        root.busy = true
        root.errorText = ""
        snapshotProbe.running = true
    }

    function applySnapshot(payload: string): void {
        const rows = []
        const lines = String(payload ?? "").split("\n")

        for (const rawLine of lines) {
            const line = rawLine.trim()
            if (line.length === 0)
                continue

            const fields = line.split("\t")
            if (fields[0] === "@STAT") {
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
                command: String(fields[7] ?? "process")
            })
        }

        root.processes = rows
        root.generation += 1
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
            "bash", "-lc",
            "set -o pipefail; "
                + "awk '/MemTotal:/ {t=$2} /MemAvailable:/ {a=$2} END {used=(t-a)/1024; total=t/1024; printf \"@STAT\\t%.1f\\t%.1f\\t\", used, total}' /proc/meminfo; "
                + "read load _ < /proc/loadavg; printf '%s\\t%s\\n' \"$load\" \"$(nproc 2>/dev/null || printf 1)\"; "
                + "LC_ALL=C ps -u \"$(id -u)\" -o pid=,ppid=,user=,%cpu=,%mem=,rss=,etimes=,comm= --sort=-%cpu 2>/dev/null "
                + "| awk '$8 != \"quickshell\" && $8 != \"qs\" {printf \"%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\n\", $1,$2,$3,$4,$5,$6,$7,$8}' "
                + "| head -n 400"
        ]

        stdout: StdioCollector {
            onStreamFinished: root.applySnapshot(text)
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root.busy = false
                root.errorText = qsTr("Unable to read the process table.")
            }
        }
    }
}
