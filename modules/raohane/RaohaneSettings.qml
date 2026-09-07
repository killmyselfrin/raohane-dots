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

        property bool presented: false

        visible: presented
        screen: root.focusedScreen
        exclusiveZone: 0
        color: "transparent"
        WlrLayershell.namespace: "quickshell:raohane-settings"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: RaohaneState.settingsOpen
            ? WlrKeyboardFocus.OnDemand
            : WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        function present(): void {
            closeTimer.stop()
            panelWindow.presented = true
            workspace.entered = false
            Qt.callLater(() => workspace.entered = true)
        }

        function dismissVisual(): void {
            workspace.entered = false
            closeTimer.restart()
        }

        function hide(): void {
            settingsSearch.clear()
            if (RaohaneState.settingsOpen)
                RaohaneState.setPrimaryOpen("settings", false)
            else
                panelWindow.dismissVisual()
        }

        function toggle(): void {
            if (RaohaneState.settingsOpen)
                panelWindow.hide()
            else
                RaohaneState.setPrimaryOpen("settings", true)
        }

        Component.onCompleted: {
            if (RaohaneState.settingsOpen)
                panelWindow.present()
        }

        Connections {
            target: RaohaneState

            function onSettingsOpenChanged(): void {
                if (RaohaneState.settingsOpen)
                    panelWindow.present()
                else if (panelWindow.presented)
                    panelWindow.dismissVisual()
            }
        }

        Timer {
            id: closeTimer
            interval: Math.max(1, RaohaneMotion.standard)
            repeat: false
            onTriggered: panelWindow.presented = false
        }

        onVisibleChanged: {
            if (visible)
                RaohaneFocusGrab.addDismissable(panelWindow)
            else
                RaohaneFocusGrab.removeDismissable(panelWindow)
        }

        Connections {
            target: RaohaneFocusGrab
            function onDismissed(): void { panelWindow.hide() }
        }

        Rectangle {
            anchors.fill: parent
            color: RaohaneTheme.dark
                ? Qt.rgba(0.01, 0.015, 0.035, 0.54)
                : Qt.rgba(0.18, 0.17, 0.15, 0.20)
            opacity: workspace.entered ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: RaohaneMotion.standard
                    easing.type: workspace.entered ? RaohaneMotion.easeStandard : RaohaneMotion.easeExit
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: panelWindow.hide()
            }
        }

        RaohaneSurface {
            id: workspace
            property bool entered: false

            width: Math.min(parent.width - 72, 1080)
            height: Math.min(parent.height - 76, 720)
            anchors.centerIn: parent
            surfaceRadius: RaohaneTheme.radiusHero
            raised: true
            showSheen: true
            border.color: RaohaneTheme.borderStrong
            clip: true
            opacity: entered ? 1 : 0
            scale: entered ? 1 : 0.985
            focus: RaohaneState.settingsOpen

            transform: Translate {
                y: workspace.entered || !RaohaneMotion.transformMotionEnabled ? 0 : 10
                Behavior on y {
                    NumberAnimation {
                        duration: RaohaneMotion.relaxed
                        easing.type: workspace.entered ? RaohaneMotion.easeEmphasized : RaohaneMotion.easeExit
                    }
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: RaohaneMotion.standard
                    easing.type: workspace.entered ? RaohaneMotion.easeStandard : RaohaneMotion.easeExit
                }
            }

            Behavior on scale {
                enabled: RaohaneMotion.transformMotionEnabled
                NumberAnimation {
                    duration: workspace.entered ? RaohaneMotion.relaxed : RaohaneMotion.standard
                    easing.type: workspace.entered ? RaohaneMotion.easeEmphasized : RaohaneMotion.easeExit
                }
            }

            Rectangle {
                z: 40
                anchors {
                    left: parent.left
                    top: parent.top
                    leftMargin: 15
                }
                width: workspace.entered ? 40 : 12
                height: 2
                radius: 1
                color: RaohaneTheme.accent
                opacity: workspace.entered ? 0.72 : 0

                Behavior on width {
                    NumberAnimation {
                        duration: RaohaneMotion.relaxed
                        easing.type: RaohaneMotion.easeEmphasized
                    }
                }

                Behavior on opacity {
                    NumberAnimation { duration: RaohaneMotion.standard }
                }
            }

            RaohaneSettingsContentV3 {
                id: settingsContent
                anchors.fill: parent
            }

            RaohaneSettingsSearch {
                id: settingsSearch
                visible: !settingsContent.pageOwnsHeader
                z: 50
                width: Math.min(278, Math.max(220, workspace.width * 0.265))
                height: 32
                anchors {
                    top: parent.top
                    right: parent.right
                    topMargin: 18
                    rightMargin: 164
                }
                opacity: workspace.entered ? 1 : 0

                transform: Translate {
                    y: workspace.entered || !RaohaneMotion.transformMotionEnabled ? 0 : -5
                    Behavior on y {
                        NumberAnimation {
                            duration: RaohaneMotion.standard
                            easing.type: RaohaneMotion.easeEmphasized
                        }
                    }
                }

                Behavior on opacity {
                    NumberAnimation { duration: RaohaneMotion.standard }
                }
            }

            RaohaneSurface {
                id: commandStrip
                visible: !settingsContent.pageOwnsHeader
                z: 50
                width: 108
                height: 32
                anchors {
                    top: parent.top
                    right: parent.right
                    topMargin: 18
                    rightMargin: 49
                }
                surfaceRadius: 10
                raised: false
                showSheen: false
                border.color: RaohaneTheme.borderFaint
                opacity: workspace.entered ? 1 : 0

                transform: Translate {
                    y: workspace.entered || !RaohaneMotion.transformMotionEnabled ? 0 : -5
                    Behavior on y {
                        NumberAnimation {
                            duration: RaohaneMotion.standard
                            easing.type: RaohaneMotion.easeEmphasized
                        }
                    }
                }

                Behavior on opacity {
                    NumberAnimation { duration: RaohaneMotion.standard }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 2

                    RaohaneIconButton {
                        buttonSize: 26
                        iconSize: 13
                        icon: "inventory_2"
                        transparentIdle: true
                        showSheen: false
                        onClicked: RaohaneSettingsRouter.request("backup", "")
                    }

                    RaohaneIconButton {
                        buttonSize: 26
                        iconSize: 13
                        icon: "keyboard"
                        transparentIdle: true
                        showSheen: false
                        onClicked: RaohaneSettingsRouter.request("keybinds", "")
                    }

                    RaohaneIconButton {
                        buttonSize: 26
                        iconSize: 13
                        icon: "animation"
                        transparentIdle: true
                        showSheen: false
                        onClicked: RaohaneSettingsRouter.request("motion", "")
                    }

                    RaohaneIconButton {
                        buttonSize: 26
                        iconSize: 13
                        icon: "language"
                        transparentIdle: true
                        showSheen: false
                        onClicked: RaohaneSettingsRouter.request("language", "")
                    }
                }
            }

            RaohaneIconButton {
                z: 50
                anchors {
                    top: parent.top
                    right: parent.right
                    topMargin: 19
                    rightMargin: 13
                }
                buttonSize: 28
                iconSize: 14
                icon: "close"
                transparentIdle: true
                showSheen: false
                opacity: workspace.entered ? 1 : 0
                onClicked: panelWindow.hide()

                Behavior on opacity {
                    NumberAnimation { duration: RaohaneMotion.standard }
                }
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
            function toggle(): void { panelWindow.toggle() }
            function open(): void { RaohaneState.setPrimaryOpen("settings", true) }
            function close(): void { panelWindow.hide() }
            function status(): string { return RaohaneState.settingsOpen ? "open" : "closed" }
            function page(page: string): void { RaohaneSettingsRouter.request(page, "") }
        }

        CompositorGlobalShortcut {
            name: "settingsToggle"
            description: "Toggles Raohane settings"
            onPressed: panelWindow.toggle()
        }
    }
}
