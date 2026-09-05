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
            implicitHeight: keyboardPanel.implicitHeight + 16

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
                property bool entered: false

                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: parent.bottom
                    bottomMargin: 8
                }
                width: Math.min(oskWindow.width - 24, keyboardRow.implicitWidth + 24)
                implicitHeight: keyboardRow.implicitHeight + 20
                surfaceRadius: 13
                raised: true
                showSheen: false
                border.color: RaohaneTheme.borderStrong
                clip: true
                opacity: entered ? 1 : 0

                Behavior on opacity {
                    NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeStandard }
                }

                Component.onCompleted: Qt.callLater(() => entered = true)

                Rectangle {
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        leftMargin: 13
                        rightMargin: 13
                    }
                    height: 1
                    color: RaohaneTheme.accent
                    opacity: 0.36
                }

                RowLayout {
                    id: keyboardRow
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    RaohaneSurface {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 42
                        Layout.fillHeight: true
                        surfaceRadius: 9
                        raised: false
                        showSheen: false
                        color: RaohaneTheme.surfaceDeep
                        border.color: RaohaneTheme.borderFaint

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 4

                            ControlButton {
                                icon: "keep"
                                toggled: root.pinned
                                onTriggered: RaohaneConfig.oskPinned = !RaohaneConfig.oskPinned
                            }

                            RaohaneSurface {
                                id: layoutButton
                                width: 34
                                height: 34
                                surfaceRadius: 8
                                active: true
                                showSheen: false
                                interactive: true
                                hovered: layoutMouse.containsMouse || activeFocus
                                pressed: layoutMouse.pressed
                                hoverScale: 1
                                pressedScale: 1
                                activeFocusOnTab: true
                                border.color: layoutButton.hovered ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint

                                Text {
                                    anchors.centerIn: parent
                                    text: oskContent.currentLayout?.name_short ?? "KB"
                                    color: layoutButton.hovered ? RaohaneTheme.accent : RaohaneTheme.text
                                    font.pixelSize: 8
                                    font.weight: Font.DemiBold

                                    Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
                                }

                                MouseArea {
                                    id: layoutMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onPressed: layoutButton.forceActiveFocus()
                                    onClicked: {
                                        oskContent.cycleLayout()
                                        RaohaneConfig.oskLayout = oskContent.layoutName
                                    }
                                }

                                Keys.onPressed: event => {
                                    if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                        oskContent.cycleLayout()
                                        RaohaneConfig.oskLayout = oskContent.layoutName
                                        event.accepted = true
                                    }
                                }
                            }

                            ControlButton {
                                icon: "keyboard_hide"
                                onTriggered: root.close()
                            }
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

    component ControlButton: RaohaneIconButton {
        id: control
        property bool toggled: false
        signal triggered()

        buttonSize: 34
        iconSize: 15
        emphasized: toggled
        transparentIdle: !toggled
        showSheen: false
        hoverScale: 1
        pressedScale: 1
        onClicked: control.triggered()
    }
}
