pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

import qs.services
import qs.modules.raohane.config
import qs.modules.raohane.services

Item {
    id: root

    property var screen
    property bool gameModeActive: false
    readonly property var brightnessMonitor: RaohaneDisplay.getMonitorForScreen(screen)
    readonly property real brightnessValue: RaohaneDisplay.compositeValue(screen)

    implicitHeight: content.implicitHeight

    Component.onCompleted: EasyEffects.fetchActiveState()

    ColumnLayout {
        id: content
        anchors {
            left: parent.left
            right: parent.right
        }
        spacing: 9

        GridLayout {
            id: toggleGrid
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 8
            rowSpacing: 8

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
                onSecondary: Quickshell.execDetached(["hyprctl", "reload"])
            }

            QuickTile {
                Layout.fillWidth: true
                icon: "coffee"
                title: qsTr("Keep Awake")
                subtitle: Idle.inhibit ? qsTr("Sleep blocked") : qsTr("Normal idle")
                active: Idle.inhibit
                onPrimary: Idle.toggleInhibit()
            }

            QuickTile {
                Layout.fillWidth: true
                visible: EasyEffects.available
                icon: "instant_mix"
                title: qsTr("EasyEffects")
                subtitle: EasyEffects.active ? qsTr("Processing") : qsTr("Bypassed")
                active: EasyEffects.active
                onPrimary: EasyEffects.toggle()
                onSecondary: Quickshell.execDetached(["bash", "-c", "flatpak run com.github.wwmm.easyeffects || easyeffects"])
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: sliderColumn.implicitHeight + 18
            radius: 17
            color: "#6f17141f"
            border.width: 1
            border.color: RaohaneTheme.border

            ColumnLayout {
                id: sliderColumn
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 9
                }
                spacing: 8

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

    Process {
        id: gameModeProbe
        running: true
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

        Layout.preferredHeight: 58
        radius: 17
        color: active ? RaohaneTheme.accentSoft : "#6f17141f"
        border.width: 1
        border.color: active || pointer.containsMouse ? RaohaneTheme.accent : RaohaneTheme.border

        RowLayout {
            anchors {
                fill: parent
                leftMargin: 11
                rightMargin: 10
            }
            spacing: 9

            Rectangle {
                width: 32
                height: 32
                radius: 11
                color: tile.active ? "#30ffffff" : "#18ffffff"

                RaohaneIcon {
                    anchors.centerIn: parent
                    text: tile.icon
                    iconSize: 18
                    color: tile.active ? RaohaneTheme.accent : RaohaneTheme.textMuted
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: -1

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
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 8
                    elide: Text.ElideRight
                }
            }

            Rectangle {
                width: 7
                height: 7
                radius: 4
                color: tile.active ? RaohaneTheme.accent : "#4dffffff"
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
        property real dragValue: clampedLiveValue

        implicitHeight: 38

        RowLayout {
            anchors.fill: parent
            spacing: 8

            Rectangle {
                width: 30
                height: 30
                radius: 10
                color: iconMouse.containsMouse ? RaohaneTheme.accentSoft : "#18ffffff"
                border.width: 1
                border.color: iconMouse.containsMouse ? RaohaneTheme.accent : "transparent"

                RaohaneIcon {
                    anchors.centerIn: parent
                    text: control.icon
                    iconSize: 17
                    color: RaohaneTheme.textMuted
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
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: control.title
                        color: RaohaneTheme.text
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: control.displayText
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 8
                    }
                }

                Item {
                    id: sliderArea
                    Layout.fillWidth: true
                    Layout.preferredHeight: 16

                    Rectangle {
                        id: track
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                        }
                        height: 5
                        radius: 3
                        color: "#2bffffff"

                        Rectangle {
                            width: Math.max(0, Math.min(parent.width, control.shownValue * parent.width))
                            height: parent.height
                            radius: parent.radius
                            color: RaohaneTheme.accent
                        }
                    }

                    Rectangle {
                        id: handle
                        width: dragArea.pressed ? 15 : 12
                        height: width
                        radius: width / 2
                        x: Math.max(0, Math.min(sliderArea.width - width,
                            control.shownValue * Math.max(0, sliderArea.width - width)))
                        anchors.verticalCenter: parent.verticalCenter
                        color: RaohaneTheme.text
                        border.width: 2
                        border.color: RaohaneTheme.accent

                        Behavior on width { NumberAnimation { duration: 90 } }
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
