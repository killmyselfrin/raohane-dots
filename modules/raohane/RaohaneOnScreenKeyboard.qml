pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

import qs.modules.raohane.services

Scope {
    id: root

    property bool pinned: false
    property string layoutName: "English (US)"

    function close(): void {
        RaohaneState.oskOpen = false
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

            Rectangle {
                id: keyboardPanel

                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: parent.bottom
                    bottomMargin: 6
                }
                width: Math.min(oskWindow.width - 20, keyboardRow.implicitWidth + 28)
                implicitHeight: keyboardRow.implicitHeight + 24
                radius: 20
                color: RaohaneTheme.glass
                border.width: 1
                border.color: RaohaneTheme.border
                clip: true

                RowLayout {
                    id: keyboardRow
                    anchors {
                        fill: parent
                        margins: 12
                    }
                    spacing: 10

                    ColumnLayout {
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 6

                        Rectangle {
                            width: 42
                            height: 42
                            radius: 13
                            color: pinMouse.containsMouse || root.pinned ? RaohaneTheme.accentSoft : "#18ffffff"
                            border.width: 1
                            border.color: root.pinned ? RaohaneTheme.accent : RaohaneTheme.border

                            RaohaneIcon {
                                anchors.centerIn: parent
                                text: "keep"
                                iconSize: 19
                                color: root.pinned ? RaohaneTheme.accent : RaohaneTheme.textMuted
                            }

                            MouseArea {
                                id: pinMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.pinned = !root.pinned
                            }
                        }

                        Rectangle {
                            width: 42
                            height: 42
                            radius: 13
                            color: layoutMouse.containsMouse ? RaohaneTheme.accentSoft : "#18ffffff"
                            border.width: 1
                            border.color: RaohaneTheme.border

                            Text {
                                anchors.centerIn: parent
                                text: oskContent.currentLayout?.name_short ?? "KB"
                                color: RaohaneTheme.text
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                            }

                            MouseArea {
                                id: layoutMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    oskContent.cycleLayout()
                                    root.layoutName = oskContent.layoutName
                                }
                            }
                        }

                        Rectangle {
                            width: 42
                            height: 42
                            radius: 13
                            color: closeMouse.containsMouse ? RaohaneTheme.accentSoft : "#18ffffff"
                            border.width: 1
                            border.color: RaohaneTheme.border

                            RaohaneIcon {
                                anchors.centerIn: parent
                                text: "keyboard_hide"
                                iconSize: 19
                                color: RaohaneTheme.textMuted
                            }

                            MouseArea {
                                id: closeMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.close()
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        color: RaohaneTheme.border
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
}
