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
            workspace.preferencesOpen = false
            RaohaneState.setPrimaryOpen("settings", false)
        }

        function openPreferences(section: string): void {
            settingsSearch.clear()
            preferences.section = section
            workspace.preferencesOpen = true
            preferences.forceActiveFocus()
        }

        onVisibleChanged: {
            if (visible) {
                workspace.entered = false
                Qt.callLater(() => workspace.entered = true)
                RaohaneFocusGrab.addDismissable(panelWindow)
            } else {
                workspace.entered = false
                workspace.preferencesOpen = false
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
            property bool preferencesOpen: false

            width: Math.min(parent.width - 96, 1040)
            height: Math.min(parent.height - 96, 700)
            anchors.centerIn: parent
            surfaceRadius: RaohaneTheme.radiusHero
            raised: true
            showSheen: false
            border.color: RaohaneTheme.borderStrong
            clip: true
            opacity: entered ? 1 : 0
            scale: entered ? 1 : 0.994
            focus: RaohaneState.settingsOpen

            transform: Translate {
                y: workspace.entered ? 0 : 10
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
                anchors.fill: parent
                visible: !workspace.preferencesOpen
            }

            RaohaneHyprlandPreferences {
                id: preferences
                anchors.fill: parent
                visible: workspace.preferencesOpen
                z: 45
                onCloseRequested: {
                    workspace.preferencesOpen = false
                    workspace.forceActiveFocus()
                }
            }

            RaohaneSettingsSearch {
                id: settingsSearch
                visible: !workspace.preferencesOpen
                z: 50
                width: Math.min(300, Math.max(230, workspace.width * 0.28))
                height: 34
                anchors {
                    top: parent.top
                    right: parent.right
                    topMargin: 19
                    rightMargin: 130
                }
            }

            RaohaneIconButton {
                visible: !workspace.preferencesOpen
                z: 50
                anchors {
                    top: parent.top
                    right: parent.right
                    topMargin: 20
                    rightMargin: 90
                }
                buttonSize: 30
                iconSize: 15
                icon: "keyboard"
                transparentIdle: true
                showSheen: false
                onClicked: panelWindow.openPreferences("keybinds")
            }

            RaohaneIconButton {
                visible: !workspace.preferencesOpen
                z: 50
                anchors {
                    top: parent.top
                    right: parent.right
                    topMargin: 20
                    rightMargin: 53
                }
                buttonSize: 30
                iconSize: 15
                icon: "animation"
                transparentIdle: true
                showSheen: false
                onClicked: panelWindow.openPreferences("motion")
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
                if (workspace.preferencesOpen && event.key === Qt.Key_Escape) {
                    workspace.preferencesOpen = false
                    workspace.forceActiveFocus()
                    event.accepted = true
                } else if (!workspace.preferencesOpen && (event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_F) {
                    settingsSearch.focusSearch()
                    event.accepted = true
                } else if (!workspace.preferencesOpen && event.key === Qt.Key_Escape) {
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
                const requested = String(page ?? "").trim().toLowerCase()
                RaohaneState.setPrimaryOpen("settings", true)
                if (requested === "keybinds" || requested === "shortcuts" || requested === "keyboard") {
                    panelWindow.openPreferences("keybinds")
                    return
                }
                if (requested === "motion" || requested === "animations" || requested === "animation") {
                    panelWindow.openPreferences("motion")
                    return
                }
                workspace.preferencesOpen = false
                RaohaneState.settingsPage = page
            }
        }

        CompositorGlobalShortcut {
            name: "settingsToggle"
            description: "Toggles Raohane settings"
            onPressed: RaohaneState.togglePrimary("settings")
        }
    }
}