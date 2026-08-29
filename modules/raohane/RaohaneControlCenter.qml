import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import qs.modules.raohane.config
import qs.modules.raohane.services

Scope {
    id: root

    property int panelWidth: 390
    property date now: new Date()

    Timer {
        interval: 1000
        repeat: true
        running: RaohaneState.controlCenterOpen
        onTriggered: root.now = new Date()
    }

    Connections {
        target: RaohaneState
        function onControlCenterOpenChanged(): void {
            if (RaohaneState.controlCenterOpen)
                root.now = new Date()
        }
    }

    PanelWindow {
        id: panelWindow

        visible: RaohaneState.controlCenterOpen
        exclusiveZone: 0
        implicitWidth: root.panelWidth + 24
        color: "transparent"
        WlrLayershell.namespace: "quickshell:raohane-control-center"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: RaohaneState.controlCenterOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        anchors {
            top: true
            right: true
            bottom: true
        }
        margins {
            top: 12
            right: 12
            bottom: 12
        }

        function hide(): void { RaohaneState.controlCenterOpen = false }

        onVisibleChanged: {
            if (visible) {
                RaohaneNotifications.markAllRead()
                RaohaneFocusGrab.addDismissable(panelWindow)
            } else {
                RaohaneFocusGrab.removeDismissable(panelWindow)
            }
        }

        Connections {
            target: RaohaneFocusGrab
            function onDismissed() { panelWindow.hide() }
        }

        Rectangle {
            width: root.panelWidth
            anchors {
                top: parent.top
                right: parent.right
                bottom: parent.bottom
            }
            radius: RaohaneTheme.radiusLarge
            color: RaohaneTheme.surfaceRaised
            border.width: 1
            border.color: RaohaneTheme.border
            clip: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 11
                spacing: 9

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 68

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 5
                        anchors.rightMargin: 3
                        spacing: 10

                        Rectangle {
                            Layout.preferredWidth: 34
                            Layout.preferredHeight: 34
                            radius: 11
                            color: RaohaneTheme.accentSoft

                            Text {
                                anchors.centerIn: parent
                                text: "ラ"
                                color: RaohaneTheme.accent
                                font.pixelSize: 14
                                font.weight: Font.Bold
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: -1

                            Text {
                                Layout.fillWidth: true
                                text: RaohaneConfig.profileDisplayName !== ""
                                    ? RaohaneConfig.profileDisplayName
                                    : RaohaneSystemInfo.username
                                color: RaohaneTheme.text
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: RaohaneSystemInfo.hostname + " · " + RaohaneSystemInfo.distroName
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 8
                                elide: Text.ElideRight
                            }
                        }

                        ActionButton {
                            icon: "settings"
                            onClicked: {
                                panelWindow.hide()
                                RaohaneState.settingsOpen = true
                            }
                        }
                        ActionButton {
                            icon: "restart_alt"
                            onClicked: {
                                Quickshell.execDetached(["hyprctl", "reload"])
                                Quickshell.reload(true)
                            }
                        }
                        ActionButton {
                            icon: "power_settings_new"
                            onClicked: {
                                panelWindow.hide()
                                RaohaneState.sessionOpen = true
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: quickControls.implicitHeight + 18
                    radius: 16
                    color: "#10ffffff"
                    border.width: 1
                    border.color: "#14ffffff"

                    RaohaneQuickControls {
                        id: quickControls
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 9
                        }
                        screen: panelWindow.screen
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 160
                    radius: 16
                    color: "#0cffffff"
                    border.width: 1
                    border.color: "#14ffffff"

                    RaohaneNotificationCenter {
                        anchors.fill: parent
                        anchors.margins: 9
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 5
                        anchors.rightMargin: 2
                        spacing: 8

                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            color: RaohanePrivacy.recordingActive || RaohanePrivacy.cameraActive || RaohanePrivacy.microphoneActive
                                ? RaohaneTheme.critical
                                : RaohaneTheme.accent
                        }

                        Text {
                            text: Qt.formatTime(root.now, "HH:mm")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 9
                            font.weight: Font.Medium
                        }

                        Text {
                            text: "RAOHANE"
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 8
                            font.letterSpacing: 1.0
                        }

                        Item { Layout.fillWidth: true }

                        ActionButton {
                            icon: "close"
                            onClicked: panelWindow.hide()
                        }
                    }
                }
            }
        }

        IpcHandler {
            target: "sidebarRight"
            function toggle(): void { RaohaneState.controlCenterOpen = !RaohaneState.controlCenterOpen }
            function open(): void { RaohaneState.controlCenterOpen = true }
            function close(): void { RaohaneState.controlCenterOpen = false }
        }

        CompositorGlobalShortcut {
            name: "sidebarRightToggle"
            description: "Toggles Raohane control center"
            onPressed: RaohaneState.controlCenterOpen = !RaohaneState.controlCenterOpen
        }
    }

    component ActionButton: Rectangle {
        id: action

        required property string icon
        signal clicked()

        Layout.preferredWidth: 30
        Layout.preferredHeight: 30
        radius: 10
        color: pointer.containsMouse ? RaohaneTheme.surfaceHover : "transparent"

        RaohaneIcon {
            anchors.centerIn: parent
            text: action.icon
            iconSize: 16
            color: pointer.containsMouse ? RaohaneTheme.text : RaohaneTheme.textMuted
        }

        MouseArea {
            id: pointer
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: action.clicked()
        }
    }
}
