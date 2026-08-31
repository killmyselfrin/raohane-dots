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
                ? Qt.rgba(0, 0, 0, 0.42)
                : Qt.rgba(0.20, 0.19, 0.17, 0.20)
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

            width: Math.min(parent.width - 64, 1120)
            height: Math.min(parent.height - 72, 760)
            anchors.centerIn: parent
            surfaceRadius: RaohaneTheme.radiusHero
            raised: true
            showSheen: false
            border.color: RaohaneTheme.borderStrong
            clip: true
            opacity: entered ? 1 : 0
            scale: entered ? 1 : 0.988
            focus: RaohaneState.settingsOpen

            transform: Translate {
                y: workspace.entered ? 0 : 14
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
                    anchors.leftMargin: 22
                    anchors.rightMargin: 16
                    spacing: 12

                    ColumnLayout {
                        Layout.preferredWidth: 190
                        spacing: -1

                        Text {
                            text: "RAOHANE"
                            color: RaohaneTheme.accent
                            font.pixelSize: 7
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.2
                        }

                        Text {
                            text: qsTr("Settings")
                            color: RaohaneTheme.text
                            font.pixelSize: 17
                            font.weight: Font.DemiBold
                        }
                    }

                    Item { Layout.fillWidth: true }

                    RaohaneSettingsSearch {
                        id: settingsSearch
                        Layout.preferredWidth: Math.min(390, Math.max(260, workspace.width * 0.35))
                        Layout.preferredHeight: 34
                    }

                    Item { Layout.fillWidth: true }

                    RowLayout {
                        spacing: 5

                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            color: RaohaneTheme.success
                        }

                        Text {
                            text: qsTr("LIVE")
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 7
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.7
                        }
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
