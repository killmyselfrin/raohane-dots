pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.config
import qs.modules.raohane.services

Item {
    id: root

    property var screen
    property string pickerMode: ""
    property int tileColumns: 2
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
        spacing: RaohaneTheme.spacing

        RaohaneSceneSwitcher {
            visible: !root.pickerOpen
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? implicitHeight : 0
        }

        GridLayout {
            id: toggleGrid
            visible: !root.pickerOpen
            Layout.fillWidth: true
            columns: Math.max(1, root.tileColumns)
            columnSpacing: RaohaneTheme.spacingSmall + 2
            rowSpacing: RaohaneTheme.spacingSmall + 2

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

        RaohaneSurface {
            visible: !root.pickerOpen
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? sliderStack.implicitHeight + 2 * RaohaneTheme.spacingSmall : 0
            surfaceRadius: RaohaneTheme.radiusLarge
            raised: false
            showSheen: false
            showInnerRim: false
            idleColor: RaohaneTheme.surfaceSubtle
            idleBorderColor: RaohaneTheme.borderFaint
            clip: true
            showStateRail: false

            ColumnLayout {
                id: sliderStack
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    leftMargin: RaohaneTheme.spacingSmall
                    rightMargin: RaohaneTheme.spacingSmall
                }
                spacing: RaohaneTheme.spacingTiny

                ControlSlider {
                    Layout.fillWidth: true
                    visible: RaohaneConfig.quickSliderBrightness
                    icon: RaohaneDisplay.gamma === 100 ? "brightness_medium" : "wb_twilight"
                    title: RaohaneDisplay.gamma === 100 ? qsTr("Brightness") : qsTr("Gamma")
                    displayText: RaohaneDisplay.gamma === 100
                        ? Math.round((root.brightnessMonitor?.brightness ?? 0.5) * 100) + "%"
                        : Math.round(RaohaneDisplay.gamma) + "%"
                    contextText: root.brightnessMonitor?.name ?? ""
                    liveValue: root.brightnessValue
                    onValueChangedByUser: value => RaohaneDisplay.setComposite(root.screen, value)
                }

                ControlSlider {
                    Layout.fillWidth: true
                    visible: RaohaneConfig.quickSliderVolume
                    icon: RaohaneAudio.muted ? "volume_off" : "volume_up"
                    iconEnabled: true
                    title: qsTr("Volume")
                    displayText: Math.round(RaohaneAudio.volume * 100) + "%"
                    contextText: RaohaneAudio.sinkName
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
                    iconEnabled: true
                    title: qsTr("Microphone")
                    displayText: Math.round(RaohaneAudio.microphoneVolume * 100) + "%"
                    contextText: RaohaneAudio.sourceName
                    liveValue: RaohaneAudio.microphoneVolume
                    pickerEnabled: true
                    pickerActive: root.pickerMode === "input"
                    onValueChangedByUser: value => RaohaneAudio.setMicrophoneVolume(value)
                    onIconTriggered: RaohaneAudio.toggleMicrophoneMute()
                    onPickerTriggered: root.togglePicker("input")
                }
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
        property string contextText: ""
        property real liveValue: 0
        property bool iconEnabled: false
        property bool pickerEnabled: false
        property bool pickerActive: false
        signal valueChangedByUser(real value)
        signal iconTriggered()
        signal pickerTriggered()

        readonly property real clampedLiveValue: Math.max(0, Math.min(1, Number(liveValue) || 0))
        readonly property bool rowHovered: valueSlider.hovered
            || (control.iconEnabled && (iconButton.hovered || iconButton.activeFocus))
            || (control.pickerEnabled && pickerButton.hovered)

        implicitHeight: 46
        surfaceRadius: RaohaneTheme.radiusSmall
        transparentIdle: true
        showSheen: false
        showInnerRim: false
        hovered: control.rowHovered && !control.pickerActive
        active: control.pickerActive
        hoverColor: RaohaneTheme.surfaceHover
        activeColor: RaohaneTheme.accentSoft
        hoverBorderColor: RaohaneTheme.borderStrong
        activeBorderColor: RaohaneTheme.accentBorder
        showStateRail: control.pickerActive
        stateRailWidth: 2
        stateRailLength: 22
        stateRailOpacity: 0.82

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: RaohaneTheme.spacingSmall
            anchors.rightMargin: RaohaneTheme.spacingSmall
            spacing: RaohaneTheme.spacingSmall + 1

            Item {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                Layout.alignment: Qt.AlignVCenter

                RaohaneIcon {
                    visible: !control.iconEnabled
                    anchors.centerIn: parent
                    text: control.icon
                    iconSize: 16
                    color: RaohaneTheme.textMuted
                }

                RaohaneIconButton {
                    id: iconButton
                    visible: control.iconEnabled
                    anchors.centerIn: parent
                    buttonSize: 32
                    iconSize: 16
                    icon: control.icon
                    emphasized: control.rowHovered && !control.pickerActive
                    transparentIdle: true
                    showSheen: false
                    hoverScale: 1
                    pressedScale: 1
                    onClicked: control.iconTriggered()
                }
            }

            ColumnLayout {
                Layout.preferredWidth: 142
                Layout.alignment: Qt.AlignVCenter
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    spacing: RaohaneTheme.spacingSmall

                    Text {
                        Layout.fillWidth: true
                        text: control.title
                        color: control.pickerActive ? RaohaneTheme.accent : RaohaneTheme.textMuted
                        font.pixelSize: 9
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                    }

                    Text {
                        text: control.displayText
                        color: control.rowHovered || control.pickerActive ? RaohaneTheme.text : RaohaneTheme.textFaint
                        font.pixelSize: 8
                        font.weight: Font.DemiBold
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: control.contextText.length > 0
                    text: control.contextText
                    color: RaohaneTheme.textFaint
                    font.pixelSize: 7
                    elide: Text.ElideRight
                }
            }

            RaohaneSlider {
                id: valueSlider
                Layout.fillWidth: true
                Layout.minimumWidth: 118
                Layout.preferredHeight: 24
                from: 0
                to: 1
                stepSize: 0.01
                trackHeight: 5
                value: control.clampedLiveValue
                showHandle: control.rowHovered || activeFocus || control.pickerActive
                onMoved: value => control.valueChangedByUser(value)
            }

            RaohaneIconButton {
                id: pickerButton
                visible: control.pickerEnabled
                Layout.preferredWidth: control.pickerEnabled ? 28 : 0
                Layout.preferredHeight: 28
                buttonSize: 28
                iconSize: 12
                icon: "expand_more"
                emphasized: control.pickerActive
                transparentIdle: true
                showSheen: false
                rotation: pickerButton.transformMotionAllowed && control.pickerActive ? 180 : 0
                onClicked: control.pickerTriggered()

                Behavior on rotation {
                    enabled: pickerButton.transformMotionAllowed
                    NumberAnimation { duration: RaohaneMotion.micro; easing.type: RaohaneMotion.easeStandard }
                }
            }
        }
    }
}
