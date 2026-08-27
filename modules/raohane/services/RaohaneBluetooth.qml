pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool available: false
    property bool enabled: false
    property var connectedDevices: []
    readonly property int connectedCount: connectedDevices.length
    readonly property bool connected: connectedCount > 0
    readonly property var firstConnectedDevice: connectedDevices.length > 0 ? connectedDevices[0] : null
    readonly property string firstConnectedName: firstConnectedDevice?.name ?? ""

    function refresh(): void {
        if (!adapterProbe.running)
            adapterProbe.exec(["bash", "-lc", "command -v bluetoothctl >/dev/null 2>&1 && bluetoothctl show || true"])
        if (!devicesProbe.running)
            devicesProbe.exec(["bash", "-lc", "command -v bluetoothctl >/dev/null 2>&1 && bluetoothctl devices Connected || true"])
    }

    function parseAdapter(text): void {
        const value = String(text ?? "")
        root.available = /(^|\n)Controller\s+/m.test(value)
        root.enabled = /Powered:\s*yes/i.test(value)
        if (!root.available)
            root.connectedDevices = []
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
        if (!root.available)
            return
        root.enabled = Boolean(value)
        powerCommand.exec(["bluetoothctl", "power", root.enabled ? "on" : "off"])
    }

    function toggle(): void {
        root.setEnabled(!root.enabled)
    }

    Process {
        id: adapterProbe
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: root.parseAdapter(text)
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
        onExited: root.refresh()
    }

    Timer {
        interval: 3000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()
}
