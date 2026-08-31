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

        RaohaneSurface {
            Layout.fillWidth: true
            Layout.preferredHeight: sliderColumn.implicitHeight + 22
            surfaceRadius: RaohaneTheme.radiusLarge
            showSheen: false
            color: RaohaneTheme.surfaceSubtle
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
                opacity: 0.18
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

    component QuickTile: RaohaneSurface {
        id: tile

        required property string icon
        required property string title
        property string subtitle: ""
        signal primary()
        signal secondary()

        Layout.preferredHeight: 66
        surfaceRadius: RaohaneTheme.radius
        showSheen: false
        hovered: pointer.containsMouse || activeFocus
        pressed: pointer.pressed
        interactive: true
        activeFocusOnTab: true

        RowLayout {
            anchors {
                fill: parent
                leftMargin: 12
                rightMargin: 12
            }
            spacing: 10

            RaohaneSurface {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                surfaceRadius: 12
                showSheen: false
                raised: tile.active
                active: tile.active

                RaohaneIcon {
                    anchors.centerIn: parent
                    text: tile.icon
                    iconSize: 18
                    fill: tile.active ? 1 : tile.hovered ? 0.28 : 0
                    symbolWeight: tile.active ? 560 : tile.hovered ? 500 : 430
                    grade: tile.active ? 40 : tile.hovered ? 20 : 0
                    color: tile.active || tile.hovered ? RaohaneTheme.accent : RaohaneTheme.textMuted
                    scale: pointer.pressed ? 0.92 : 1

                    Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
                    Behavior on scale {
                        NumberAnimation { duration: RaohaneMotion.micro; easing.type: RaohaneMotion.easeStandard }
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
                    scale: pointer.pressed ? 0.82 : 1

                    Behavior on width {
                        NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeEmphasized }
                    }
                    Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
                    Behavior on scale {
                        NumberAnimation { duration: RaohaneMotion.micro; easing.type: RaohaneMotion.easeStandard }
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
            onPressed: tile.forceActiveFocus()
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton)
                    tile.secondary()
                else
                    tile.primary()
            }
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                tile.primary()
                event.accepted = true
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
        readonly property bool hovered: valueSlider.hovered || iconButton.hovered || iconButton.activeFocus

        implicitHeight: 42

        RowLayout {
            anchors.fill: parent
            spacing: 9

            RaohaneIconButton {
                id: iconButton
                buttonSize: 32
                iconSize: 17
                icon: control.icon
                emphasized: control.hovered
                onClicked: control.iconTriggered()
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

                    RaohaneSurface {
                        implicitWidth: valueLabel.implicitWidth + 14
                        implicitHeight: 19
                        surfaceRadius: 9
                        showSheen: false
                        hovered: control.hovered
                        border.color: control.hovered ? RaohaneTheme.borderStrong : RaohaneTheme.border

                        Text {
                            id: valueLabel
                            anchors.centerIn: parent
                            text: control.displayText
                            color: control.hovered ? RaohaneTheme.accent : RaohaneTheme.textMuted
                            font.pixelSize: 8
                            font.weight: Font.DemiBold

                            Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
                        }
                    }
                }

                RaohaneSlider {
                    id: valueSlider
                    Layout.fillWidth: true
                    Layout.preferredHeight: 20
                    from: 0
                    to: 1
                    stepSize: 0.01
                    value: control.clampedLiveValue
                    onMoved: value => control.valueChangedByUser(value)
                }
            }
        }
    }
}
