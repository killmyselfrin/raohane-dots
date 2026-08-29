import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root

    PanelWindow {
        id: panelWindow

        visible: RaohaneState.settingsOpen
        exclusiveZone: 0
        color: "transparent"
        WlrLayershell.namespace: "quickshell:raohane-settings"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: RaohaneState.settingsOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        function hide(): void { RaohaneState.settingsOpen = false }

        onVisibleChanged: {
            if (visible)
                RaohaneFocusGrab.addDismissable(panelWindow)
            else
                RaohaneFocusGrab.removeDismissable(panelWindow)
        }

        Connections {
            target: RaohaneFocusGrab
            function onDismissed() { panelWindow.hide() }
        }

        Rectangle {
            anchors.fill: parent
            color: "#72000000"
            opacity: RaohaneState.settingsOpen ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: RaohaneTheme.animationDuration } }

            MouseArea {
                anchors.fill: parent
                onClicked: panelWindow.hide()
            }
        }

        Rectangle {
            id: window

            width: Math.min(parent.width - 72, 1080)
            height: Math.min(parent.height - 72, 720)
            anchors.centerIn: parent
            radius: RaohaneTheme.radiusLarge
            color: RaohaneTheme.surfaceRaised
            border.width: 1
            border.color: RaohaneTheme.border
            clip: true
            opacity: RaohaneState.settingsOpen ? 1 : 0
            scale: RaohaneState.settingsOpen ? 1 : 0.98

            Behavior on opacity { NumberAnimation { duration: RaohaneTheme.animationDuration } }
            Behavior on scale { NumberAnimation { duration: RaohaneTheme.animationDuration; easing.type: Easing.OutCubic } }

            Item {
                id: titleBar

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                }
                height: 50

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 12
                    spacing: 10

                    Text {
                        text: "ラ"
                        color: RaohaneTheme.accent
                        font.pixelSize: 14
                        font.weight: Font.Bold
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: -2

                        Text {
                            text: qsTr("Settings")
                            color: RaohaneTheme.text
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: "設定 · native.json"
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 8
                        }
                    }

                    Rectangle {
                        width: 30
                        height: 30
                        radius: 10
                        color: closeMouse.containsMouse ? RaohaneTheme.surfaceHover : "transparent"

                        RaohaneIcon {
                            anchors.centerIn: parent
                            text: "close"
                            iconSize: 16
                            color: closeMouse.containsMouse ? RaohaneTheme.text : RaohaneTheme.textMuted
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

                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                    }
                    height: 1
                    color: "#14ffffff"
                }
            }

            RaohaneSettingsContent {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: titleBar.bottom
                    bottom: parent.bottom
                    margins: 8
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
            function toggle(): void { RaohaneState.settingsOpen = !RaohaneState.settingsOpen }
            function open(): void { RaohaneState.settingsOpen = true }
            function close(): void { RaohaneState.settingsOpen = false }
        }

        CompositorGlobalShortcut {
            name: "settingsToggle"
            description: "Toggles Raohane settings"
            onPressed: RaohaneState.settingsOpen = !RaohaneState.settingsOpen
        }
    }
}
