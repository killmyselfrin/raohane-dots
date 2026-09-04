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
    Layout.preferredHeight: visible ? 62 : 0
    surfaceRadius: 15
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
    border.color: root.menuOpen || root.active ? RaohaneTheme.accentBorder
        : root.hovered ? RaohaneTheme.borderStrong
        : RaohaneTheme.borderFaint

    Behavior on border.color {
        ColorAnimation { duration: RaohaneMotion.micro }
    }

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

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 9
        anchors.rightMargin: 9
        anchors.topMargin: 8
        anchors.bottomMargin: 8
        spacing: 9

        Rectangle {
            Layout.preferredWidth: 31
            Layout.preferredHeight: 31
            Layout.alignment: Qt.AlignVCenter
            radius: 10
            color: root.active || root.menuOpen ? RaohaneTheme.accentSoft
                : root.hovered ? RaohaneTheme.surfaceHover
                : RaohaneTheme.surfaceSubtle
            border.width: 1
            border.color: root.active || root.menuOpen ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint

            Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
            Behavior on border.color { ColorAnimation { duration: RaohaneMotion.micro } }

            RaohaneIcon {
                anchors.centerIn: parent
                text: root.currentIcon
                iconSize: 16
                fill: root.active ? 1 : root.hovered ? 0.30 : 0
                symbolWeight: root.active ? 560 : root.hovered ? 500 : 430
                grade: root.active ? 40 : root.hovered ? 20 : 0
                color: root.active || root.hovered || root.menuOpen ? RaohaneTheme.accent : RaohaneTheme.textMuted
                scale: pointer.pressed ? 0.92 : 1

                Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
                Behavior on scale {
                    NumberAnimation { duration: RaohaneMotion.micro; easing.type: RaohaneMotion.easeStandard }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 1

            Text {
                Layout.fillWidth: true
                text: root.definition?.label ?? root.tileId
                color: RaohaneTheme.text
                font.pixelSize: 9
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                Rectangle {
                    Layout.preferredWidth: 4
                    Layout.preferredHeight: 4
                    radius: 2
                    color: root.active ? RaohaneTheme.accent : RaohaneTheme.textFaint
                    opacity: root.active ? 0.95 : 0.48

                    Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
                }

                Text {
                    Layout.fillWidth: true
                    text: root.subtitle
                    color: root.active ? RaohaneTheme.textMuted : RaohaneTheme.textFaint
                    font.pixelSize: 7
                    elide: Text.ElideRight
                }
            }
        }

        RaohaneIcon {
            visible: root.showMenu
            Layout.preferredWidth: root.showMenu ? 14 : 0
            Layout.alignment: Qt.AlignVCenter
            text: "expand_more"
            iconSize: 12
            color: root.menuOpen ? RaohaneTheme.accent : RaohaneTheme.textFaint
            rotation: root.menuOpen ? 180 : 0

            Behavior on rotation {
                NumberAnimation { duration: RaohaneMotion.micro; easing.type: RaohaneMotion.easeStandard }
            }
            Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
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
