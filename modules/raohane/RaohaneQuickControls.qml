pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.config
import qs.modules.raohane.services

Item {
    id: root

    property var screen
    property string pickerMode: ""
    readonly property bool pickerOpen: root.pickerMode.length > 0
    readonly property var brightnessMonitor: RaohaneDisplay.getMonitorForScreen(screen)
    readonly property real brightnessValue: RaohaneDisplay.compositeValue(screen)
    readonly property var tileLayout: RaohaneQuickControlRegistry.sanitizeLayout(
        RaohaneConfig.quickControlTiles
    )

    implicitHeight: content.implicitHeight

    function togglePicker(mode: string): void {
        root.pickerMode = root.pickerMode === mode ? "" : mode
    }

    Component.onCompleted: RaohanePerformance.refreshGameMode()

    ColumnLayout {
        id: content
        anchors {
            left: parent.left
            right: parent.right
        }
        spacing: 10

        GridLayout {
            id: toggleGrid
            visible: !root.pickerOpen
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 7
            rowSpacing: 7

            Repeater {
                model: root.tileLayout

                delegate: RaohaneQuickControlTile {
                    required property var modelData

                    Layout.fillWidth: true
                    tileId: String(modelData)
                    pickerMode: root.pickerMode
                    onPickerRequested: mode => root.togglePicker(mode)
                }
            }
        }

        ColumnLayout {
            visible: !root.pickerOpen
            Layout.fillWidth: true
            Layout.topMargin: 1
            spacing: 5

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
                pickerEnabled: true
                pickerActive: root.pickerMode === "output"
                onValueChangedByUser: value => RaohaneAudio.setVolume(value)
                onIconTriggered: RaohaneAudio.toggleMute()
                onPickerTriggered: root.togglePicker("output")
            }

            ControlSlider {
                Layout.fillWidth: true
                visible: RaohaneConfig.quickSliderMic
                icon: RaohaneAudio.microphoneMuted ? "mic_off" : "mic"
                title: qsTr("Microphone")
                displayText: Math.round(RaohaneAudio.microphoneVolume * 100) + "%"
                liveValue: RaohaneAudio.microphoneVolume
                pickerEnabled: true
                pickerActive: root.pickerMode === "input"
                onValueChangedByUser: value => RaohaneAudio.setMicrophoneVolume(value)
                onIconTriggered: RaohaneAudio.toggleMicrophoneMute()
                onPickerTriggered: root.togglePicker("input")
            }
        }

        RaohaneDevicePicker {
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            mode: root.pickerMode
            onCloseRequested: root.pickerMode = ""
        }
    }

    component ControlSlider: RaohaneSurface {
        id: control

        required property string icon
        required property string title
        property string displayText: ""
        property real liveValue: 0
        property bool pickerEnabled: false
        property bool pickerActive: false
        signal valueChangedByUser(real value)
        signal iconTriggered()
        signal pickerTriggered()

        readonly property real clampedLiveValue: Math.max(0, Math.min(1, Number(liveValue) || 0))
        readonly property bool rowHovered: valueSlider.hovered || iconButton.hovered || iconButton.activeFocus
            || (control.pickerEnabled && pickerButton.hovered)

        implicitHeight: 44
        surfaceRadius: 13
        transparentIdle: true
        showSheen: false
        hovered: control.rowHovered
        interactive: false
        border.color: control.pickerActive ? RaohaneTheme.accentBorder
            : control.rowHovered ? RaohaneTheme.borderStrong
            : RaohaneTheme.borderFaint

        Behavior on border.color { ColorAnimation { duration: RaohaneMotion.micro } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 5
            anchors.rightMargin: 5
            spacing: 7

            RaohaneIconButton {
                id: iconButton
                Layout.alignment: Qt.AlignVCenter
                buttonSize: 30
                iconSize: 15
                icon: control.icon
                emphasized: control.rowHovered && !control.pickerActive
                transparentIdle: !control.rowHovered || control.pickerActive
                showSheen: false
                onClicked: control.iconTriggered()
            }

            ColumnLayout {
                Layout.preferredWidth: 66
                Layout.alignment: Qt.AlignVCenter
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: control.title
                    color: control.pickerActive ? RaohaneTheme.accent : RaohaneTheme.textMuted
                    font.pixelSize: 8
                    font.weight: Font.Medium
                    elide: Text.ElideRight

                    Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
                }

                Text {
                    Layout.fillWidth: true
                    text: control.displayText
                    color: control.rowHovered ? RaohaneTheme.text : RaohaneTheme.textFaint
                    font.pixelSize: 7
                    font.weight: Font.DemiBold

                    Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
                }
            }

            RaohaneSlider {
                id: valueSlider
                Layout.fillWidth: true
                Layout.preferredHeight: 22
                from: 0
                to: 1
                stepSize: 0.01
                value: control.clampedLiveValue
                showHandle: control.rowHovered || activeFocus
                onMoved: value => control.valueChangedByUser(value)
            }

            RaohaneIconButton {
                id: pickerButton
                visible: control.pickerEnabled
                Layout.preferredWidth: control.pickerEnabled ? 24 : 0
                Layout.preferredHeight: 24
                buttonSize: 24
                iconSize: 12
                icon: "expand_more"
                emphasized: control.pickerActive
                transparentIdle: !control.pickerActive
                showSheen: false
                rotation: control.pickerActive ? 180 : 0
                onClicked: control.pickerTriggered()

                Behavior on rotation {
                    NumberAnimation { duration: RaohaneMotion.micro; easing.type: RaohaneMotion.easeStandard }
                }
            }
        }
    }
}
