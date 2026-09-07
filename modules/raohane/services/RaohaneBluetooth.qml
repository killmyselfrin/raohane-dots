pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import qs.modules.raohane.config

Singleton {
    id: root

    property bool available: false
    property bool enabled: false
    property bool busy: false
    property bool requestedEnabled: false
    property bool applyPending: false
    property string lastError: ""
    property string commandError: ""
    property var connectedDevices: []

    readonly property int connectedCount: connectedDevices.length
    readonly property bool connected: connectedCount > 0
    readonly property var firstConnectedDevice: connectedDevices.length > 0 ? connectedDevices[0] : null
    readonly property string firstConnectedName: firstConnectedDevice?.name ?? ""

    signal powerApplied(bool enabled)

    function refresh(): void {
        if (!adapterProbe.running)
            adapterProbe.exec(["bash", "-lc", "command -v bluetoothctl >/dev/null 2>&1 && bluetoothctl show || true"])
        if (!devicesProbe.running)
            devicesProbe.exec(["bash", "-lc", "command -v bluetoothctl >/dev/null 2>&1 && bluetoothctl devices Connected || true"])
    }

    function finishPowerVerification(): void {
        if (!root.applyPending)
            return

        if (root.enabled === root.requestedEnabled) {
            root.applyPending = false
            root.busy = false
            root.lastError = ""
            root.powerApplied(root.enabled)
            return
        }

        root.applyPending = false
        root.busy = false
        root.lastError = qsTr("Bluetooth adapter did not apply the requested power state")
    }

    function parseAdapter(text): void {
        const value = String(text ?? "")
        root.available = /(^|\n)Controller\s+/m.test(value)
        root.enabled = /Powered:\s*yes/i.test(value)
        if (!root.available)
            root.connectedDevices = []
        root.finishPowerVerification()
    }

    function parseConnectedDevices(text): void {
        const devices = []
        for (const rawLine of String(text ?? "").split("\n")) {
            const line = rawLine.trim()
            const match = line.match(/^Device\s+([0-9A-Fa-f:]{17})\s+(.+)$/)
            if (!match)
                continue
            devices.push({
                address: match[1],
                name: match[2],
                connected: true
            })
        }
        root.connectedDevices = devices
    }

    function setEnabled(value: bool): void {
        const requested = Boolean(value)
        if (!root.available || root.busy || root.enabled === requested)
            return

        root.busy = true
        root.requestedEnabled = requested
        root.applyPending = true
        root.lastError = ""
        root.commandError = ""
        powerCommand.exec(["bluetoothctl", "power", requested ? "on" : "off"])
    }

    function toggle(): void {
        root.setEnabled(!root.enabled)
    }

    function openManager(): void {
        const command = String(RaohaneConfig.bluetoothCommand ?? "").trim()
        if (command !== "")
            Quickshell.execDetached(["bash", "-c", command])
    }

    Process {
        id: adapterProbe
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: root.parseAdapter(text)
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0 && root.applyPending) {
                root.applyPending = false
                root.busy = false
                root.lastError = qsTr("Could not verify Bluetooth adapter state")
            }
        }
    }

    Process {
        id: devicesProbe
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: root.parseConnectedDevices(text)
        }
    }

    Process {
        id: powerCommand
        environment: ({ LANG: "C", LC_ALL: "C" })

        stderr: StdioCollector {
            onStreamFinished: {
                const value = String(text ?? "").trim()
                root.commandError = value.length > 0 ? value.split("\n").pop() : ""
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                verifyPowerTimer.restart()
                return
            }
            root.applyPending = false
            root.busy = false
            root.lastError = root.commandError.length > 0
                ? root.commandError
                : qsTr("Bluetooth power command failed")
            root.refresh()
        }
    }

    Process {
        id: bluezMonitor
        command: [
            "bash", "-lc",
            "if command -v bluetoothctl >/dev/null 2>&1; then exec bluetoothctl --monitor; else sleep 3600; fi"
        ]
        running: true
        environment: ({ LANG: "C", LC_ALL: "C" })

        stdout: SplitParser {
            onRead: data => {
                if (data.length > 0)
                    monitorDebounce.restart()
            }
        }

        onExited: monitorRestart.restart()
    }

    Timer {
        id: verifyPowerTimer
        interval: 260
        repeat: false
        onTriggered: root.refresh()
    }

    Timer {
        id: monitorDebounce
        interval: 180
        repeat: false
        onTriggered: root.refresh()
    }

    Timer {
        id: monitorRestart
        interval: 2500
        repeat: false
        onTriggered: bluezMonitor.running = true
    }

    // BlueZ monitor events are the primary update path. Keep only a slow repair
    // snapshot in case a monitor event is lost instead of spawning bluetoothctl
    // probes every 15 seconds while the shell is otherwise idle.
    Timer {
        interval: 90000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()
}
