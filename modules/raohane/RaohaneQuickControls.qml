pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

import qs.modules.raohane.config
import qs.modules.raohane.services

Item {
    id: root

    property var screen
    property bool gameModeActive: false
    readonly property var brightnessMonitor: RaohaneDisplay.getMonitorForScreen(screen)
    readonly property real brightnessValue: RaohaneDisplay.compositeValue(screen)

    implicitHeight: content.implicitHeight

    ColumnLayout {
        id: content
        anchors {
            left: parent.left
            right: parent.right
        }
        spacing: 11

        GridLayout {
            id: toggleGrid
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 10
            rowSpacing: 10

            QuickTile {
                Layout.fillWidth: true
                icon: RaohaneNetwork.materialSymbol
                title: qsTr("Network")
                subtitle: RaohaneNetwork.networkName || qsTr("Disconnected")
                active: RaohaneNetwork.wifiStatus !== "disabled"
                onPrimary: RaohaneNetwork.toggleWifi()
                onSecondary: {
                    const command = RaohaneNetwork.ethernet ? RaohaneConfig.networkEthernetCommand : RaohaneConfig.networkCommand
                    if (command && command.length > 0)
                        Quickshell.execDetached(["bash", "-c", command])
                }
            }

            QuickTile {
                Layout.fillWidth: true
                visible: RaohaneBluetooth.available
                icon: RaohaneBluetooth.connected ? "bluetooth_connected"
                    : RaohaneBluetooth.enabled ? "bluetooth" : "bluetooth_disabled"
                title: qsTr("Bluetooth")
                subtitle: RaohaneBluetooth.firstConnectedName.length > 0
                    ? RaohaneBluetooth.firstConnectedName
                    : (RaohaneBluetooth.enabled ? qsTr("On") : qsTr("Off"))
                active: RaohaneBluetooth.enabled
                onPrimary: RaohaneBluetooth.toggle()
                onSecondary: {
                    const command = RaohaneConfig.bluetoothCommand
                    if (command && command.length > 0)
                        Quickshell.execDetached(["bash", "-c", command])
                }
            }

            QuickTile {
                Layout.fillWidth: true
                icon: RaohaneConfig.nightLightAutomatic ? "night_sight_auto" : "bedtime"
                title: qsTr("Night Light")
                subtitle: RaohaneConfig.nightLightAutomatic ? qsTr("Automatic") : qsTr("Manual")
                active: RaohaneDisplay.temperatureActive
                onPrimary: RaohaneDisplay.toggleTemperature()
                onSecondary: RaohaneConfig.nightLightAutomatic = !RaohaneConfig.nightLightAutomatic
            }

            QuickTile {
                Layout.fillWidth: true
                icon: "gamepad"
                title: qsTr("Game Mode")
                subtitle: root.gameModeActive ? qsTr("Low latency") : qsTr("Desktop effects")
                active: root.gameModeActive
                onPrimary: root.setGameMode(!root.gameModeActive)
                onSecondary: root.setGameMode(false)
            }

            QuickTile {
                Layout.fillWidth: true
                icon: "coffee"
                title: qsTr("Keep Awake")
                subtitle: RaohaneIdle.inhibit ? qsTr("Sleep blocked") : qsTr("Normal idle")
                active: RaohaneIdle.inhibit
                onPrimary: RaohaneIdle.toggleInhibit()
            }

            QuickTile {
                Layout.fillWidth: true
                visible: RaohaneEasyEffects.available
                icon: "instant_mix"
                title: qsTr("EasyEffects")
                subtitle: RaohaneEasyEffects.active ? qsTr("Processing") : qsTr("Bypassed")
                active: RaohaneEasyEffects.active
                onPrimary: RaohaneEasyEffects.toggle()
                onSecondary: RaohaneEasyEffects.launchUi()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: sliderColumn.implicitHeight + 22
            radius: 20
            color: "#76171420"
            border.width: 1
            border.color: RaohaneTheme.border

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    leftMargin: 18
                    rightMargin: 18
                }
                height: 1
                color: "#22ffffff"
            }

            ColumnLayout {
                id: sliderColumn
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 11
                }
                spacing: 7

                ControlSlider {
                    Layout.fillWidth: true
                    visible: RaohaneConfig.quickSliderBrightness
                    icon: RaohaneDisplay.gamma === 100 ? "brightness_medium" : "wb_twilight"
                    title: RaohaneDisplay.gamma === 100 ? qsTr("Brightness") : qsTr("Gamma")
                    displayText: RaohaneDisplay.gamma === 100
                        ? Math.round((root.brightnessMonitor?.brightness ?? 0.5) * 100) + "%"
                        : Math.round(RaohaneDisplay.gamma) + "%"
                    liveValue: root.brightnessValue
                    onValueChangedByUser: value => RaohaneDisplay.setComposite(root.screen, value)
                }

                ControlSlider {
                    Layout.fillWidth: true
                    visible: RaohaneConfig.quickSliderVolume
                    icon: RaohaneAudio.muted ? "volume_off" : "volume_up"
                    title: qsTr("Volume")
                    displayText: Math.round(RaohaneAudio.volume * 100) + "%"
                    liveValue: RaohaneAudio.volume
                    onValueChangedByUser: value => RaohaneAudio.setVolume(value)
                    onIconTriggered: RaohaneAudio.toggleMute()
                }

                ControlSlider {
                    Layout.fillWidth: true
                    visible: RaohaneConfig.quickSliderMic
                    icon: RaohaneAudio.microphoneMuted ? "mic_off" : "mic"
                    title: qsTr("Microphone")
                    displayText: Math.round(RaohaneAudio.microphoneVolume * 100) + "%"
                    liveValue: RaohaneAudio.microphoneVolume
                    onValueChangedByUser: value => RaohaneAudio.setMicrophoneVolume(value)
                    onIconTriggered: RaohaneAudio.toggleMicrophoneMute()
                }
            }
        }
    }

    function refreshGameMode(): void {
        if (!gameModeProbe.running)
            gameModeProbe.running = true
    }

    Process {
        id: gameModeProbe
        command: ["hyprctl", "getoption", "animations:enabled", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.gameModeActive = Number(JSON.parse(text).int) === 0
                } catch (error) {
                    root.gameModeActive = false
                }
            }
        }
    }

    function setGameMode(enabled: bool): void {
        root.gameModeActive = enabled
        if (enabled) {
            Quickshell.execDetached([
                "hyprctl", "--batch",
                "keyword animations:enabled 0; keyword decoration:shadow:enabled 0; keyword decoration:blur:enabled 0; keyword general:gaps_in 0; keyword general:gaps_out 0; keyword general:border_size 1; keyword decoration:rounding 0; keyword general:allow_tearing 1"
            ])
        } else {
            Quickshell.execDetached(["hyprctl", "reload"])
        }
    }

    component QuickTile: Rectangle {
        id: tile

        required property string icon
        required property string title
        property string subtitle: ""
        property bool active: false
        signal primary()
        signal secondary()

        readonly property bool hovered: pointer.containsMouse

        Layout.preferredHeight: 66
        radius: 20
        color: active ? "#8b2b203b" : (hovered ? "#841c1826" : "#76171420")
        border.width: 1
        border.color: active ? RaohaneTheme.accent : (hovered ? "#58ffffff" : RaohaneTheme.border)

        Behavior on color { ColorAnimation { duration: 140 } }
        Behavior on border.color { ColorAnimation { duration: 140 } }

        Rectangle {
            anchors {
                fill: parent
                margins: 1
            }
            radius: tile.radius - 1
            color: "transparent"
            border.width: 1
            border.color: tile.active ? "#1fffffff" : (tile.hovered ? "#12ffffff" : "transparent")

            Behavior on border.color { ColorAnimation { duration: 140 } }
        }

        Rectangle {
            visible: tile.active
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
                leftMargin: 5
                topMargin: 16
                bottomMargin: 16
            }
            width: 3
            radius: 2
            color: RaohaneTheme.accent
            opacity: 0.9
        }

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                leftMargin: 18
                rightMargin: 18
            }
            height: 1
            color: tile.hovered || tile.active ? "#26ffffff" : "#10ffffff"

            Behavior on color { ColorAnimation { duration: 140 } }
        }

        RowLayout {
            anchors {
                fill: parent
                leftMargin: 12
                rightMargin: 12
            }
            spacing: 10

            Item {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40

                Rectangle {
                    anchors.centerIn: parent
                    width: tile.active ? 40 : (tile.hovered ? 38 : 36)
                    height: width
                    radius: 14
                    color: RaohaneTheme.accent
                    opacity: tile.active ? 0.13 : (tile.hovered ? 0.08 : 0.03)

                    Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 140 } }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 34
                    height: 34
                    radius: 12
                    color: tile.active ? "#2effffff" : (tile.hovered ? "#20ffffff" : "#14ffffff")
                    border.width: 1
                    border.color: tile.active ? "#44ffffff" : (tile.hovered ? "#26ffffff" : "#12ffffff")

                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on border.color { ColorAnimation { duration: 140 } }

                    RaohaneIcon {
                        anchors.centerIn: parent
                        text: tile.icon
                        iconSize: 18
                        color: tile.active || tile.hovered ? RaohaneTheme.accent : RaohaneTheme.textMuted

                        Behavior on color { ColorAnimation { duration: 140 } }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    text: tile.title
                    color: RaohaneTheme.text
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: tile.subtitle
                    color: tile.active ? "#c8ffffff" : RaohaneTheme.textMuted
                    font.pixelSize: 8
                    elide: Text.ElideRight

                    Behavior on color { ColorAnimation { duration: 140 } }
                }
            }

            Item {
                Layout.preferredWidth: 22
                Layout.preferredHeight: 22

                Rectangle {
                    anchors.centerIn: parent
                    width: 18
                    height: 18
                    radius: 9
                    color: tile.active ? RaohaneTheme.accentSoft : "#10ffffff"
                    border.width: 1
                    border.color: tile.active ? "#66ffffff" : "#18ffffff"

                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on border.color { ColorAnimation { duration: 140 } }

                    Rectangle {
                        anchors.centerIn: parent
                        width: tile.active ? 7 : 5
                        height: width
                        radius: width / 2
                        color: tile.active ? RaohaneTheme.accent : "#5affffff"

                        Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 140 } }
                    }
                }
            }
        }

        MouseArea {
            id: pointer
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton)
                    tile.secondary()
                else
                    tile.primary()
            }
        }
    }

    component ControlSlider: Item {
        id: control

        required property string icon
        required property string title
        property string displayText: ""
        property real liveValue: 0
        signal valueChangedByUser(real value)
        signal iconTriggered()

        readonly property real clampedLiveValue: Math.max(0, Math.min(1, Number(liveValue) || 0))
        readonly property real shownValue: dragArea.pressed ? dragValue : clampedLiveValue
        readonly property bool hovered: dragArea.containsMouse || iconMouse.containsMouse
        property real dragValue: clampedLiveValue

        implicitHeight: 42

        RowLayout {
            anchors.fill: parent
            spacing: 9

            Rectangle {
                width: 32
                height: 32
                radius: 11
                color: control.hovered ? RaohaneTheme.accentSoft : "#18ffffff"
                border.width: 1
                border.color: control.hovered ? "#55ffffff" : "#16ffffff"

                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on border.color { ColorAnimation { duration: 120 } }

                RaohaneIcon {
                    anchors.centerIn: parent
                    text: control.icon
                    iconSize: 17
                    color: control.hovered ? RaohaneTheme.accent : RaohaneTheme.textMuted

                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                MouseArea {
                    id: iconMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: control.iconTriggered()
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: control.title
                        color: RaohaneTheme.text
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        implicitWidth: valueLabel.implicitWidth + 12
                        implicitHeight: 17
                        radius: 8.5
                        color: control.hovered ? RaohaneTheme.accentSoft : "#14ffffff"
                        border.width: 1
                        border.color: control.hovered ? "#38ffffff" : "transparent"

                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        Text {
                            id: valueLabel
                            anchors.centerIn: parent
                            text: control.displayText
                            color: control.hovered ? RaohaneTheme.accent : RaohaneTheme.textMuted
                            font.pixelSize: 8
                            font.weight: Font.DemiBold

                            Behavior on color { ColorAnimation { duration: 120 } }
                        }
                    }
                }

                Item {
                    id: sliderArea
                    Layout.fillWidth: true
                    Layout.preferredHeight: 18

                    Rectangle {
                        id: trackGlow
                        anchors {
                            left: parent.left
                            verticalCenter: parent.verticalCenter
                        }
                        width: Math.max(0, Math.min(parent.width, control.shownValue * parent.width))
                        height: dragArea.pressed ? 13 : 11
                        radius: height / 2
                        color: RaohaneTheme.accent
                        opacity: dragArea.pressed ? 0.18 : (dragArea.containsMouse ? 0.13 : 0.08)

                        Behavior on height { NumberAnimation { duration: 100 } }
                        Behavior on opacity { NumberAnimation { duration: 100 } }
                    }

                    Rectangle {
                        id: track
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                        }
                        height: dragArea.pressed ? 7 : 6
                        radius: height / 2
                        color: dragArea.containsMouse ? "#35ffffff" : "#28ffffff"
                        border.width: 1
                        border.color: dragArea.containsMouse ? "#24ffffff" : "#14ffffff"

                        Behavior on height { NumberAnimation { duration: 100 } }
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Behavior on border.color { ColorAnimation { duration: 100 } }

                        Rectangle {
                            width: Math.max(0, Math.min(parent.width, control.shownValue * parent.width))
                            height: parent.height
                            radius: parent.radius
                            color: RaohaneTheme.accent
                        }
                    }

                    Rectangle {
                        id: handleHalo
                        width: dragArea.pressed ? 29 : (dragArea.containsMouse ? 25 : 21)
                        height: width
                        radius: width / 2
                        x: Math.max(-width / 2, Math.min(sliderArea.width - width / 2,
                            control.shownValue * sliderArea.width - width / 2))
                        anchors.verticalCenter: parent.verticalCenter
                        color: RaohaneTheme.accent
                        opacity: dragArea.pressed ? 0.16 : (dragArea.containsMouse ? 0.10 : 0.04)

                        Behavior on width { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
                        Behavior on opacity { NumberAnimation { duration: 110 } }
                    }

                    Rectangle {
                        id: handle
                        width: dragArea.pressed ? 18 : (dragArea.containsMouse ? 16 : 14)
                        height: width
                        radius: width / 2
                        x: Math.max(0, Math.min(sliderArea.width - width,
                            control.shownValue * sliderArea.width - width / 2))
                        anchors.verticalCenter: parent.verticalCenter
                        color: RaohaneTheme.text
                        border.width: 2
                        border.color: RaohaneTheme.accent

                        Behavior on width { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }

                        Rectangle {
                            width: dragArea.pressed ? 6 : 4
                            height: width
                            radius: width / 2
                            anchors.centerIn: parent
                            color: RaohaneTheme.accent

                            Behavior on width { NumberAnimation { duration: 100 } }
                        }
                    }

                    MouseArea {
                        id: dragArea
                        anchors.fill: parent
                        hoverEnabled: true
                        preventStealing: true
                        acceptedButtons: Qt.LeftButton
                        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.PointingHandCursor

                        function valueForX(mouseX: real): real {
                            if (width <= 0)
                                return control.clampedLiveValue
                            return Math.max(0, Math.min(1, mouseX / width))
                        }

                        function applyPosition(mouseX: real): void {
                            control.dragValue = valueForX(mouseX)
                            control.valueChangedByUser(control.dragValue)
                        }

                        onPressed: mouse => applyPosition(mouse.x)
                        onPositionChanged: mouse => {
                            if (pressed)
                                applyPosition(mouse.x)
                        }
                        onReleased: mouse => applyPosition(mouse.x)
                    }
                }
            }
        }
    }
}
