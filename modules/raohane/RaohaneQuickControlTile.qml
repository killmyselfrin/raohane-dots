pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.config
import qs.modules.raohane.services

RaohaneSurface {
    id: root

    property string tileId: ""
    property string pickerMode: ""
    signal pickerRequested(string mode)

    readonly property var definition: RaohaneQuickControlRegistry.definition(root.tileId)
    readonly property bool available: root.tileId === "bluetooth" ? RaohaneBluetooth.available
        : root.tileId === "easyEffects" ? RaohaneEasyEffects.available
        : root.definition !== null
    readonly property bool tileActive: root.tileId === "network" ? RaohaneNetwork.wifiStatus !== "disabled"
        : root.tileId === "bluetooth" ? RaohaneBluetooth.enabled
        : root.tileId === "nightLight" ? RaohaneDisplay.temperatureActive
        : root.tileId === "gameMode" ? RaohanePerformance.gameModeActive
        : root.tileId === "keepAwake" ? RaohaneIdle.inhibit
        : root.tileId === "easyEffects" ? RaohaneEasyEffects.active
        : false
    readonly property bool showMenu: root.tileId === "network"
    readonly property bool menuOpen: root.tileId === "network" && root.pickerMode === "wifi"
    readonly property string currentIcon: root.tileId === "network" ? RaohaneNetwork.materialSymbol
        : root.tileId === "bluetooth" ? (RaohaneBluetooth.connected ? "bluetooth_connected" : RaohaneBluetooth.enabled ? "bluetooth" : "bluetooth_disabled")
        : root.tileId === "nightLight" ? (RaohaneConfig.nightLightAutomatic ? "night_sight_auto" : "bedtime")
        : root.definition?.icon ?? "tune"
    readonly property string subtitle: root.tileId === "network" ? (RaohaneNetwork.networkName || qsTr("Disconnected"))
        : root.tileId === "bluetooth" ? (RaohaneBluetooth.firstConnectedName.length > 0 ? RaohaneBluetooth.firstConnectedName : (RaohaneBluetooth.enabled ? qsTr("On") : qsTr("Off")))
        : root.tileId === "nightLight" ? (RaohaneConfig.nightLightAutomatic ? qsTr("Automatic") : qsTr("Manual"))
        : root.tileId === "gameMode" ? (RaohanePerformance.gameModeActive ? qsTr("Low latency") : qsTr("Desktop effects"))
        : root.tileId === "keepAwake" ? (RaohaneIdle.inhibit ? qsTr("Sleep blocked") : qsTr("Normal idle"))
        : root.tileId === "easyEffects" ? (RaohaneEasyEffects.active ? qsTr("Processing") : qsTr("Bypassed"))
        : ""

    visible: root.available
    Layout.preferredHeight: visible ? 64 : 0
    surfaceRadius: 16
    active: root.tileActive
    showSheen: false
    transparentIdle: !root.active && !root.menuOpen
    hovered: pointer.containsMouse || activeFocus
    pressed: pointer.pressed
    interactive: true
    hoverScale: RaohaneMotion.subtleHoverScale
    pressedScale: RaohaneMotion.softPressScale
    activeFocusOnTab: visible
    feedback: root.showMenu ? "navigate" : "tap"
    border.color: root.menuOpen ? RaohaneTheme.accentBorder
        : root.active ? RaohaneTheme.accentBorder
        : root.hovered ? RaohaneTheme.borderStrong
        : RaohaneTheme.border

    function triggerPrimary(): void {
        switch (root.tileId) {
        case "network":
            root.pickerRequested("wifi")
            break
        case "bluetooth":
            RaohaneBluetooth.toggle()
            break
        case "nightLight":
            RaohaneDisplay.toggleTemperature()
            break
        case "gameMode":
            RaohanePerformance.toggleGameMode()
            break
        case "keepAwake":
            RaohaneIdle.toggleInhibit()
            break
        case "easyEffects":
            RaohaneEasyEffects.toggle()
            break
        }
    }

    function triggerSecondary(): void {
        switch (root.tileId) {
        case "network":
            RaohaneNetwork.toggleWifi()
            break
        case "bluetooth":
            RaohaneBluetooth.openManager()
            break
        case "nightLight":
            RaohaneConfig.nightLightAutomatic = !RaohaneConfig.nightLightAutomatic
            break
        case "gameMode":
            RaohanePerformance.setGameMode(false)
            break
        case "easyEffects":
            RaohaneEasyEffects.launchUi()
            break
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 11
        anchors.rightMargin: 11
        anchors.topMargin: 9
        anchors.bottomMargin: 9
        spacing: 3

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            RaohaneIcon {
                text: root.currentIcon
                iconSize: 18
                fill: root.active ? 1 : root.hovered ? 0.35 : 0
                symbolWeight: root.active ? 560 : root.hovered ? 500 : 430
                grade: root.active ? 40 : root.hovered ? 20 : 0
                color: root.active || root.hovered || root.menuOpen ? RaohaneTheme.accent : RaohaneTheme.textMuted
                scale: pointer.pressed ? 0.92 : 1

                Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
                Behavior on scale {
                    NumberAnimation { duration: RaohaneMotion.micro; easing.type: RaohaneMotion.easeStandard }
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                width: 6
                height: 6
                radius: 3
                color: root.active ? RaohaneTheme.accent : RaohaneTheme.surfaceSubtle
                border.width: root.active ? 0 : 1
                border.color: RaohaneTheme.border
                opacity: root.active ? 1 : 0.72

                Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
                Behavior on opacity { NumberAnimation { duration: RaohaneMotion.micro } }
            }

            RaohaneIcon {
                visible: root.showMenu
                text: "expand_more"
                iconSize: 12
                color: root.menuOpen ? RaohaneTheme.accent : RaohaneTheme.textFaint
                rotation: root.menuOpen ? 180 : 0
                Behavior on rotation {
                    NumberAnimation { duration: RaohaneMotion.micro; easing.type: RaohaneMotion.easeStandard }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: root.definition?.label ?? root.tileId
            color: RaohaneTheme.text
            font.pixelSize: 10
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Text {
            Layout.fillWidth: true
            text: root.subtitle
            color: RaohaneTheme.textMuted
            font.pixelSize: 7
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onPressed: root.forceActiveFocus()
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                root.triggerSecondary()
            else
                root.triggerPrimary()
        }
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.triggerPrimary()
            event.accepted = true
        }
    }
}
