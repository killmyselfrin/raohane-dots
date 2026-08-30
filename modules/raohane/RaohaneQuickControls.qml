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
            color: RaohaneTheme.surfaceSubtle
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
                color: RaohaneTheme.highlight
                opacity: 0.22
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
        radius: 18
        color: active ? RaohaneTheme.accentSoft : (hovered ? RaohaneTheme.surfaceHover : RaohaneTheme.surfaceSubtle)
        border.width: 1
        border.color: active ? RaohaneTheme.accentBorder : (hovered ? RaohaneTheme.borderStrong : RaohaneTheme.border)

        Behavior on color { ColorAnimation { duration: RaohaneTheme.animationFast } }
        Behavior on border.color { ColorAnimation { duration: RaohaneTheme.animationFast } }

        RowLayout {
            anchors {
                fill: parent
                leftMargin: 12
                rightMargin: 12
            }
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                radius: 12
                color: tile.active ? RaohaneTheme.surfaceRaised : RaohaneTheme.surfaceSubtle
                border.width: 1
                border.color: tile.active ? RaohaneTheme.accentBorder : RaohaneTheme.border

                RaohaneIcon {
                    anchors.centerIn: parent
                    text: tile.icon
                    iconSize: 17
                    color: tile.active || tile.hovered ? RaohaneTheme.accent : RaohaneTheme.textMuted
                    Behavior on color { ColorAnimation { duration: RaohaneTheme.animationFast } }
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
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 8
                    elide: Text.ElideRight
                }
            }

            Rectangle {
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18
                radius: 9
                color: tile.active ? RaohaneTheme.accentSoft : RaohaneTheme.surfaceSubtle
                border.width: 1
                border.color: tile.active ? RaohaneTheme.accentBorder : RaohaneTheme.border

                Rectangle {
                    anchors.centerIn: parent
                    width: tile.active ? 7 : 5
                    height: width
                    radius: width / 2
                    color: tile.active ? RaohaneTheme.accent : RaohaneTheme.textFaint
                    Behavior on width { NumberAnimation { duration: RaohaneTheme.animationFast; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: RaohaneTheme.animationFast } }
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
                color: control.hovered ? RaohaneTheme.surfaceHover : RaohaneTheme.surfaceSubtle
                border.width: 1
                border.color: control.hovered ? RaohaneTheme.borderStrong : RaohaneTheme.border

                Behavior on color { ColorAnimation { duration: RaohaneTheme.animationFast } }
                Behavior on border.color { ColorAnimation { duration: RaohaneTheme.animationFast } }

                RaohaneIcon {
                    anchors.centerIn: parent
                    text: control.icon
                    iconSize: 17
                    color: control.hovered ? RaohaneTheme.accent : RaohaneTheme.textMuted
                    Behavior on color { ColorAnimation { duration: RaohaneTheme.animationFast } }
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
                        color: control.hovered ? RaohaneTheme.surfaceHover : RaohaneTheme.surfaceSubtle
                        border.width: 1
                        border.color: control.hovered ? RaohaneTheme.borderStrong : RaohaneTheme.border

                        Text {
                            id: valueLabel
                            anchors.centerIn: parent
                            text: control.displayText
                            color: control.hovered ? RaohaneTheme.accent : RaohaneTheme.textMuted
                            font.pixelSize: 8
                            font.weight: Font.DemiBold
                        }
                    }
                }

                Item {
                    id: sliderArea
                    Layout.fillWidth: true
                    Layout.preferredHeight: 18

                    Rectangle {
                        id: track
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                        }
                        height: dragArea.pressed ? 7 : 6
                        radius: height / 2
                        color: RaohaneTheme.surfaceDeep
                        border.width: 1
                        border.color: control.hovered ? RaohaneTheme.borderStrong : RaohaneTheme.border

                        Rectangle {
                            width: Math.max(0, Math.min(parent.width, control.shownValue * parent.width))
                            height: parent.height
                            radius: parent.radius
                            color: RaohaneTheme.accent
                        }
                    }

                    Rectangle {
                        id: handle
                        width: dragArea.pressed ? 17 : (dragArea.containsMouse ? 16 : 14)
                        height: width
                        radius: width / 2
                        x: Math.max(0, Math.min(sliderArea.width - width,
                            control.shownValue * sliderArea.width - width / 2))
                        anchors.verticalCenter: parent.verticalCenter
                        color: RaohaneTheme.surfaceRaised
                        border.width: 2
                        border.color: RaohaneTheme.accent

                        Behavior on width { NumberAnimation { duration: RaohaneTheme.animationFast; easing.type: Easing.OutCubic } }
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
