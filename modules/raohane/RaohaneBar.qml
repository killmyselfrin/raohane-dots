pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQml
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

import qs.modules.raohane.config
import qs.modules.raohane.services

Scope {
    id: root

    function styleValue(key: string, fallback): var {
        const style = RaohaneConfig.style
        if (!style || !Object.prototype.hasOwnProperty.call(style, key))
            return fallback
        return style[key]
    }

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
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            implicitHeight: 64

            property bool superShow: false
            readonly property bool autoHide: RaohaneConfig.barAutoHide
            readonly property bool mustShow: !autoHide || hoverRegion.containsMouse || superShow
            readonly property var hyprMonitor: Hyprland.monitorFor(barWindow.screen)
            readonly property bool monitorHasFullscreen: hyprMonitor?.activeWorkspace?.hasFullscreen ?? false
            readonly property bool monitorHasSpecialOpen: (hyprMonitor?.lastIpcObject?.specialWorkspace?.name ?? "") !== ""
            readonly property bool effectiveFullscreen: monitorHasFullscreen && !monitorHasSpecialOpen
            readonly property bool fullscreenSuppressed: effectiveFullscreen && !superShow
            readonly property real podScale: Number(root.styleValue("barScale", 1.0))
            readonly property int podHeight: Math.max(38, Math.min(48, Math.round(RaohaneTheme.barHeight * podScale)))

            visible: RaohaneState.barOpen && !RaohaneState.screenLocked && !fullscreenSuppressed
            exclusiveZone: fullscreenSuppressed
                ? 0
                : (autoHide && (!mustShow || !RaohaneConfig.barAutoHidePushWindows))
                    ? 0
                    : implicitHeight

            WlrLayershell.namespace: "quickshell:raohane-bar"
            WlrLayershell.layer: (monitorHasFullscreen && (monitorHasSpecialOpen || superShow))
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
                height: 52
                y: {
                    if (barWindow.mustShow)
                        return RaohaneConfig.barBottom ? barWindow.height - height - 6 : 6
                    return RaohaneConfig.barBottom ? barWindow.height + 2 : -height - 4
                }

                Behavior on y {
                    NumberAnimation {
                        duration: RaohaneTheme.animationDuration
                        easing.type: Easing.OutCubic
                    }
                }

                RaohaneSurface {
                    id: leftIsland
                    anchors {
                        left: parent.left
                        leftMargin: 14
                        verticalCenter: parent.verticalCenter
                    }
                    width: Math.min(parent.width * 0.38, leftRow.implicitWidth + 24)
                    height: barWindow.podHeight
                    surfaceRadius: Math.min(Math.round(height * 0.42), height / 2)
                    raised: true

                    Rectangle {
                        anchors {
                            left: parent.left
                            leftMargin: 1
                            verticalCenter: parent.verticalCenter
                        }
                        width: 2
                        height: Math.min(18, parent.height - 12)
                        radius: 1
                        color: RaohaneTheme.accent
                        opacity: 0.72
                    }

                    RowLayout {
                        id: leftRow
                        anchors {
                            fill: parent
                            leftMargin: 8
                            rightMargin: 9
                        }
                        spacing: 6

                        Rectangle {
                            width: 30
                            height: 30
                            radius: 12
                            color: launcherMouse.containsMouse
                                ? RaohaneTheme.accentHover
                                : RaohaneTheme.accentSoft
                            border.width: 1
                            border.color: launcherMouse.containsMouse
                                ? RaohaneTheme.accentGlow
                                : RaohaneTheme.border

                            Text {
                                anchors.centerIn: parent
                                text: "ラ"
                                color: RaohaneTheme.text
                                font.pixelSize: 13
                                font.weight: Font.Bold
                            }

                            MouseArea {
                                id: launcherMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: RaohaneState.togglePrimary("launcher")
                            }
                        }

                        Rectangle {
                            width: 1
                            Layout.preferredHeight: 18
                            color: RaohaneTheme.borderFaint
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
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor

                        onClicked: mouse => {
                            if (RaohaneContext.mode !== "media") {
                                if (mouse.button === Qt.LeftButton)
                                    RaohaneState.togglePrimary("controlCenter")
                                return
                            }

                            if (mouse.button === Qt.MiddleButton) {
                                RaohaneMedia.togglePlaying()
                            } else if (mouse.button === Qt.RightButton) {
                                RaohaneMedia.cyclePlayer(1)
                            } else {
                                RaohaneState.mediaOverlayOpen = !RaohaneState.mediaOverlayOpen
                            }
                        }

                        onWheel: wheel => {
                            if (RaohaneContext.mode !== "media" || !RaohaneMedia.volumeSupported)
                                return
                            const step = wheel.angleDelta.y >= 0 ? 0.04 : -0.04
                            RaohaneMedia.setVolume(RaohaneMedia.volume + step)
                            wheel.accepted = true
                        }
                    }
                }

                RaohaneSurface {
                    id: rightIsland
                    anchors {
                        right: parent.right
                        rightMargin: 14
                        verticalCenter: parent.verticalCenter
                    }
                    width: Math.min(parent.width * 0.38, Math.max(184, rightRow.implicitWidth + 22))
                    height: barWindow.podHeight
                    surfaceRadius: Math.min(Math.round(height * 0.42), height / 2)
                    raised: true

                    Rectangle {
                        anchors {
                            right: parent.right
                            rightMargin: 1
                            verticalCenter: parent.verticalCenter
                        }
                        width: 2
                        height: Math.min(18, parent.height - 12)
                        radius: 1
                        color: RaohaneTheme.accentSecondary
                        opacity: 0.5
                    }

                    RowLayout {
                        id: rightRow
                        anchors {
                            fill: parent
                            leftMargin: 8
                            rightMargin: 8
                        }
                        spacing: 7

                        RaohaneSysTray {
                            Layout.alignment: Qt.AlignVCenter
                            parentWindow: barWindow
                        }

                        RaohaneSystemIcons {
                            Layout.alignment: Qt.AlignVCenter
                            onActivated: RaohaneState.togglePrimary("controlCenter")
                        }

                        Rectangle {
                            width: 1
                            Layout.preferredHeight: 18
                            color: RaohaneTheme.borderFaint
                        }

                        RaohaneClock {
                            Layout.alignment: Qt.AlignVCenter
                            showDate: RaohaneConfig.barShowDate
                            active: barWindow.visible
                        }

                        Rectangle {
                            width: 30
                            height: 30
                            radius: 12
                            color: controlMouse.containsMouse
                                ? RaohaneTheme.accentHover
                                : "transparent"
                            border.width: controlMouse.containsMouse ? 1 : 0
                            border.color: RaohaneTheme.accentGlow

                            RaohaneIcon {
                                anchors.centerIn: parent
                                text: "tune"
                                iconSize: 15
                                color: controlMouse.containsMouse
                                    ? RaohaneTheme.accent
                                    : RaohaneTheme.textMuted
                            }

                            MouseArea {
                                id: controlMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: RaohaneState.togglePrimary("controlCenter")
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "bar"
        function toggle(): void { RaohaneState.barOpen = !RaohaneState.barOpen }
        function open(): void { RaohaneState.barOpen = true }
        function close(): void { RaohaneState.barOpen = false }
        function mode(): string { return "horizontal" }
    }

    CompositorGlobalShortcut {
        name: "barToggle"
        description: "Toggles the Raohane bar"
        onPressed: RaohaneState.barOpen = !RaohaneState.barOpen
    }
}
