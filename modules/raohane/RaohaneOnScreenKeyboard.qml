pragma ComponentBehavior: Bound

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
    readonly property bool pinned: RaohaneConfig.oskPinned
    readonly property string layoutName: RaohaneConfig.oskLayout

    function close(): void { RaohaneState.oskOpen = false }

    Connections {
        target: RaohaneState
        function onScreenLockedChanged(): void {
            if (!RaohaneState.screenLocked)
                return
            RaohaneYdotool.releaseAllKeys()
            root.close()
        }
    }

    Loader {
        id: oskLoader
        active: RaohaneState.oskOpen

        onActiveChanged: {
            if (!active)
                RaohaneYdotool.releaseAllKeys()
        }

        sourceComponent: PanelWindow {
            id: oskWindow

            visible: oskLoader.active && !RaohaneState.screenLocked
            screen: root.focusedScreen
            color: "transparent"
            exclusionMode: ExclusionMode.Normal
            exclusiveZone: root.pinned ? implicitHeight : 0
            implicitHeight: keyboardPanel.implicitHeight + 12

            anchors {
                bottom: true
                left: true
                right: true
            }

            WlrLayershell.namespace: "quickshell:raohane-osk"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            mask: Region { item: keyboardPanel }

            RaohaneSurface {
                id: keyboardPanel

                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: parent.bottom
                    bottomMargin: 6
                }
                width: Math.min(oskWindow.width - 20, keyboardRow.implicitWidth + 26)
                implicitHeight: keyboardRow.implicitHeight + 22
                surfaceRadius: 19
                raised: true
                showSheen: false
                border.color: RaohaneTheme.borderStrong
                clip: true

                RowLayout {
                    id: keyboardRow
                    anchors.fill: parent
                    anchors.margins: 11
                    spacing: 9

                    ColumnLayout {
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 5

                        ControlButton {
                            icon: "keep"
                            active: root.pinned
                            onTriggered: RaohaneConfig.oskPinned = !RaohaneConfig.oskPinned
                        }

                        Rectangle {
                            width: 40
                            height: 40
                            radius: 11
                            color: layoutMouse.containsMouse ? RaohaneTheme.surfaceHover : "transparent"
                            border.width: 1
                            border.color: layoutMouse.containsMouse ? RaohaneTheme.borderStrong : RaohaneTheme.border

                            Text {
                                anchors.centerIn: parent
                                text: oskContent.currentLayout?.name_short ?? "KB"
                                color: RaohaneTheme.text
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                            }

                            MouseArea {
                                id: layoutMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    oskContent.cycleLayout()
                                    RaohaneConfig.oskLayout = oskContent.layoutName
                                }
                            }
                        }

                        ControlButton {
                            icon: "keyboard_hide"
                            onTriggered: root.close()
                        }
                    }

                    Rectangle {
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        color: RaohaneTheme.borderFaint
                    }

                    RaohaneOskContent {
                        id: oskContent
                        Layout.alignment: Qt.AlignVCenter
                        layoutName: root.layoutName
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "osk"
        function toggle(): void { RaohaneState.oskOpen = !RaohaneState.oskOpen }
        function open(): void { RaohaneState.oskOpen = true }
        function close(): void { RaohaneState.oskOpen = false }
    }

    CompositorGlobalShortcut {
        name: "oskToggle"
        description: "Toggle Raohane on-screen keyboard"
        onPressed: RaohaneState.oskOpen = !RaohaneState.oskOpen
    }
    CompositorGlobalShortcut {
        name: "oskOpen"
        description: "Open Raohane on-screen keyboard"
        onPressed: RaohaneState.oskOpen = true
    }
    CompositorGlobalShortcut {
        name: "oskClose"
        description: "Close Raohane on-screen keyboard"
        onPressed: RaohaneState.oskOpen = false
    }

    component ControlButton: Rectangle {
        id: control
        required property string icon
        property bool active: false
        signal triggered()

        width: 40
        height: 40
        radius: 11
        color: active ? RaohaneTheme.surfaceRaised
            : pointer.containsMouse ? RaohaneTheme.surfaceHover : "transparent"
        border.width: 1
        border.color: active ? RaohaneTheme.borderStrong : RaohaneTheme.border

        RaohaneIcon {
            anchors.centerIn: parent
            text: control.icon
            iconSize: 18
            fill: control.active ? 1 : 0
            color: control.active ? RaohaneTheme.accent : RaohaneTheme.textMuted
        }

        MouseArea {
            id: pointer
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: control.triggered()
        }
    }
}
