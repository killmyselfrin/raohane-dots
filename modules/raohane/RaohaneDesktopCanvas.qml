pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.modules.raohane.config
import qs.modules.raohane.services

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
        readonly property bool canvasVisible: !RaohaneState.screenLocked
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
            opacity: desktopWindow.canvasVisible && RaohaneConfig.desktopWidgetsEnabled ? 1 : 0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation {
                    duration: RaohaneMotion.standard
                    easing.type: RaohaneMotion.easeStandard
                }
            }

            ColumnLayout {
                anchors {
                    left: parent.left
                    top: parent.top
                    leftMargin: 54
                    topMargin: 92
                }
                width: Math.min(RaohaneConfig.desktopWidgetsCompact ? 390 : 520, parent.width * 0.42)
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
                        text: "ラオハネ  ·  RAOHANE"
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.4
                    }
                }

                Text {
                    visible: RaohaneConfig.desktopWidgetClock
                    Layout.topMargin: 5
                    text: Qt.formatTime(root.now, "HH:mm")
                    color: RaohaneTheme.text
                    font.pixelSize: 70
                    font.weight: Font.Light
                    font.letterSpacing: -2.8
                }

                Text {
                    visible: RaohaneConfig.desktopWidgetClock
                    text: Qt.formatDate(root.now, "dddd, d MMMM")
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 13
                    font.weight: Font.Medium
                }

                Rectangle {
                    visible: RaohaneConfig.desktopWidgetClock && RaohaneConfig.desktopWidgetContext
                    Layout.topMargin: 14
                    Layout.bottomMargin: 12
                    Layout.preferredWidth: 118
                    Layout.preferredHeight: 1
                    color: RaohaneTheme.accent
                    opacity: 0.58
                }

                RowLayout {
                    visible: RaohaneConfig.desktopWidgetContext
                    Layout.fillWidth: true
                    spacing: 10

                    RaohaneSurface {
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 34
                        surfaceRadius: 12
                        raised: false
                        active: RaohaneContext.mode === "privacy" || RaohaneContext.mode === "recording"
                        showSheen: false

                        RaohaneIcon {
                            anchors.centerIn: parent
                            text: RaohaneContext.icon
                            iconSize: 16
                            fill: RaohaneContext.mode === "media"
                                || RaohaneContext.mode === "privacy"
                                || RaohaneContext.mode === "recording" ? 1 : 0
                            color: RaohaneTheme.accent
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
                    visible: RaohaneConfig.desktopWidgetContext
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

            ColumnLayout {
                anchors {
                    right: parent.right
                    bottom: parent.bottom
                    rightMargin: 54
                    bottomMargin: RaohaneConfig.dockEnabled ? 116 : 54
                }
                width: RaohaneConfig.desktopWidgetsCompact ? 220 : 276
                spacing: 10

                RaohaneSurface {
                    visible: RaohaneConfig.desktopWidgetSystem
                    Layout.fillWidth: true
                    Layout.preferredHeight: RaohaneConfig.desktopWidgetsCompact ? 72 : 86
                    surfaceRadius: 20
                    raised: false
                    showSheen: false
                    opacity: visible ? 0.92 : 0

                    Behavior on opacity { NumberAnimation { duration: RaohaneMotion.standard } }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: qsTr("SYSTEM")
                                color: RaohaneTheme.textFaint
                                font.pixelSize: 8
                                font.weight: Font.DemiBold
                                font.letterSpacing: 1.1
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: RaohaneSystemInfo.hostname
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 8
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            StatusItem {
                                Layout.fillWidth: true
                                icon: RaohaneNetwork.materialSymbol
                                label: RaohaneNetwork.networkName || (RaohaneNetwork.ethernet ? qsTr("Ethernet") : qsTr("Offline"))
                                active: RaohaneNetwork.wifiConnected || RaohaneNetwork.ethernet
                            }
                            StatusItem {
                                Layout.fillWidth: true
                                icon: RaohaneAudio.muted ? "volume_off" : "volume_up"
                                label: RaohaneAudio.muted ? qsTr("Muted") : Math.round(RaohaneAudio.volume * 100) + "%"
                                active: !RaohaneAudio.muted
                            }
                        }
                    }
                }

                RaohaneSurface {
                    visible: RaohaneConfig.desktopWidgetMotto
                    Layout.fillWidth: true
                    Layout.preferredHeight: RaohaneConfig.desktopWidgetsCompact ? 48 : 58
                    surfaceRadius: 18
                    raised: false
                    showSheen: false

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 10

                        Rectangle {
                            Layout.preferredWidth: 2
                            Layout.preferredHeight: 24
                            radius: 1
                            color: RaohaneTheme.accent
                            opacity: 0.68
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Text {
                                text: qsTr("Move gently. Stay present.")
                                color: RaohaneTheme.text
                                font.pixelSize: 10
                                font.weight: Font.Medium
                            }
                            Text {
                                visible: !RaohaneConfig.desktopWidgetsCompact
                                text: "静かに、前へ"
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 8
                                font.letterSpacing: 0.8
                            }
                        }
                        RaohaneIcon {
                            text: "spa"
                            iconSize: 17
                            fill: 0.16
                            color: RaohaneTheme.accent
                        }
                    }
                }
            }
        }
    }

    component StatusItem: RowLayout {
        id: statusItem
        required property string icon
        required property string label
        property bool active: false
        spacing: 5

        RaohaneIcon {
            text: statusItem.icon
            iconSize: 13
            color: statusItem.active ? RaohaneTheme.accent : RaohaneTheme.textFaint
        }
        Text {
            Layout.fillWidth: true
            text: statusItem.label
            color: RaohaneTheme.textMuted
            font.pixelSize: 9
            elide: Text.ElideRight
        }
    }
}
