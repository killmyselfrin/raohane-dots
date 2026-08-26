pragma Singleton

import QtQuick
import Quickshell.Bluetooth

QtObject {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: Bluetooth.adapters.values.length > 0
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property var connectedDevices: Bluetooth.devices.values.filter(device => device.connected)
    readonly property int connectedCount: connectedDevices.length
    readonly property bool connected: connectedCount > 0
    readonly property var firstConnectedDevice: connectedDevices.length > 0 ? connectedDevices[0] : null
    readonly property string firstConnectedName: firstConnectedDevice?.name ?? ""

    function setEnabled(value: bool): void {
        if (root.adapter)
            root.adapter.enabled = value
    }

    function toggle(): void {
        root.setEnabled(!root.enabled)
    }
}
