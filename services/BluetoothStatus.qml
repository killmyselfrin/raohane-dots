pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.modules.raohane.services

// Compatibility facade. Device discovery/control is owned by RaohaneBluetooth
// through bluetoothctl so inherited surfaces do not create a second BlueZ
// object-manager connection.
Singleton {
    id: root

    readonly property bool available: RaohaneBluetooth.available
    readonly property bool enabled: RaohaneBluetooth.enabled
    readonly property var firstActiveDevice: RaohaneBluetooth.firstConnectedDevice
    readonly property int activeDeviceCount: RaohaneBluetooth.connectedCount
    readonly property bool connected: RaohaneBluetooth.connected

    readonly property var connectedDevices: RaohaneBluetooth.connectedDevices
    readonly property var pairedButNotConnectedDevices: []
    readonly property var unpairedDevices: []
    readonly property var friendlyDeviceList: connectedDevices

    function sortFunction(a, b): int {
        return String(a?.name ?? "").localeCompare(String(b?.name ?? ""))
    }
}
