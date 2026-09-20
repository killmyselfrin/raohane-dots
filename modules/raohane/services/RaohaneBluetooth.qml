pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Bluetooth

import qs.modules.raohane.config

Singleton {
    id: root

    readonly property var adapterList: Bluetooth.adapters?.values ?? []
    readonly property var adapter: Bluetooth.defaultAdapter
        ?? (root.adapterList.length > 0 ? root.adapterList[0] : null)
    readonly property bool available: root.adapter !== null
    readonly property bool enabled: root.adapter?.enabled ?? false
    readonly property bool busy: root.adapter !== null
        && (root.adapter.state === BluetoothAdapterState.Enabling
            || root.adapter.state === BluetoothAdapterState.Disabling)
    readonly property bool blocked: root.adapter !== null
        && root.adapter.state === BluetoothAdapterState.Blocked
    readonly property bool discovering: root.adapter?.discovering ?? false
    readonly property var devices: root.buildDevices()

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

    function buildDevices(): var {
        if (!root.adapter || !root.adapter.devices)
            return []

        const entries = [...root.adapter.devices.values].filter(device => Boolean(device))
        entries.sort((left, right) => {
            const connectedOrder = Number(Boolean(right.connected)) - Number(Boolean(left.connected))
            if (connectedOrder !== 0)
                return connectedOrder
            const pairedOrder = Number(Boolean(right.paired || right.bonded)) - Number(Boolean(left.paired || left.bonded))
            if (pairedOrder !== 0)
                return pairedOrder
            return root.deviceLabel(left).localeCompare(root.deviceLabel(right))
        })
        return entries
    }

    function buildConnectedDevices(): var {
        const entries = []
        for (const device of root.devices) {
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

        return entries
    }

    // Compatibility entrypoint for panels that used to request an explicit
    // snapshot on open. The Quickshell BlueZ model is live and event-driven.
    function refresh(force): void {}

    function finishPowerVerification(): void {
        if (!root.applyPending || !root.adapter || root.busy)
            return

        const state = root.adapter.state
        if (state !== BluetoothAdapterState.Enabled
                && state !== BluetoothAdapterState.Disabled
                && state !== BluetoothAdapterState.Blocked)
            return

        root.applyPending = false
        if (state !== BluetoothAdapterState.Blocked
                && root.adapter.enabled === root.requestedEnabled) {
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
    }

    function toggle(): void {
        root.setEnabled(!root.enabled)
    }

    function setDiscovering(value: bool): void {
        if (!root.adapter || !root.enabled)
            return
        root.adapter.discovering = Boolean(value)
    }

    function startDiscovery(): void {
        root.setDiscovering(true)
    }

    function stopDiscovery(): void {
        if (root.adapter)
            root.adapter.discovering = false
    }

    function toggleDevice(device): void {
        if (!device || root.busy)
            return

        if (device.connected) {
            device.disconnect()
            return
        }

        device.trusted = true
        if (device.paired || device.bonded)
            device.connect()
        else
            device.pair()
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
    }

    onAdapterChanged: {
        if (!root.adapter) {
            root.applyPending = false
            root.lastError = ""
        }
    }
}
