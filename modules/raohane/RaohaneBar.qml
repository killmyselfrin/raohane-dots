pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQml
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

import qs
import qs.services
import qs.modules.common
import qs.modules.ii.bar

// Raohane-owned shell chrome using the mature end4-pC workspace, tray and
// system backends. The presentation lives here while hardware/system behavior
// remains delegated to tested foundation services during migration.
Scope {
    id: root

    Variants {
        model: {
            const screens = Quickshell.screens
            const configured = Config.options.bar.screenList
            if (!configured || configured.length === 0)
                return screens
            return screens.filter(screen => configured.includes(screen.name))
        }

        PanelWindow {
            id: barWindow
            required property ShellScreen modelData

            screen: modelData
            visible: GlobalStates.barOpen && !GlobalStates.screenLocked
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            implicitHeight: 64

            property bool superShow: false
            readonly property bool autoHide: Config.options.bar.autoHide.enable
            readonly property bool mustShow: !autoHide || hoverRegion.containsMouse || superShow
            readonly property var monitorData: HyprlandData.monitors.find(m => m.name === barWindow.screen?.name)
            readonly property bool monitorHasFullscreen: HyprlandData.workspaceById[monitorData?.activeWorkspace?.id]?.hasfullscreen ?? false
            readonly property bool monitorHasSpecialOpen: (monitorData?.specialWorkspace?.name ?? "") !== ""

            exclusiveZone: (autoHide && (!mustShow || !Config.options.bar.autoHide.pushWindows))
                ? 0
                : implicitHeight

            WlrLayershell.namespace: "quickshell:raohane-bar"
            WlrLayershell.layer: (monitorHasFullscreen && monitorHasSpecialOpen)
                ? WlrLayer.Overlay
                : WlrLayer.Top

            anchors {
                top: !Config.options.bar.bottom
                bottom: Config.options.bar.bottom
                left: true
                right: true
            }

            Timer {
                id: superRevealTimer
                interval: Config.options.bar.autoHide.showWhenPressingSuper.delay ?? 140
                repeat: false
                onTriggered: barWindow.superShow = true
            }

            Connections {
                target: GlobalStates

                function onSuperDownChanged(): void {
                    if (!Config.options.bar.autoHide.showWhenPressingSuper.enable)
                        return
                    if (GlobalStates.superDown) {
                        superRevealTimer.restart()
                    } else {
                        superRevealTimer.stop()
                        barWindow.superShow = false
                    }
                }
            }

            MouseArea {
                id: hoverRegion
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
            }

            Item {
                id: barContent
                width: parent.width
                height: 54
                y: {
                    if (barWindow.mustShow)
                        return Config.options.bar.bottom
                            ? barWindow.height - height - 5
                            : 5
                    return Config.options.bar.bottom
                        ? barWindow.height + 2
                        : -height - 2
                }

                Behavior on y {
                    NumberAnimation {
                        duration: RaohaneTheme.animationDuration
                        easing.type: Easing.OutCubic
                    }
                }

                Rectangle {
                    id: leftIsland
                    anchors {
                        left: parent.left
                        leftMargin: 14
                        verticalCenter: parent.verticalCenter
                    }
                    width: Math.min(parent.width * 0.38, leftRow.implicitWidth + 20)
                    height: RaohaneTheme.barHeight
                    radius: RaohaneTheme.radius
                    color: RaohaneTheme.glass
                    border.width: 1
                    border.color: RaohaneTheme.border

                    RowLayout {
                        id: leftRow
                        anchors {
                            fill: parent
                            leftMargin: 8
                            rightMargin: 8
                        }
                        spacing: 6

                        Rectangle {
                            width: 30
                            height: 30
                            radius: 11
                            color: launcherMouse.containsMouse
                                ? RaohaneTheme.accentSoft
                                : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "ラ"
                                color: RaohaneTheme.accent
                                font.pixelSize: 15
                                font.weight: Font.Bold
                            }

                            MouseArea {
                                id: launcherMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    GlobalStates.overviewOpen = false
                                    RaohaneState.launcherOpen = !RaohaneState.launcherOpen
                                }
                            }
                        }

                        Rectangle {
                            width: 1
                            Layout.preferredHeight: 22
                            color: RaohaneTheme.border
                        }

                        Workspaces {
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }
                }

                RaohaneContextIsland {
                    id: contextIsland
                    anchors.centerIn: parent

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (RaohaneContext.mode === "media")
                                RaohaneState.mediaOverlayOpen = !RaohaneState.mediaOverlayOpen
                            else
                                GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen
                        }
                    }
                }

                Rectangle {
                    id: rightIsland
                    anchors {
                        right: parent.right
                        rightMargin: 14
                        verticalCenter: parent.verticalCenter
                    }
                    width: Math.min(parent.width * 0.38, Math.max(190, rightRow.implicitWidth + 22))
                    height: RaohaneTheme.barHeight
                    radius: RaohaneTheme.radius
                    color: RaohaneTheme.glass
                    border.width: 1
                    border.color: RaohaneTheme.border

                    RowLayout {
                        id: rightRow
                        anchors {
                            fill: parent
                            leftMargin: 9
                            rightMargin: 9
                        }
                        spacing: 8

                        SysTray {
                            Layout.alignment: Qt.AlignVCenter
                        }

                        SystemIcons {
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Rectangle {
                            width: 1
                            Layout.preferredHeight: 22
                            color: RaohaneTheme.border
                        }

                        ColumnLayout {
                            Layout.alignment: Qt.AlignVCenter
                            spacing: -2

                            Text {
                                text: DateTime.time
                                color: RaohaneTheme.text
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }

                            Text {
                                visible: Config.options.time.showDate
                                text: DateTime.shortDate
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 8
                            }
                        }

                        Rectangle {
                            width: 30
                            height: 30
                            radius: 11
                            color: controlMouse.containsMouse
                                ? RaohaneTheme.accentSoft
                                : "transparent"

                            RaohaneIcon {
                                anchors.centerIn: parent
                                text: "tune"
                                iconSize: 17
                                color: RaohaneTheme.text
                            }

                            MouseArea {
                                id: controlMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "bar"

        function toggle(): void {
            GlobalStates.barOpen = !GlobalStates.barOpen
        }

        function open(): void {
            GlobalStates.barOpen = true
        }

        function close(): void {
            GlobalStates.barOpen = false
        }
    }

    CompositorGlobalShortcut {
        name: "barToggle"
        description: "Toggles the Raohane bar"
        onPressed: GlobalStates.barOpen = !GlobalStates.barOpen
    }
}
