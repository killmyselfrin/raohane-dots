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
    readonly property bool tileBusy: (root.tileId === "network" && RaohaneNetwork.wifiBusy)
        || (root.tileId === "gameMode" && RaohanePerformance.busy)
        || (root.tileId === "bluetooth" && RaohaneBluetooth.busy)
        || (root.tileId === "easyEffects" && RaohaneEasyEffects.busy)
    readonly property bool tileError: (root.tileId === "network" && RaohaneNetwork.wifiToggleError.length > 0)
        || (root.tileId === "gameMode" && RaohanePerformance.lastError.length > 0)
        || (root.tileId === "bluetooth" && RaohaneBluetooth.lastError.length > 0)
        || (root.tileId === "easyEffects" && RaohaneEasyEffects.lastError.length > 0)
    readonly property bool showMenu: root.tileId === "network"
    readonly property bool menuOpen: root.tileId === "network" && root.pickerMode === "wifi"
    readonly property string currentIcon: root.tileBusy ? "progress_activity"
        : root.tileId === "network" ? RaohaneNetwork.materialSymbol
        : root.tileId === "bluetooth" ? (RaohaneBluetooth.connected ? "bluetooth_connected" : RaohaneBluetooth.enabled ? "bluetooth" : "bluetooth_disabled")
        : root.tileId === "nightLight" ? (RaohaneConfig.nightLightAutomatic ? "night_sight_auto" : "bedtime")
        : root.definition?.icon ?? "tune"
    readonly property string subtitle: root.tileId === "network" ? (root.tileBusy
            ? qsTr("Applying…")
            : root.tileError
                ? qsTr("Wi-Fi action failed")
                : RaohaneNetwork.networkName.length > 0
                    ? RaohaneNetwork.networkName
                    : !RaohaneNetwork.wifiEnabled
                        ? qsTr("Wi-Fi off")
                        : RaohaneNetwork.ethernet
                            ? qsTr("Ethernet")
                            : qsTr("Not connected"))
        : root.tileId === "bluetooth" ? (root.tileBusy
            ? qsTr("Applying…")
            : root.tileError
                ? qsTr("Bluetooth action failed")
                : RaohaneBluetooth.firstConnectedName.length > 0
                    ? RaohaneBluetooth.firstConnectedName
                    : (RaohaneBluetooth.enabled ? qsTr("On") : qsTr("Off")))
        : root.tileId === "nightLight" ? (RaohaneConfig.nightLightAutomatic ? qsTr("Automatic") : qsTr("Manual"))
        : root.tileId === "gameMode" ? (root.tileBusy
            ? qsTr("Applying…")
            : root.tileError
                ? qsTr("Hyprland rejected the change")
                : RaohanePerformance.gameModeActive ? qsTr("Low latency") : qsTr("Desktop effects"))
        : root.tileId === "keepAwake" ? (RaohaneIdle.inhibit ? qsTr("Sleep blocked") : qsTr("Normal idle"))
        : root.tileId === "easyEffects" ? (root.tileBusy
            ? qsTr("Applying…")
            : root.tileError
                ? qsTr("EasyEffects action failed")
                : RaohaneEasyEffects.active ? qsTr("Processing") : qsTr("Bypassed"))
        : ""

    visible: root.available
    enabled: root.available && !root.tileBusy
    Layout.preferredHeight: visible ? 62 : 0
    surfaceRadius: 15
    active: root.tileActive
    showSheen: false
    transparentIdle: false
    hovered: pointer.containsMouse || activeFocus
    pressed: pointer.pressed
    interactive: true
    hoverScale: 1
    pressedScale: 1
    activeFocusOnTab: visible && enabled
    feedback: root.showMenu ? "navigate" : "tap"
    border.color: root.tileError ? RaohaneTheme.critical
        : root.menuOpen || root.active ? RaohaneTheme.accentBorder
        : root.hovered ? RaohaneTheme.borderStrong
        : RaohaneTheme.borderFaint

    Behavior on border.color { ColorAnimation { duration: RaohaneMotion.micro } }
    Behavior on opacity { NumberAnimation { duration: RaohaneMotion.micro } }

    function triggerPrimary(): void {
        if (root.tileBusy)
            return
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
        if (root.tileBusy)
            return
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

    Rectangle {
        visible: root.active || root.menuOpen || root.tileError
        z: 3
        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
            leftMargin: 2
        }
        width: 3
        height: 26
        radius: 2
        color: root.tileError ? RaohaneTheme.critical : RaohaneTheme.accent
        opacity: root.tileError ? 0.92 : root.menuOpen ? 1 : 0.76

        Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
        Behavior on opacity {
            NumberAnimation { duration: RaohaneMotion.micro; easing.type: RaohaneMotion.easeStandard }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.topMargin: 8
        anchors.bottomMargin: 8
        spacing: 10

        Rectangle {
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            Layout.alignment: Qt.AlignVCenter
            radius: 11
            color: root.tileError
                ? Qt.rgba(RaohaneTheme.critical.r, RaohaneTheme.critical.g, RaohaneTheme.critical.b, 0.10)
                : root.active || root.menuOpen ? RaohaneTheme.accentSoft
                : root.hovered ? RaohaneTheme.surfaceHover
                : RaohaneTheme.surfaceSubtle
            border.width: 1
            border.color: root.tileError ? RaohaneTheme.critical
                : root.active || root.menuOpen ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint

            Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
            Behavior on border.color { ColorAnimation { duration: RaohaneMotion.micro } }

            RaohaneIcon {
                anchors.centerIn: parent
                text: root.currentIcon
                iconSize: 18
                fill: root.active || root.tileError ? 1 : root.hovered ? 0.4 : 0
                symbolWeight: root.active || root.tileError ? 560 : root.hovered ? 500 : 430
                grade: root.active ? 40 : 0
                color: root.tileError ? RaohaneTheme.critical
                    : root.active || root.hovered || root.menuOpen ? RaohaneTheme.accent : RaohaneTheme.textMuted

                Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }

                RotationAnimation on rotation {
                    running: root.tileBusy
                    loops: Animation.Infinite
                    from: 0
                    to: 360
                    duration: 850
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
                color: root.tileError ? RaohaneTheme.critical : RaohaneTheme.text
                font.pixelSize: 10
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: root.subtitle
                color: root.tileError ? RaohaneTheme.critical
                    : root.active ? RaohaneTheme.textMuted : RaohaneTheme.textFaint
                font.pixelSize: 8
                elide: Text.ElideRight
            }
        }

        Rectangle {
            Layout.preferredWidth: 7
            Layout.preferredHeight: 7
            Layout.alignment: Qt.AlignVCenter
            radius: 4
            color: root.tileError ? RaohaneTheme.critical
                : root.active ? RaohaneTheme.accent : RaohaneTheme.borderStrong
            opacity: root.active || root.tileError ? 1 : 0.55

            Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
        }

        RaohaneIcon {
            visible: root.showMenu
            Layout.preferredWidth: root.showMenu ? 14 : 0
            Layout.alignment: Qt.AlignVCenter
            text: "expand_more"
            iconSize: 13
            color: root.menuOpen ? RaohaneTheme.accent : RaohaneTheme.textFaint
            rotation: root.transformMotionAllowed && root.menuOpen ? 180 : 0

            Behavior on rotation {
                enabled: root.transformMotionAllowed
                NumberAnimation { duration: RaohaneMotion.micro; easing.type: RaohaneMotion.easeStandard }
            }
        }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onPressed: root.forceActiveFocus()
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                root.triggerSecondary()
            else
                root.triggerPrimary()
        }
    }

    Keys.onPressed: event => {
        if (!root.enabled)
            return
        if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.triggerPrimary()
            event.accepted = true
        }
    }
}
