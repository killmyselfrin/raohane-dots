import QtQuick
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
                ? Qt.rgba(0, 0, 0, 0.46)
                : Qt.rgba(0.18, 0.17, 0.15, 0.18)

            MouseArea {
                anchors.fill: parent
                onClicked: panelWindow.hide()
            }
        }

        RaohaneSurface {
            id: workspace
            property bool entered: false

            width: Math.min(parent.width - 96, 1040)
            height: Math.min(parent.height - 96, 700)
            anchors.centerIn: parent
            surfaceRadius: RaohaneTheme.radiusHero
            raised: true
            showSheen: false
            border.color: RaohaneTheme.borderStrong
            clip: true
            opacity: entered ? 1 : 0
            focus: RaohaneState.settingsOpen

            Behavior on opacity {
                NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeStandard }
            }

            Rectangle {
                z: 40
                anchors {
                    left: parent.left
                    top: parent.top
                    leftMargin: 18
                }
                width: 54
                height: 2
                radius: 1
                color: RaohaneTheme.accent
                opacity: 0.72
            }

            RaohaneSettingsContentV3 {
                id: settingsContent
                anchors.fill: parent
            }

            RaohaneSettingsSearch {
                id: settingsSearch
                visible: !settingsContent.pageOwnsHeader
                z: 50
                width: Math.min(300, Math.max(220, workspace.width * 0.27))
                height: 34
                anchors {
                    top: parent.top
                    right: parent.right
                    topMargin: 19
                    rightMargin: 204
                }
            }

            RaohaneIconButton {
                visible: !settingsContent.pageOwnsHeader
                z: 50
                anchors {
                    top: parent.top
                    right: parent.right
                    topMargin: 20
                    rightMargin: 164
                }
                buttonSize: 30
                iconSize: 15
                icon: "inventory_2"
                transparentIdle: true
                showSheen: false
                onClicked: RaohaneSettingsRouter.request("backup", "")
            }

            RaohaneIconButton {
                visible: !settingsContent.pageOwnsHeader
                z: 50
                anchors {
                    top: parent.top
                    right: parent.right
                    topMargin: 20
                    rightMargin: 127
                }
                buttonSize: 30
                iconSize: 15
                icon: "keyboard"
                transparentIdle: true
                showSheen: false
                onClicked: RaohaneSettingsRouter.request("keybinds", "")
            }

            RaohaneIconButton {
                visible: !settingsContent.pageOwnsHeader
                z: 50
                anchors {
                    top: parent.top
                    right: parent.right
                    topMargin: 20
                    rightMargin: 90
                }
                buttonSize: 30
                iconSize: 15
                icon: "animation"
                transparentIdle: true
                showSheen: false
                onClicked: RaohaneSettingsRouter.request("motion", "")
            }

            RaohaneIconButton {
                visible: !settingsContent.pageOwnsHeader
                z: 50
                anchors {
                    top: parent.top
                    right: parent.right
                    topMargin: 20
                    rightMargin: 53
                }
                buttonSize: 30
                iconSize: 15
                icon: "language"
                transparentIdle: true
                showSheen: false
                onClicked: RaohaneSettingsRouter.request("language", "")
            }

            RaohaneIconButton {
                z: 50
                anchors {
                    top: parent.top
                    right: parent.right
                    topMargin: 20
                    rightMargin: 16
                }
                buttonSize: 30
                iconSize: 15
                icon: "close"
                transparentIdle: true
                showSheen: false
                onClicked: panelWindow.hide()
            }

            Keys.onPressed: event => {
                if (settingsSearch.visible && (event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_F) {
                    settingsSearch.focusSearch()
                    event.accepted = true
                } else if (event.key === Qt.Key_Escape) {
                    if (settingsSearch.visible && settingsSearch.query.length > 0) {
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
            function page(page: string): void { RaohaneSettingsRouter.request(page, "") }
        }

        CompositorGlobalShortcut {
            name: "settingsToggle"
            description: "Toggles Raohane settings"
            onPressed: RaohaneState.togglePrimary("settings")
        }
    }
}
