import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import qs.modules.raohane.config
import qs.modules.raohane.services

Scope {
    id: root

    property int panelWidth: 420

    PanelWindow {
        id: panelWindow
        visible: RaohaneState.controlCenterOpen
        exclusiveZone: 0
        implicitWidth: root.panelWidth + 28
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
            top: 10
            right: 10
            bottom: 10
        }

        function hide(): void {
            RaohaneState.controlCenterOpen = false
        }

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
            id: shell
            width: root.panelWidth
            anchors {
                top: parent.top
                right: parent.right
                bottom: parent.bottom
            }
            radius: 26
            color: RaohaneTheme.glassStrong
            border.width: 1
            border.color: RaohaneTheme.border
            clip: true

            Rectangle {
                width: 3
                height: parent.height * 0.42
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                radius: 2
                color: RaohaneTheme.accent
                opacity: 0.9
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                Rectangle {
                    id: hero
                    Layout.fillWidth: true
                    Layout.preferredHeight: 150
                    radius: 20
                    color: "#241f31"
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: RaohaneConfig.wallpaperPath
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: false
                        opacity: status === Image.Ready ? 0.78 : 0
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: "#540a0910"
                    }

                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                        }
                        height: 72
                        color: "#bb15131d"
                    }

                    Column {
                        anchors {
                            left: parent.left
                            leftMargin: 16
                            bottom: parent.bottom
                            bottomMargin: 13
                        }
                        spacing: 2

                        Text {
                            text: RaohaneSystemInfo.username
                            color: RaohaneTheme.text
                            font.pixelSize: 17
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: RaohaneSystemInfo.hostname + "  ·  " + RaohaneSystemInfo.distroName
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 11
                        }
                    }

                    Row {
                        anchors {
                            right: parent.right
                            rightMargin: 12
                            bottom: parent.bottom
                            bottomMargin: 12
                        }
                        spacing: 7

                        ActionPill {
                            icon: "settings"
                            onClicked: {
                                RaohaneState.controlCenterOpen = false
                                RaohaneState.settingsOpen = true
                            }
                        }
                        ActionPill {
                            icon: "restart_alt"
                            onClicked: {
                                Quickshell.execDetached(["hyprctl", "reload"])
                                Quickshell.reload(true)
                            }
                        }
                        ActionPill {
                            icon: "power_settings_new"
                            onClicked: {
                                RaohaneState.controlCenterOpen = false
                                Quickshell.execDetached(["raohane", "session"])
                            }
                        }
                    }

                    Rectangle {
                        anchors {
                            top: parent.top
                            left: parent.left
                            topMargin: 12
                            leftMargin: 12
                        }
                        width: titleRow.implicitWidth + 18
                        height: 28
                        radius: 14
                        color: "#c9161320"
                        border.width: 1
                        border.color: RaohaneTheme.border

                        Row {
                            id: titleRow
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
                                text: "RAOHANE / CONTROL"
                                color: RaohaneTheme.text
                                font.pixelSize: 10
                                font.letterSpacing: 1.2
                                font.weight: Font.DemiBold
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: quickControls.implicitHeight + 18
                    radius: 20
                    color: RaohaneTheme.glass
                    border.width: 1
                    border.color: RaohaneTheme.border

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
                    Layout.minimumHeight: 150
                    radius: 20
                    color: "#b915131d"
                    border.width: 1
                    border.color: RaohaneTheme.border

                    RaohaneNotificationCenter {
                        anchors.fill: parent
                        anchors.margins: 10
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 17
                        color: RaohaneTheme.glass
                        border.width: 1
                        border.color: RaohaneTheme.border

                        Row {
                            anchors.centerIn: parent
                            spacing: 7

                            Rectangle {
                                width: 5
                                height: 5
                                radius: 3
                                anchors.verticalCenter: parent.verticalCenter
                                color: RaohanePrivacy.recordingActive || RaohanePrivacy.cameraActive || RaohanePrivacy.microphoneActive
                                    ? RaohaneTheme.critical
                                    : RaohaneTheme.accent
                            }

                            Text {
                                text: "ラオハネ  ·  " + Qt.formatTime(new Date(), "hh:mm")
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 10
                            }
                        }
                    }

                    Rectangle {
                        width: 34
                        height: 34
                        radius: 17
                        color: RaohaneTheme.accentSoft
                        border.width: 1
                        border.color: RaohaneTheme.border

                        RaohaneIcon {
                            anchors.centerIn: parent
                            text: "close"
                            iconSize: 17
                            color: RaohaneTheme.text
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
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

    component ActionPill: Rectangle {
        id: action
        required property string icon
        signal clicked()

        width: 34
        height: 34
        radius: 17
        color: mouse.containsMouse ? RaohaneTheme.accentSoft : "#c51c1925"
        border.width: 1
        border.color: mouse.containsMouse ? RaohaneTheme.accent : RaohaneTheme.border

        RaohaneIcon {
            anchors.centerIn: parent
            text: action.icon
            iconSize: 17
            color: RaohaneTheme.text
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: action.clicked()
        }
    }
}
