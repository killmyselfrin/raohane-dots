import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import qs
import qs.modules.common
import qs.modules.common.widgets

Scope {
    id: root

    Component.onCompleted: GlobalStates.settingsOpen = false

    PanelWindow {
        id: panelWindow
        visible: GlobalStates.settingsOpen
        exclusiveZone: 0
        color: "transparent"
        WlrLayershell.namespace: "quickshell:raohane-settings"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: GlobalStates.settingsOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        function hide(): void { GlobalStates.settingsOpen = false }

        onVisibleChanged: {
            if (visible)
                GlobalFocusGrab.addDismissable(panelWindow)
            else
                GlobalFocusGrab.removeDismissable(panelWindow)
        }

        Connections {
            target: GlobalFocusGrab
            function onDismissed() { panelWindow.hide() }
        }

        Rectangle {
            anchors.fill: parent
            color: "#6608070d"
            opacity: GlobalStates.settingsOpen ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 180 } }

            MouseArea {
                anchors.fill: parent
                onClicked: panelWindow.hide()
            }
        }

        Rectangle {
            id: window
            width: Math.min(parent.width - 70, 1120)
            height: Math.min(parent.height - 70, 760)
            anchors.centerIn: parent
            radius: 28
            color: RaohaneTheme.glassStrong
            border.width: 1
            border.color: RaohaneTheme.border
            clip: true
            opacity: GlobalStates.settingsOpen ? 1 : 0
            scale: GlobalStates.settingsOpen ? 1 : 0.965

            Behavior on opacity { NumberAnimation { duration: 190; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }

            Rectangle {
                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: parent.bottom
                }
                width: 4
                color: RaohaneTheme.accent
                opacity: 0.82
            }

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                }
                height: 54
                color: "#d216141f"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 14
                    spacing: 12

                    Rectangle {
                        width: 30
                        height: 30
                        radius: 10
                        color: RaohaneTheme.accentSoft
                        border.width: 1
                        border.color: RaohaneTheme.border

                        Text {
                            anchors.centerIn: parent
                            text: "ラ"
                            color: RaohaneTheme.accent
                            font.pixelSize: 15
                            font.weight: Font.Bold
                        }
                    }

                    Column {
                        Layout.alignment: Qt.AlignVCenter
                        spacing: -1

                        Text {
                            text: "RAOHANE SETTINGS"
                            color: RaohaneTheme.text
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.2
                        }

                        Text {
                            text: "設定  /  Hyprland shell control"
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 9
                            font.letterSpacing: 0.6
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: stateText.implicitWidth + 20
                        height: 28
                        radius: 14
                        color: "#8f201b2b"
                        border.width: 1
                        border.color: RaohaneTheme.border

                        Row {
                            anchors.centerIn: parent
                            spacing: 7

                            Rectangle {
                                width: 6
                                height: 6
                                radius: 3
                                anchors.verticalCenter: parent.verticalCenter
                                color: RaohaneTheme.accent
                            }

                            Text {
                                id: stateText
                                text: "LIVE CONFIG"
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 9
                                font.letterSpacing: 0.8
                            }
                        }
                    }

                    Rectangle {
                        width: 32
                        height: 32
                        radius: 11
                        color: closeMouse.containsMouse ? RaohaneTheme.accentSoft : "#6f201d29"
                        border.width: 1
                        border.color: closeMouse.containsMouse ? RaohaneTheme.accent : RaohaneTheme.border

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "close"
                            iconSize: 18
                            color: RaohaneTheme.text
                        }

                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: panelWindow.hide()
                        }
                    }
                }
            }

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    bottom: parent.bottom
                    leftMargin: 10
                    rightMargin: 10
                    topMargin: 64
                    bottomMargin: 10
                }
                radius: 22
                color: "#b3121019"
                border.width: 1
                border.color: "#25ffffff"
                clip: true

                RaohaneSettingsContent {
                    anchors.fill: parent
                    anchors.margins: 8
                }
            }

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    panelWindow.hide()
                    event.accepted = true
                }
            }
        }

        IpcHandler {
            target: "settings"
            function toggle(): void { GlobalStates.settingsOpen = !GlobalStates.settingsOpen }
            function open(): void { GlobalStates.settingsOpen = true }
            function close(): void { GlobalStates.settingsOpen = false }
        }

        CompositorGlobalShortcut {
            name: "settingsToggle"
            description: "Toggles Raohane settings"
            onPressed: GlobalStates.settingsOpen = !GlobalStates.settingsOpen
        }
    }
}
