pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQml
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

import qs.modules.raohane.config

// Raohane-owned shell chrome. Workspaces, tray, status, clock, configuration
// and runtime state are all native and resolve only Raohane-owned contracts.
Scope {
    id: root

    Variants {
        model: {
            const screens = Quickshell.screens
            const configured = RaohaneConfig.barScreenList
            if (!configured || configured.length === 0)
                return screens
            return screens.filter(screen => configured.includes(screen.name))
        }

        PanelWindow {
            id: barWindow
            required property ShellScreen modelData

            screen: modelData
            visible: RaohaneState.barOpen && !RaohaneState.screenLocked
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            implicitHeight: 64

            property bool superShow: false
            readonly property bool autoHide: RaohaneConfig.barAutoHide
            readonly property bool mustShow: !autoHide || hoverRegion.containsMouse || superShow
            readonly property var hyprMonitor: Hyprland.monitorFor(barWindow.screen)
            readonly property bool monitorHasFullscreen: hyprMonitor?.activeWorkspace?.hasFullscreen ?? false
            readonly property bool monitorHasSpecialOpen: (hyprMonitor?.lastIpcObject?.specialWorkspace?.name ?? "") !== ""

            exclusiveZone: (autoHide && (!mustShow || !RaohaneConfig.barAutoHidePushWindows))
                ? 0
                : implicitHeight

            WlrLayershell.namespace: "quickshell:raohane-bar"
            WlrLayershell.layer: (monitorHasFullscreen && monitorHasSpecialOpen)
                ? WlrLayer.Overlay
                : WlrLayer.Top

            anchors {
                top: !RaohaneConfig.barBottom
                bottom: RaohaneConfig.barBottom
                left: true
                right: true
            }

            Timer {
                id: superRevealTimer
                interval: RaohaneConfig.barShowOnSuperDelay
                repeat: false
                onTriggered: barWindow.superShow = true
            }

            Connections {
                target: RaohaneState

                function onSuperDownChanged(): void {
                    if (!RaohaneConfig.barShowOnSuper)
                        return
                    if (RaohaneState.superDown) {
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
                        return RaohaneConfig.barBottom
                            ? barWindow.height - height - 5
                            : 5
                    return RaohaneConfig.barBottom
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
                                    RaohaneState.overviewOpen = false
                                    RaohaneState.launcherOpen = !RaohaneState.launcherOpen
                                }
                            }
                        }

                        Rectangle {
                            width: 1
                            Layout.preferredHeight: 22
                            color: RaohaneTheme.border
                        }

                        RaohaneWorkspaces {
                            Layout.alignment: Qt.AlignVCenter
                            screen: barWindow.screen
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
                                RaohaneState.controlCenterOpen = !RaohaneState.controlCenterOpen
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

                        RaohaneSysTray {
                            Layout.alignment: Qt.AlignVCenter
                            parentWindow: barWindow
                        }

                        RaohaneSystemIcons {
                            Layout.alignment: Qt.AlignVCenter
                            onActivated: RaohaneState.controlCenterOpen = !RaohaneState.controlCenterOpen
                        }

                        Rectangle {
                            width: 1
                            Layout.preferredHeight: 22
                            color: RaohaneTheme.border
                        }

                        RaohaneClock {
                            Layout.alignment: Qt.AlignVCenter
                            showDate: RaohaneConfig.barShowDate
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
                                onClicked: RaohaneState.controlCenterOpen = !RaohaneState.controlCenterOpen
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
            RaohaneState.barOpen = !RaohaneState.barOpen
        }

        function open(): void {
            RaohaneState.barOpen = true
        }

        function close(): void {
            RaohaneState.barOpen = false
        }
    }

    CompositorGlobalShortcut {
        name: "barToggle"
        description: "Toggles the Raohane bar"
        onPressed: RaohaneState.barOpen = !RaohaneState.barOpen
    }
}
