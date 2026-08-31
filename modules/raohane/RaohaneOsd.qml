import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

import qs.modules.raohane.config
import qs.modules.raohane.services

Scope {
    id: root

    property string currentIndicator: "volume"
    readonly property var focusedScreen: Quickshell.screens.find(screen => screen.name === Hyprland.focusedMonitor?.name)
        ?? Quickshell.screens[0]
    readonly property var brightnessMonitor: RaohaneDisplay.getMonitorForScreen(focusedScreen)

    readonly property real value: {
        if (currentIndicator === "brightness")
            return Math.max(0, Math.min(1, brightnessMonitor?.brightness ?? 0.5))
        if (currentIndicator === "gamma") {
            const lower = RaohaneDisplay.gammaLowerLimit / 100
            const current = RaohaneDisplay.gamma / 100
            if (lower >= 1)
                return current
            return Math.max(0, Math.min(1, (current - lower) / (1 - lower)))
        }
        return Math.max(0, Math.min(1, RaohaneAudio.volume))
    }

    readonly property string icon: currentIndicator === "brightness"
        ? (RaohaneDisplay.temperatureActive ? "routine" : "light_mode")
        : currentIndicator === "gamma"
            ? "wb_twilight"
            : (RaohaneAudio.muted ? "volume_off" : "volume_up")

    readonly property string label: currentIndicator === "brightness"
        ? qsTr("Brightness")
        : currentIndicator === "gamma"
            ? qsTr("Gamma")
            : qsTr("Volume")

    readonly property int percent: currentIndicator === "gamma"
        ? Math.round(RaohaneDisplay.gamma)
        : Math.round(value * 100)

    function trigger(indicator: string): void {
        currentIndicator = indicator
        RaohaneState.osdOpen = true
        hideTimer.restart()
    }

    Timer {
        id: hideTimer
        interval: RaohaneConfig.osdTimeout
        repeat: false
        onTriggered: RaohaneState.osdOpen = false
    }

    Connections {
        target: RaohaneDisplay

        function onBrightnessChanged(): void { root.trigger("brightness") }
        function onGammaChanged(): void { root.trigger("gamma") }
    }

    Connections {
        target: RaohaneAudio

        function onVolumeChanged(): void {
            if (RaohaneAudio.ready)
                root.trigger("volume")
        }

        function onMutedChanged(): void {
            if (RaohaneAudio.ready)
                root.trigger("volume")
        }
    }

    Loader {
        active: RaohaneState.osdOpen

        sourceComponent: PanelWindow {
            id: panelWindow

            screen: root.focusedScreen
            visible: true
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            implicitWidth: 356
            implicitHeight: 76

            WlrLayershell.namespace: "quickshell:raohane-osd"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors {
                top: !RaohaneConfig.barBottom
                bottom: RaohaneConfig.barBottom
            }

            margins {
                top: 70
                bottom: 70
            }

            mask: Region { item: card }

            RaohaneSurface {
                id: card

                width: 324
                height: 64
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: !RaohaneConfig.barBottom ? parent.top : undefined
                anchors.bottom: RaohaneConfig.barBottom ? parent.bottom : undefined
                surfaceRadius: 19
                raised: true
                showSheen: false
                border.color: RaohaneTheme.borderStrong

                opacity: 0
                scale: 0.965
                transform: Translate {
                    y: RaohaneConfig.barBottom ? 10 : -10
                }

                Component.onCompleted: enterAnimation.start()

                ParallelAnimation {
                    id: enterAnimation

                    NumberAnimation {
                        target: card
                        property: "opacity"
                        to: 1
                        duration: RaohaneMotion.standard
                        easing.type: RaohaneMotion.easeStandard
                    }
                    NumberAnimation {
                        target: card
                        property: "scale"
                        to: 1
                        duration: RaohaneMotion.enter
                        easing.type: RaohaneMotion.easeEnter
                    }
                    NumberAnimation {
                        target: card.transform
                        property: "y"
                        to: 0
                        duration: RaohaneMotion.enter
                        easing.type: RaohaneMotion.easeEmphasized
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                    onEntered: RaohaneState.osdOpen = false
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 11

                    RaohaneSurface {
                        Layout.preferredWidth: 38
                        Layout.preferredHeight: 38
                        surfaceRadius: 12
                        raised: false
                        active: root.currentIndicator === "volume" && RaohaneAudio.muted
                        showSheen: false

                        RaohaneIcon {
                            anchors.centerIn: parent
                            text: root.icon
                            iconSize: 20
                            fill: 1
                            color: RaohaneTheme.accent

                            Behavior on text {
                                SequentialAnimation {
                                    NumberAnimation { target: parent; property: "scale"; to: 0.88; duration: RaohaneMotion.micro }
                                    NumberAnimation { target: parent; property: "scale"; to: 1; duration: RaohaneMotion.micro; easing.type: RaohaneMotion.easeEmphasized }
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 5

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: root.label
                                color: RaohaneTheme.text
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: root.percent + "%"
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 9
                                font.weight: Font.DemiBold

                                Behavior on text {
                                    SequentialAnimation {
                                        NumberAnimation { target: parent; property: "opacity"; to: 0.62; duration: RaohaneMotion.micro }
                                        NumberAnimation { target: parent; property: "opacity"; to: 1; duration: RaohaneMotion.micro }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 5
                            radius: 3
                            color: RaohaneTheme.surfaceDeep
                            border.width: 1
                            border.color: RaohaneTheme.borderFaint

                            Rectangle {
                                width: parent.width * root.value
                                height: parent.height
                                radius: parent.radius
                                color: RaohaneTheme.accent
                                opacity: 0.9

                                Behavior on width {
                                    NumberAnimation {
                                        duration: RaohaneMotion.micro
                                        easing.type: RaohaneMotion.easeStandard
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "osdVolume"

        function trigger(): void { root.trigger("volume") }
        function hide(): void { RaohaneState.osdOpen = false }
        function toggle(): void { RaohaneState.osdOpen = !RaohaneState.osdOpen }
    }

    GlobalShortcut {
        name: "osdVolumeTrigger"
        description: "Triggers Raohane volume OSD"
        onPressed: root.trigger("volume")
    }

    GlobalShortcut {
        name: "osdVolumeHide"
        description: "Hides Raohane OSD"
        onPressed: RaohaneState.osdOpen = false
    }
}
