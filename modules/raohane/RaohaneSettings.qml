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
            if (visible) {
                workspace.entered = false
                Qt.callLater(() => workspace.entered = true)
                RaohaneFocusGrab.addDismissable(panelWindow)
            } else {
                workspace.entered = false
                RaohaneFocusGrab.removeDismissable(panelWindow)
            }
        }

        Connections {
            target: RaohaneFocusGrab
            function onDismissed() { panelWindow.hide() }
        }

        Rectangle {
            anchors.fill: parent
            color: RaohaneTheme.dark
                ? Qt.rgba(0, 0, 0, 0.40)
                : Qt.rgba(0.20, 0.19, 0.17, 0.18)
            opacity: RaohaneState.settingsOpen ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeStandard }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: panelWindow.hide()
            }
        }

        RaohaneSurface {
            id: workspace
            property bool entered: false

            width: Math.min(parent.width - 80, 1080)
            height: Math.min(parent.height - 88, 724)
            anchors.centerIn: parent
            surfaceRadius: RaohaneTheme.radiusHero
            raised: true
            showSheen: false
            border.color: RaohaneTheme.borderStrong
            clip: true
            opacity: entered ? 1 : 0
            scale: entered ? 1 : 0.992
            focus: RaohaneState.settingsOpen

            transform: Translate {
                y: workspace.entered ? 0 : 12
                Behavior on y {
                    NumberAnimation { duration: RaohaneMotion.enter; easing.type: RaohaneMotion.easeEmphasized }
                }
            }

            Behavior on opacity {
                NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeStandard }
            }

            Behavior on scale {
                NumberAnimation { duration: RaohaneMotion.enter; easing.type: RaohaneMotion.easeEmphasized }
            }

            Rectangle {
                z: 30
                anchors {
                    left: parent.left
                    top: parent.top
                    leftMargin: 22
                }
                width: 72
                height: 2
                radius: 1
                color: RaohaneTheme.accent
                opacity: 0.78
            }

            Item {
                id: titleBar
                z: 20
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                }
                height: 64

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 22
                    anchors.rightMargin: 16
                    spacing: 12

                    ColumnLayout {
                        Layout.preferredWidth: 176
                        spacing: -1

                        Text {
                            text: "RAOHANE"
                            color: RaohaneTheme.accent
                            font.pixelSize: 7
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.4
                        }

                        Text {
                            text: qsTr("Settings")
                            color: RaohaneTheme.text
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                        }
                    }

                    Item { Layout.fillWidth: true }

                    RaohaneSettingsSearch {
                        id: settingsSearch
                        Layout.preferredWidth: Math.min(370, Math.max(260, workspace.width * 0.34))
                        Layout.preferredHeight: 34
                    }

                    Item { Layout.fillWidth: true }

                    Item {
                        Layout.preferredWidth: 176
                        Layout.fillHeight: true

                        RaohaneIconButton {
                            anchors {
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                            }
                            buttonSize: 32
                            iconSize: 16
                            icon: "close"
                            transparentIdle: true
                            showSheen: false
                            onClicked: panelWindow.hide()
                        }
                    }
                }

                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                        leftMargin: 22
                        rightMargin: 16
                    }
                    height: 1
                    color: RaohaneTheme.borderFaint
                }
            }

            RaohaneSettingsContentV2 {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: titleBar.bottom
                    bottom: parent.bottom
                }
            }

            Keys.onPressed: event => {
                if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_F) {
                    settingsSearch.focusSearch()
                    event.accepted = true
                } else if (event.key === Qt.Key_Escape) {
                    if (settingsSearch.query.length > 0) {
                        settingsSearch.clear()
                        workspace.forceActiveFocus()
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
