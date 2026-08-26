pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import qs
import qs.modules.raohane.config

Variants {
    id: root
    model: Quickshell.screens

    property date now: new Date()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    PanelWindow {
        id: desktopWindow

        required property var modelData

        readonly property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)
        readonly property list<HyprlandWorkspace> monitorWorkspaces: Hyprland.workspaces.values.filter(workspace =>
            workspace.monitor && desktopWindow.monitor
            && workspace.monitor.name === desktopWindow.monitor.name
        )
        readonly property bool fullscreenActive: monitorWorkspaces.some(workspace =>
            workspace.active
            && workspace.toplevels.values.some(window => window.wayland?.fullscreen)
        )
        readonly property bool canvasVisible: !GlobalStates.screenLocked
            && !(RaohaneConfig.wallpaperHideWhenFullscreen && fullscreenActive)

        screen: modelData
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "quickshell:raohane-desktop-canvas"
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        Item {
            anchors.fill: parent
            opacity: desktopWindow.canvasVisible ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }

            ColumnLayout {
                anchors {
                    left: parent.left
                    top: parent.top
                    leftMargin: 54
                    topMargin: 92
                }
                width: Math.min(520, parent.width * 0.42)
                spacing: 3

                RowLayout {
                    spacing: 9

                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: RaohaneTheme.accent
                        opacity: 0.9
                    }

                    Text {
                        text: "ラオハネ  /  RAOHANE"
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.4
                    }
                }

                Text {
                    Layout.topMargin: 5
                    text: Qt.formatTime(root.now, "HH:mm")
                    color: RaohaneTheme.text
                    font.pixelSize: 70
                    font.weight: Font.Light
                    font.letterSpacing: -2.8
                }

                Text {
                    text: Qt.formatDate(root.now, "dddd, d MMMM")
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 13
                    font.weight: Font.Medium
                }

                Rectangle {
                    Layout.topMargin: 14
                    Layout.bottomMargin: 12
                    Layout.preferredWidth: 118
                    Layout.preferredHeight: 1
                    color: RaohaneTheme.accent
                    opacity: 0.58
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        width: 34
                        height: 34
                        radius: 12
                        color: RaohaneTheme.accentSoft
                        border.width: 1
                        border.color: RaohaneTheme.border

                        Text {
                            anchors.centerIn: parent
                            text: RaohaneContext.icon
                            color: RaohaneTheme.accent
                            font.pixelSize: 15
                            font.weight: Font.DemiBold
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            Layout.fillWidth: true
                            text: RaohaneContext.title
                            color: RaohaneTheme.text
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: RaohaneContext.detail
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 9
                            elide: Text.ElideRight
                        }
                    }
                }

                Text {
                    Layout.topMargin: 14
                    text: RaohaneContext.mode === "media"
                        ? qsTr("music is part of the room")
                        : RaohaneContext.mode === "privacy" || RaohaneContext.mode === "recording"
                            ? qsTr("privacy state is visible")
                            : qsTr("静けさの中で動く")
                    color: RaohaneTheme.textMuted
                    opacity: 0.72
                    font.pixelSize: 8
                    font.letterSpacing: 0.7
                }
            }
        }
    }
}
