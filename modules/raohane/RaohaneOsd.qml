import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

import qs
import qs.modules.common
import qs.modules.common.widgets
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
            if (lower >= 1) return current
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
        GlobalStates.osdVolumeOpen = true
        hideTimer.restart()
    }

    Timer {
        id: hideTimer
        interval: Config.options.osd?.timeout ?? 1500
        repeat: false
        onTriggered: GlobalStates.osdVolumeOpen = false
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
        active: GlobalStates.osdVolumeOpen

        sourceComponent: PanelWindow {
            id: panelWindow
            screen: root.focusedScreen
            visible: true
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            implicitWidth: 390
            implicitHeight: 78

            WlrLayershell.namespace: "quickshell:raohane-osd"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors {
                top: !Config.options.bar.bottom
                bottom: Config.options.bar.bottom
            }

            margins {
                top: 72
                bottom: 72
            }

            mask: Region { item: card }

            Rectangle {
                id: card
                width: 350
                height: 72
                anchors.horizontalCenter: parent.horizontalCenter
                radius: 24
                color: RaohaneTheme.glassStrong
                border.width: 1
                border.color: RaohaneTheme.border

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                    onEntered: GlobalStates.osdVolumeOpen = false
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    Rectangle {
                        width: 42
                        height: 42
                        radius: 15
                        color: RaohaneTheme.accentSoft

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: root.icon
                            iconSize: 22
                            color: RaohaneTheme.accent
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: root.label
                                color: RaohaneTheme.text
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: root.percent + "%"
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 6
                            radius: 3
                            color: "#32ffffff"

                            Rectangle {
                                width: parent.width * root.value
                                height: parent.height
                                radius: parent.radius
                                color: RaohaneTheme.accent

                                Behavior on width {
                                    NumberAnimation {
                                        duration: 120
                                        easing.type: Easing.OutCubic
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
        function hide(): void { GlobalStates.osdVolumeOpen = false }
        function toggle(): void { GlobalStates.osdVolumeOpen = !GlobalStates.osdVolumeOpen }
    }

    CompositorGlobalShortcut {
        name: "osdVolumeTrigger"
        description: "Triggers Raohane volume OSD"
        onPressed: root.trigger("volume")
    }

    CompositorGlobalShortcut {
        name: "osdVolumeHide"
        description: "Hides Raohane OSD"
        onPressed: GlobalStates.osdVolumeOpen = false
    }
}
