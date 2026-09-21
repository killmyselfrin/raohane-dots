import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.modules.raohane.config

Scope {
    id: root

    readonly property var focusedScreen: Quickshell.screens.find(screen => screen.name === Hyprland.focusedMonitor?.name)
        ?? Quickshell.screens[0]

    Component.onDestruction: RaohaneFocusGrab.removeDismissable(panelWindow)

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

        Component.onCompleted: {
            if (RaohaneState.settingsOpen)
                panelWindow.present()
        }

        Connections {
            target: RaohaneState

            function onSettingsOpenChanged(): void {
                if (RaohaneState.settingsOpen) {
                    panelWindow.present()
                } else if (panelWindow.presented) {
                    settingsSearch.clear()
                    panelWindow.dismissVisual()
                }
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
                ? Qt.rgba(0.01, 0.015, 0.035, 0.62)
                : Qt.rgba(0.18, 0.17, 0.15, 0.26)
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

            width: Math.min(parent.width - 64, 1340)
            height: Math.min(parent.height - 72, 860)
            anchors.centerIn: parent
            surfaceRadius: RaohaneTheme.radiusLarge
            raised: true
            showSheen: false
            showInnerRim: false
            idleColor: Qt.rgba(
                RaohaneTheme.backgroundElevated.r,
                RaohaneTheme.backgroundElevated.g,
                RaohaneTheme.backgroundElevated.b,
                1
            )
            border.color: RaohaneTheme.borderFaint
            clip: true
            opacity: entered ? 1 : 0
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

            RaohaneSettingsContentV3 {
                id: settingsContent
                anchors.fill: parent
            }

            RaohaneSettingsSearch {
                id: settingsSearch
                visible: !settingsContent.pageOwnsHeader
                z: 50
                width: Math.min(340, Math.max(260, workspace.width * 0.28))
                height: 34
                anchors {
                    top: parent.top
                    right: parent.right
                    topMargin: 15
                    rightMargin: 58
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

            RaohaneIconButton {
                z: 50
                anchors {
                    top: parent.top
                    right: parent.right
                    topMargin: 17
                    rightMargin: 18
                }
                buttonSize: 28
                iconSize: 13
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
    }
}
