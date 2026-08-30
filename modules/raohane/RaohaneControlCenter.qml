import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.modules.raohane.config
import qs.modules.raohane.services

Scope {
    id: root

    readonly property var focusedScreen: Quickshell.screens.find(screen => screen.name === Hyprland.focusedMonitor?.name)
        ?? Quickshell.screens[0]
    property int panelWidth: 440
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
            if (RaohaneState.controlCenterOpen) {
                root.now = new Date()
                RaohaneEasyEffects.refresh()
                quickControls.refreshGameMode()
            }
        }
    }

    PanelWindow {
        id: panelWindow

        visible: RaohaneState.controlCenterOpen
        screen: root.focusedScreen
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
            top: 14
            right: 14
            bottom: 14
        }

        function hide(): void { RaohaneState.setPrimaryOpen("controlCenter", false) }

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

        RaohaneSurface {
            id: panelSurface
            width: root.panelWidth
            anchors {
                top: parent.top
                right: parent.right
                bottom: parent.bottom
            }
            surfaceRadius: RaohaneTheme.radiusHero
            raised: true
            showSheen: false
            border.color: RaohaneTheme.borderStrong
            clip: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 56

                    RowLayout {
                        anchors.fill: parent
                        spacing: 10

                        Rectangle {
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 36
                            radius: 12
                            color: RaohaneTheme.surfaceSubtle
                            border.width: 1
                            border.color: RaohaneTheme.border

                            Text {
                                anchors.centerIn: parent
                                text: "ラ"
                                color: RaohaneTheme.accent
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                Layout.fillWidth: true
                                text: qsTr("Control Center")
                                color: RaohaneTheme.text
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: (RaohaneConfig.profileDisplayName !== ""
                                    ? RaohaneConfig.profileDisplayName
                                    : RaohaneSystemInfo.username)
                                    + " · " + RaohaneSystemInfo.hostname
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 8
                                elide: Text.ElideRight
                            }
                        }

                        ColumnLayout {
                            spacing: -1

                            Text {
                                Layout.alignment: Qt.AlignRight
                                text: Qt.formatTime(root.now, "HH:mm")
                                color: RaohaneTheme.text
                                font.pixelSize: 13
                                font.weight: Font.Medium
                            }

                            Text {
                                Layout.alignment: Qt.AlignRight
                                text: Qt.formatDate(root.now, "ddd, d MMM")
                                color: RaohaneTheme.textFaint
                                font.pixelSize: 7
                            }
                        }

                        ActionButton {
                            icon: "settings"
                            onClicked: RaohaneState.setPrimaryOpen("settings", true)
                        }
                        ActionButton {
                            icon: "power_settings_new"
                            emphasized: true
                            onClicked: RaohaneState.setPrimaryOpen("session", true)
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: RaohaneTheme.borderFaint
                }

                RaohaneSurface {
                    Layout.fillWidth: true
                    Layout.preferredHeight: quickControls.implicitHeight + 18
                    surfaceRadius: 17
                    raised: false
                    showSheen: false

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

                RaohaneSurface {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 180
                    surfaceRadius: 17
                    raised: false
                    showSheen: false

                    RaohaneNotificationCenter {
                        anchors.fill: parent
                        anchors.margins: 10
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: RaohaneTheme.borderFaint
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    Layout.leftMargin: 4
                    spacing: 8

                    Rectangle {
                        width: 7
                        height: 7
                        radius: 4
                        color: RaohanePrivacy.recordingActive || RaohanePrivacy.cameraActive || RaohanePrivacy.microphoneActive
                            ? RaohaneTheme.critical
                            : RaohaneTheme.success
                    }

                    Text {
                        text: RaohanePrivacy.recordingActive || RaohanePrivacy.cameraActive || RaohanePrivacy.microphoneActive
                            ? qsTr("Privacy activity")
                            : qsTr("System ready")
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 8
                        font.weight: Font.Medium
                    }

                    Text {
                        text: "·"
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 8
                    }

                    Text {
                        text: RaohaneSystemInfo.distroName
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 8
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    ActionButton {
                        icon: "restart_alt"
                        onClicked: {
                            Quickshell.execDetached(["hyprctl", "reload"])
                            Quickshell.reload(true)
                        }
                    }
                    ActionButton {
                        icon: "close"
                        onClicked: panelWindow.hide()
                    }
                }
            }
        }

        IpcHandler {
            target: "sidebarRight"
            function toggle(): void { RaohaneState.togglePrimary("controlCenter") }
            function open(): void { RaohaneState.setPrimaryOpen("controlCenter", true) }
            function close(): void { RaohaneState.setPrimaryOpen("controlCenter", false) }
        }

        CompositorGlobalShortcut {
            name: "sidebarRightToggle"
            description: "Toggles Raohane control center"
            onPressed: RaohaneState.togglePrimary("controlCenter")
        }
    }

    component ActionButton: Rectangle {
        id: action

        required property string icon
        property bool emphasized: false
        signal clicked()

        Layout.preferredWidth: 31
        Layout.preferredHeight: 31
        radius: 10
        color: pointer.containsMouse || emphasized ? RaohaneTheme.surfaceHover : "transparent"
        border.width: emphasized || pointer.containsMouse ? 1 : 0
        border.color: emphasized ? RaohaneTheme.accentBorder : RaohaneTheme.borderStrong

        RaohaneIcon {
            anchors.centerIn: parent
            text: action.icon
            iconSize: 16
            fill: action.emphasized ? 1 : 0
            color: action.emphasized ? RaohaneTheme.accent : pointer.containsMouse ? RaohaneTheme.text : RaohaneTheme.textMuted
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
