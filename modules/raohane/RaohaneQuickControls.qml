pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

import qs
import qs.services
import qs.modules.common.widgets
import qs.modules.raohane.services

Item {
    id: root

    property var screen
    property bool gameModeActive: false
    readonly property var brightnessMonitor: Brightness.getMonitorForScreen(screen)
    readonly property real brightnessValue: Hyprsunset.gamma === 100
        ? 0.3 + (brightnessMonitor?.brightness ?? 0.5) * 0.7
        : (Hyprsunset.gamma - Hyprsunset.gammaLowerLimit) / (100 - Hyprsunset.gammaLowerLimit) * 0.3

    implicitHeight: content.implicitHeight

    Component.onCompleted: {
        Hyprsunset.fetchState()
        EasyEffects.fetchActiveState()
    }

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
                icon: Network.materialSymbol
                title: qsTr("Network")
                subtitle: Network.networkName || qsTr("Disconnected")
                active: Network.wifiStatus !== "disabled"
                onPrimary: Network.toggleWifi()
                onSecondary: {
                    const command = Network.ethernet ? Config.options.apps.networkEthernet : Config.options.apps.network
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
                    const command = Config.options.apps.bluetooth
                    if (command && command.length > 0)
                        Quickshell.execDetached(["bash", "-c", command])
                }
            }

            QuickTile {
                Layout.fillWidth: true
                icon: Config.options.light.night.automatic ? "night_sight_auto" : "bedtime"
                title: qsTr("Night Light")
                subtitle: Config.options.light.night.automatic ? qsTr("Automatic") : qsTr("Manual")
                active: Hyprsunset.temperatureActive
                onPrimary: Hyprsunset.toggleTemperature()
                onSecondary: Config.options.light.night.automatic = !Config.options.light.night.automatic
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
                    visible: Config.options.sidebar.quickSliders.showBrightness
                    icon: Hyprsunset.gamma === 100 ? "brightness_medium" : "wb_twilight"
                    title: Hyprsunset.gamma === 100 ? qsTr("Brightness") : qsTr("Gamma")
                    displayText: Hyprsunset.gamma === 100
                        ? Math.round((root.brightnessMonitor?.brightness ?? 0.5) * 100) + "%"
                        : Math.round(Hyprsunset.gamma) + "%"
                    liveValue: root.brightnessValue
                    onValueChangedByUser: value => root.setBrightnessComposite(value)
                }

                ControlSlider {
                    Layout.fillWidth: true
                    visible: Config.options.sidebar.quickSliders.showVolume
                    icon: RaohaneAudio.muted ? "volume_off" : "volume_up"
                    title: qsTr("Volume")
                    displayText: Math.round(RaohaneAudio.volume * 100) + "%"
                    liveValue: RaohaneAudio.volume
                    onValueChangedByUser: value => RaohaneAudio.setVolume(value)
                    onIconTriggered: RaohaneAudio.toggleMute()
                }

                ControlSlider {
                    Layout.fillWidth: true
                    visible: Config.options.sidebar.quickSliders.showMic
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

    function setBrightnessComposite(value: real): void {
        const monitor = root.brightnessMonitor
        if (!monitor)
            return

        if (value >= 0.3) {
            monitor.setBrightness((value - 0.3) / 0.7)
            if (Hyprsunset.gamma !== 100)
                Hyprsunset.setGamma(100)
        } else {
            if (monitor.brightness !== 0)
                monitor.setBrightness(0)
            Hyprsunset.setGamma(value / 0.3 * (100 - Hyprsunset.gammaLowerLimit) + Hyprsunset.gammaLowerLimit)
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

                MaterialSymbol {
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

                MaterialSymbol {
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

                Slider {
                    id: slider
                    Layout.fillWidth: true
                    from: 0
                    to: 1
                    padding: 0
                    onMoved: control.valueChangedByUser(value)

                    Binding {
                        target: slider
                        property: "value"
                        value: Math.max(0, Math.min(1, control.liveValue))
                        when: !slider.pressed
                    }

                    background: Rectangle {
                        x: slider.leftPadding
                        y: slider.topPadding + slider.availableHeight / 2 - height / 2
                        width: slider.availableWidth
                        height: 5
                        radius: 3
                        color: "#2bffffff"

                        Rectangle {
                            width: slider.visualPosition * parent.width
                            height: parent.height
                            radius: parent.radius
                            color: RaohaneTheme.accent
                        }
                    }

                    handle: Rectangle {
                        x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                        y: slider.topPadding + slider.availableHeight / 2 - height / 2
                        width: slider.pressed ? 14 : 12
                        height: width
                        radius: width / 2
                        color: RaohaneTheme.text
                        border.width: 2
                        border.color: RaohaneTheme.accent

                        Behavior on width { NumberAnimation { duration: 90 } }
                    }
                }
            }
        }
    }
}
