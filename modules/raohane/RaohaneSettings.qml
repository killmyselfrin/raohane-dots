import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

Scope {
    id: root

    readonly property var focusedScreen: Quickshell.screens.find(screen => screen.name === Hyprland.focusedMonitor?.name)
        ?? Quickshell.screens[0]

    PanelWindow {
        id: panelWindow

        visible: RaohaneState.settingsOpen
        screen: root.focusedScreen
        exclusiveZone: 0
        color: "transparent"
        WlrLayershell.namespace: "quickshell:raohane-settings"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: RaohaneState.settingsOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        function hide(): void {
            settingsSearch.clear()
            RaohaneState.settingsOpen = false
        }

        onVisibleChanged: {
            if (visible)
                RaohaneFocusGrab.addDismissable(panelWindow)
            else
                RaohaneFocusGrab.removeDismissable(panelWindow)
        }

        Connections {
            target: RaohaneFocusGrab
            function onDismissed() { panelWindow.hide() }
        }

        Rectangle {
            anchors.fill: parent
            color: "#72000000"
            opacity: RaohaneState.settingsOpen ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: RaohaneTheme.animationDuration } }

            MouseArea {
                anchors.fill: parent
                onClicked: panelWindow.hide()
            }
        }

        Rectangle {
            id: window

            width: Math.min(parent.width - 72, 1080)
            height: Math.min(parent.height - 72, 720)
            anchors.centerIn: parent
            radius: RaohaneTheme.radiusLarge
            color: RaohaneTheme.surfaceRaised
            border.width: 1
            border.color: RaohaneTheme.border
            clip: true
            opacity: RaohaneState.settingsOpen ? 1 : 0
            scale: RaohaneState.settingsOpen ? 1 : 0.98
            focus: RaohaneState.settingsOpen

            Behavior on opacity { NumberAnimation { duration: RaohaneTheme.animationDuration } }
            Behavior on scale { NumberAnimation { duration: RaohaneTheme.animationDuration; easing.type: Easing.OutCubic } }

            Item {
                id: titleBar
                z: 20

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                }
                height: 50

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 12
                    spacing: 10

                    Text {
                        text: "ラ"
                        color: RaohaneTheme.accent
                        font.pixelSize: 14
                        font.weight: Font.Bold
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: -2

                        Text {
                            text: qsTr("Settings")
                            color: RaohaneTheme.text
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: "設定 · native.json"
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 8
                        }
                    }

                    RaohaneSettingsSearch {
                        id: settingsSearch
                        Layout.preferredWidth: Math.min(320, Math.max(210, window.width * 0.31))
                        Layout.preferredHeight: 32
                    }

                    RaohaneIconButton {
                        buttonSize: 30
                        iconSize: 16
                        icon: "close"
                        onClicked: panelWindow.hide()
                    }
                }

                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                    }
                    height: 1
                    color: "#14ffffff"
                }
            }

            RaohaneSettingsContent {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: titleBar.bottom
                    bottom: parent.bottom
                    margins: 8
                }
            }

            Keys.onPressed: event => {
                if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_F) {
                    settingsSearch.focusSearch()
                    event.accepted = true
                } else if (event.key === Qt.Key_Escape) {
                    if (settingsSearch.query.length > 0) {
                        settingsSearch.clear()
                        window.forceActiveFocus()
                    } else {
                        panelWindow.hide()
                    }
                    event.accepted = true
                }
            }
        }

        IpcHandler {
            target: "settings"
            function toggle(): void { RaohaneState.settingsOpen = !RaohaneState.settingsOpen }
            function open(): void { RaohaneState.settingsOpen = true }
            function close(): void { panelWindow.hide() }
            function status(): string { return RaohaneState.settingsOpen ? "open" : "closed" }
            function page(page: string): void {
                RaohaneState.settingsPage = page
                RaohaneState.settingsOpen = true
            }
        }

        CompositorGlobalShortcut {
            name: "settingsToggle"
            description: "Toggles Raohane settings"
            onPressed: RaohaneState.settingsOpen = !RaohaneState.settingsOpen
        }
    }
}
