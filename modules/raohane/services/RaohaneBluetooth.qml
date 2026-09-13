pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Bluetooth

import qs.modules.raohane.config

Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: root.adapter !== null
    readonly property bool enabled: root.adapter?.enabled ?? false
    readonly property bool busy: root.adapter !== null
        && (root.adapter.state === BluetoothAdapterState.Enabling
            || root.adapter.state === BluetoothAdapterState.Disabling)
    readonly property bool blocked: root.adapter !== null
        && root.adapter.state === BluetoothAdapterState.Blocked

    property bool requestedEnabled: false
    property bool applyPending: false
    property string lastError: ""
    readonly property string commandError: ""

    readonly property var connectedDevices: root.buildConnectedDevices()
    readonly property int connectedCount: connectedDevices.length
    readonly property bool connected: connectedCount > 0
    readonly property var firstConnectedDevice: connectedCount > 0 ? connectedDevices[0] : null
    readonly property string firstConnectedName: firstConnectedDevice?.name ?? ""

    signal powerApplied(bool enabled)

    function deviceLabel(device): string {
        if (!device)
            return ""

        const alias = String(device.name ?? "").trim()
        if (alias.length > 0)
            return alias

        const providedName = String(device.deviceName ?? "").trim()
        if (providedName.length > 0)
            return providedName

        return String(device.address ?? "").trim()
    }

    function buildConnectedDevices(): var {
        const entries = []
        for (const device of Bluetooth.devices.values) {
            if (!device || !device.connected)
                continue

            entries.push({
                address: String(device.address ?? ""),
                name: root.deviceLabel(device),
                connected: true,
                batteryAvailable: Boolean(device.batteryAvailable),
                battery: device.batteryAvailable ? Number(device.battery) : 0,
                device: device
            })
        }

        entries.sort((left, right) => left.name.localeCompare(right.name))
        return entries
    }

    // Retained for presentation code that used to request a bluetoothctl
    // snapshot when opening a panel. The Quickshell BlueZ model is live and
    // needs no subprocess refresh.
    function refresh(force): void {}

    function finishPowerVerification(): void {
        if (!root.applyPending || !root.adapter || root.busy)
            return

        root.applyPending = false
        if (root.adapter.enabled === root.requestedEnabled) {
            root.lastError = ""
            root.powerApplied(root.adapter.enabled)
            return
        }

        root.lastError = qsTr("Bluetooth adapter did not apply the requested power state")
    }

    function setEnabled(value: bool): void {
        const requested = Boolean(value)
        if (!root.adapter || root.busy || root.adapter.enabled === requested)
            return

        if (root.blocked) {
            root.lastError = qsTr("Bluetooth adapter did not apply the requested power state")
            return
        }

        root.requestedEnabled = requested
        root.applyPending = true
        root.lastError = ""
        root.adapter.enabled = requested
        root.finishPowerVerification()
    }

    function toggle(): void {
        root.setEnabled(!root.enabled)
    }

    function openManager(): void {
        const command = String(RaohaneConfig.bluetoothCommand ?? "").trim()
        if (command.length > 0)
            Quickshell.execDetached(["bash", "-c", command])
    }

    Connections {
        target: root.adapter
        ignoreUnknownSignals: true

        function onStateChanged(): void {
            root.finishPowerVerification()
        }

        function onEnabledChanged(): void {
            root.finishPowerVerification()
        }
    }

    onAdapterChanged: {
        if (!root.adapter) {
            root.applyPending = false
            root.lastError = ""
        }
    }
}
