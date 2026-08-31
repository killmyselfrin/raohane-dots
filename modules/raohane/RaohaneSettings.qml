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
            color: RaohaneTheme.dark ? "#70000000" : "#305b5750"
            opacity: RaohaneState.settingsOpen ? 1 : 0
            Behavior on opacity {
                NumberAnimation { duration: RaohaneMotion.shortDuration; easing.type: RaohaneMotion.easeStandard }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: panelWindow.hide()
            }
        }

        RaohaneSurface {
            id: window

            width: Math.min(parent.width - 96, 1180)
            height: Math.min(parent.height - 96, 780)
            anchors.centerIn: parent
            surfaceRadius: RaohaneTheme.radiusHero
            raised: true
            showSheen: false
            border.color: RaohaneTheme.borderStrong
            clip: true
            opacity: RaohaneState.settingsOpen ? 1 : 0
            scale: RaohaneState.settingsOpen ? 1 : 0.985
            focus: RaohaneState.settingsOpen

            transform: Translate {
                y: RaohaneState.settingsOpen ? 0 : 10
                Behavior on y {
                    NumberAnimation { duration: RaohaneMotion.mediumDuration; easing.type: RaohaneMotion.easeEmphasized }
                }
            }

            Behavior on opacity {
                NumberAnimation { duration: RaohaneMotion.shortDuration; easing.type: RaohaneMotion.easeStandard }
            }
            Behavior on scale {
                NumberAnimation { duration: RaohaneMotion.mediumDuration; easing.type: RaohaneMotion.easeEmphasized }
            }

            Item {
                id: titleBar
                z: 20

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                }
                height: 60

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 14
                    spacing: 11

                    RaohaneSurface {
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 34
                        surfaceRadius: 11
                        active: true
                        showSheen: false

                        RaohaneIcon {
                            anchors.centerIn: parent
                            text: "settings"
                            iconSize: 18
                            fill: 1
                            symbolWeight: 540
                            color: RaohaneTheme.accent
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            text: qsTr("Settings")
                            color: RaohaneTheme.text
                            font.pixelSize: 15
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: qsTr("Raohane shell configuration")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 8
                        }
                    }

                    RaohaneSettingsSearch {
                        id: settingsSearch
                        Layout.preferredWidth: Math.min(340, Math.max(230, window.width * 0.30))
                        Layout.preferredHeight: 34
                    }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 22
                        color: RaohaneTheme.borderFaint
                    }

                    RaohaneIconButton {
                        buttonSize: 32
                        iconSize: 16
                        icon: "close"
                        transparentIdle: true
                        showSheen: false
                        onClicked: panelWindow.hide()
                    }
                }

                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                        leftMargin: 18
                        rightMargin: 18
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
