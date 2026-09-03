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
    readonly property int panelWidth: Math.min(426, Math.max(376, Math.round((root.focusedScreen?.width ?? 1280) * 0.30)))
    readonly property int panelHeight: Math.min(700, Math.max(610, Math.round((root.focusedScreen?.height ?? 800) - 44)))
    property date now: new Date()

    Timer {
        interval: 1000
        repeat: true
        running: RaohaneState.controlCenterOpen
        onTriggered: root.now = new Date()
    }

    Connections {
        target: RaohaneState
        function onControlCenterOpenChanged(): void {
            if (RaohaneState.controlCenterOpen) {
                root.now = new Date()
                RaohaneEasyEffects.refresh()
                RaohanePerformance.refreshGameMode()
            }
        }
    }

    PanelWindow {
        id: panelWindow

        visible: RaohaneState.controlCenterOpen
        screen: root.focusedScreen
        exclusiveZone: 0
        implicitWidth: root.panelWidth + 28
        implicitHeight: root.panelHeight + 28
        color: "transparent"
        WlrLayershell.namespace: "quickshell:raohane-control-center"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: RaohaneState.controlCenterOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        anchors {
            top: true
            right: true
        }
        margins {
            top: 14
            right: 14
        }

        function hide(): void { RaohaneState.setPrimaryOpen("controlCenter", false) }

        onVisibleChanged: {
            if (visible) {
                panelSurface.entered = false
                Qt.callLater(() => panelSurface.entered = true)
                RaohaneNotifications.markAllRead()
                RaohaneFocusGrab.addDismissable(panelWindow)
            } else {
                panelSurface.entered = false
                RaohaneFocusGrab.removeDismissable(panelWindow)
            }
        }

        Connections {
            target: RaohaneFocusGrab
            function onDismissed() { panelWindow.hide() }
        }

        RaohaneSurface {
            id: panelSurface
            property bool entered: false

            width: root.panelWidth
            height: root.panelHeight
            anchors {
                top: parent.top
                right: parent.right
            }
            surfaceRadius: RaohaneTheme.radiusHero
            raised: true
            showSheen: false
            border.color: RaohaneTheme.borderStrong
            clip: true
            opacity: entered ? 1 : 0
            scale: entered ? 1 : 0.994

            transform: Translate {
                x: panelSurface.entered ? 0 : 14
                y: panelSurface.entered ? 0 : -6

                Behavior on x {
                    NumberAnimation { duration: RaohaneMotion.enter; easing.type: RaohaneMotion.easeEmphasized }
                }
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
                anchors {
                    top: parent.top
                    right: parent.right
                    topMargin: -76
                    rightMargin: -58
                }
                width: 190
                height: 190
                radius: 95
                color: RaohaneTheme.accentGlow
                opacity: 0.10
            }

            ColumnLayout {
                anchors {
                    fill: parent
                    margins: 16
                }
                spacing: 13

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    spacing: 10

                    RaohaneSurface {
                        Layout.preferredWidth: 42
                        Layout.preferredHeight: 42
                        surfaceRadius: 13
                        active: true
                        showSheen: false

                        RaohaneIcon {
                            anchors.centerIn: parent
                            text: "tune"
                            iconSize: 20
                            fill: 1
                            color: RaohaneTheme.accent
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            text: qsTr("Control Center")
                            color: RaohaneTheme.text
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: Qt.formatDateTime(root.now, "ddd, d MMM · HH:mm")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 8
                        }
                    }

                    RaohaneIconButton {
                        buttonSize: 32
                        iconSize: 16
                        icon: "settings"
                        transparentIdle: true
                        showSheen: false
                        onClicked: {
                            panelWindow.hide()
                            RaohaneState.setPrimaryOpen("settings", true)
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

                RaohaneQuickControls {
                    id: quickControls
                    Layout.fillWidth: true
                    screen: panelWindow.screen
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: RaohaneTheme.borderFaint
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Notifications")
                        color: RaohaneTheme.text
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }

                    Text {
                        visible: RaohaneNotifications.unread > 0
                        text: String(RaohaneNotifications.unread)
                        color: RaohaneTheme.accent
                        font.pixelSize: 8
                        font.weight: Font.Bold
                    }

                    RaohaneIconButton {
                        visible: RaohaneNotifications.items.length > 0
                        buttonSize: 28
                        iconSize: 14
                        icon: "clear_all"
                        transparentIdle: true
                        showSheen: false
                        onClicked: RaohaneNotifications.clearAll()
                    }
                }

                RaohaneNotificationCenter {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    panelWindow.hide()
                    event.accepted = true
                }
            }
        }
    }

    IpcHandler {
        target: "controlCenter"
        function toggle(): void { RaohaneState.togglePrimary("controlCenter") }
        function open(): void { RaohaneState.setPrimaryOpen("controlCenter", true) }
        function close(): void { RaohaneState.setPrimaryOpen("controlCenter", false) }
        function status(): string { return RaohaneState.controlCenterOpen ? "open" : "closed" }
    }

    CompositorGlobalShortcut {
        name: "sidebarRightToggle"
        description: "Toggles Raohane Control Center"
        onPressed: RaohaneState.togglePrimary("controlCenter")
    }
}
