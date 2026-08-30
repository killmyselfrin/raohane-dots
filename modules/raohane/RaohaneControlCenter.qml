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
    property int panelWidth: 470
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
        implicitWidth: root.panelWidth + 34
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
            top: 16
            right: 16
            bottom: 16
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

        Rectangle {
            anchors.centerIn: panelSurface
            width: panelSurface.width + 12
            height: panelSurface.height + 12
            radius: RaohaneTheme.radiusHero + 6
            color: "transparent"
            border.width: 4
            border.color: "#1fc56cff"
            opacity: RaohaneState.controlCenterOpen ? 1 : 0
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
            border.color: RaohaneTheme.accentBorder
            clip: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: RaohaneTheme.panelPadding
                spacing: 12

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 72

                    RowLayout {
                        anchors.fill: parent
                        spacing: 11

                        Rectangle {
                            Layout.preferredWidth: 42
                            Layout.preferredHeight: 42
                            radius: 15
                            color: RaohaneTheme.accentSoft
                            border.width: 1
                            border.color: RaohaneTheme.accentGlow

                            Text {
                                anchors.centerIn: parent
                                text: "ラ"
                                color: RaohaneTheme.text
                                font.pixelSize: 16
                                font.weight: Font.Bold
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                Layout.fillWidth: true
                                text: qsTr("Control Center")
                                color: RaohaneTheme.text
                                font.pixelSize: 17
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: (RaohaneConfig.profileDisplayName !== ""
                                    ? RaohaneConfig.profileDisplayName
                                    : RaohaneSystemInfo.username)
                                    + "  ·  " + RaohaneSystemInfo.hostname
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 9
                                elide: Text.ElideRight
                            }
                        }

                        ColumnLayout {
                            spacing: -1

                            Text {
                                Layout.alignment: Qt.AlignRight
                                text: Qt.formatTime(root.now, "HH:mm")
                                color: RaohaneTheme.text
                                font.pixelSize: 15
                                font.weight: Font.DemiBold
                            }

                            Text {
                                Layout.alignment: Qt.AlignRight
                                text: Qt.formatDate(root.now, "ddd, d MMM")
                                color: RaohaneTheme.textFaint
                                font.pixelSize: 8
                            }
                        }

                        ActionButton {
                            icon: "settings"
                            emphasized: false
                            onClicked: RaohaneState.setPrimaryOpen("settings", true)
                        }
                        ActionButton {
                            icon: "power_settings_new"
                            emphasized: true
                            onClicked: RaohaneState.setPrimaryOpen("session", true)
                        }
                    }
                }

                RaohaneSurface {
                    Layout.fillWidth: true
                    Layout.preferredHeight: quickControls.implicitHeight + 22
                    surfaceRadius: 19
                    raised: false

                    RaohaneQuickControls {
                        id: quickControls
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 11
                        }
                        screen: panelWindow.screen
                    }
                }

                RaohaneSurface {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 180
                    surfaceRadius: 19
                    raised: false

                    RaohaneNotificationCenter {
                        anchors.fill: parent
                        anchors.margins: 11
                    }
                }

                RaohaneSurface {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    surfaceRadius: 16
                    raised: false

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 8
                        spacing: 9

                        Rectangle {
                            width: 8
                            height: 8
                            radius: 4
                            color: RaohanePrivacy.recordingActive || RaohanePrivacy.cameraActive || RaohanePrivacy.microphoneActive
                                ? RaohaneTheme.critical
                                : RaohaneTheme.success
                        }

                        Text {
                            text: RaohanePrivacy.recordingActive || RaohanePrivacy.cameraActive || RaohanePrivacy.microphoneActive
                                ? qsTr("Privacy activity")
                                : qsTr("All systems calm")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 9
                            font.weight: Font.Medium
                        }

                        Text {
                            text: "·"
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 9
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

        Layout.preferredWidth: 32
        Layout.preferredHeight: 32
        radius: 11
        color: emphasized
            ? RaohaneTheme.accentSoft
            : pointer.containsMouse ? RaohaneTheme.surfaceHover : "transparent"
        border.width: emphasized || pointer.containsMouse ? 1 : 0
        border.color: emphasized ? RaohaneTheme.accentBorder : RaohaneTheme.borderStrong

        RaohaneIcon {
            anchors.centerIn: parent
            text: action.icon
            iconSize: 16
            color: action.emphasized || pointer.containsMouse
                ? RaohaneTheme.accent
                : RaohaneTheme.textMuted
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
