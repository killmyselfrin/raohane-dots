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
            RaohaneState.setPrimaryOpen("settings", false)
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
            color: RaohaneTheme.dark ? "#78000000" : "#385b5750"
            opacity: RaohaneState.settingsOpen ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: RaohaneTheme.animationDuration } }

            MouseArea {
                anchors.fill: parent
                onClicked: panelWindow.hide()
            }
        }

        Rectangle {
            anchors.centerIn: window
            width: window.width + 10
            height: window.height + 10
            radius: RaohaneTheme.radiusHero + 5
            color: "transparent"
            border.width: 1
            border.color: RaohaneTheme.borderFaint
            opacity: RaohaneState.settingsOpen ? 0.75 : 0
        }

        RaohaneSurface {
            id: window

            width: Math.min(parent.width - 88, 1240)
            height: Math.min(parent.height - 88, 800)
            anchors.centerIn: parent
            surfaceRadius: RaohaneTheme.radiusHero
            raised: true
            border.color: RaohaneTheme.borderStrong
            clip: true
            opacity: RaohaneState.settingsOpen ? 1 : 0
            scale: RaohaneState.settingsOpen ? 1 : 0.975
            focus: RaohaneState.settingsOpen

            Behavior on opacity { NumberAnimation { duration: RaohaneTheme.animationDuration } }
            Behavior on scale {
                NumberAnimation {
                    duration: RaohaneTheme.animationSlow
                    easing.type: Easing.OutCubic
                }
            }

            Item {
                id: titleBar
                z: 20

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                }
                height: 68

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 16
                    spacing: 12

                    Rectangle {
                        Layout.preferredWidth: 38
                        Layout.preferredHeight: 38
                        radius: 13
                        color: RaohaneTheme.surfaceSubtle
                        border.width: 1
                        border.color: RaohaneTheme.border

                        Text {
                            anchors.centerIn: parent
                            text: "ラ"
                            color: RaohaneTheme.accent
                            font.pixelSize: 15
                            font.weight: Font.DemiBold
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: qsTr("Raohane Settings")
                            color: RaohaneTheme.text
                            font.pixelSize: 17
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: qsTr("Minimal shell configuration")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 9
                        }
                    }

                    RaohaneSettingsSearch {
                        id: settingsSearch
                        Layout.preferredWidth: Math.min(360, Math.max(240, window.width * 0.31))
                        Layout.preferredHeight: 36
                    }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 24
                        color: RaohaneTheme.borderFaint
                    }

                    RaohaneIconButton {
                        buttonSize: 34
                        iconSize: 17
                        icon: "close"
                        onClicked: panelWindow.hide()
                    }
                }

                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                        leftMargin: 20
                        rightMargin: 20
                    }
                    height: 1
                    color: RaohaneTheme.borderFaint
                }
            }

            RaohaneSettingsContent {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: titleBar.bottom
                    bottom: parent.bottom
                    margins: 10
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
            function toggle(): void { RaohaneState.togglePrimary("settings") }
            function open(): void { RaohaneState.setPrimaryOpen("settings", true) }
            function close(): void { panelWindow.hide() }
            function status(): string { return RaohaneState.settingsOpen ? "open" : "closed" }
            function page(page: string): void {
                RaohaneState.settingsPage = page
                RaohaneState.setPrimaryOpen("settings", true)
            }
        }

        CompositorGlobalShortcut {
            name: "settingsToggle"
            description: "Toggles Raohane settings"
            onPressed: RaohaneState.togglePrimary("settings")
        }
    }
}
