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
    property int panelWidth: 436
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
                quickControls.refreshGameMode()
            }
        }
    }

    PanelWindow {
        id: panelWindow

        visible: RaohaneState.controlCenterOpen
        screen: root.focusedScreen
        exclusiveZone: 0
        implicitWidth: root.panelWidth + 28
        color: "transparent"
        WlrLayershell.namespace: "quickshell:raohane-control-center"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: RaohaneState.controlCenterOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        anchors {
            top: true
            right: true
            bottom: true
        }
        margins {
            top: 14
            right: 14
            bottom: 14
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
            anchors {
                top: parent.top
                right: parent.right
                bottom: parent.bottom
            }
            surfaceRadius: RaohaneTheme.radiusHero
            raised: true
            showSheen: false
            border.color: RaohaneTheme.borderStrong
            clip: true
            opacity: entered ? 1 : 0
            scale: entered ? 1 : 0.988

            transform: Translate {
                x: panelSurface.entered ? 0 : 22
                Behavior on x {
                    NumberAnimation { duration: RaohaneMotion.enter; easing.type: RaohaneMotion.easeEmphasized }
                }
            }

            Behavior on opacity {
                NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeStandard }
            }
            Behavior on scale {
                NumberAnimation { duration: RaohaneMotion.enter; easing.type: RaohaneMotion.easeEmphasized }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: 18
                anchors.rightMargin: 18
                anchors.topMargin: 16
                anchors.bottomMargin: 12
                spacing: 0

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 70

                    RowLayout {
                        anchors.fill: parent
                        spacing: 11

                        RaohaneSurface {
                            Layout.preferredWidth: 46
                            Layout.preferredHeight: 46
                            surfaceRadius: 15
                            active: true
                            showSheen: false
                            clip: true

                            Image {
                                id: avatar
                                anchors.fill: parent
                                source: RaohaneConfig.profileAvatarPath !== ""
                                    ? "file://" + RaohaneConfig.profileAvatarPath
                                    : RaohanePaths.defaultAvatarUrl
                                fillMode: Image.PreserveAspectCrop
                                visible: status === Image.Ready
                                asynchronous: true
                            }

                            RaohaneIcon {
                                anchors.centerIn: parent
                                visible: !avatar.visible
                                text: "account_circle"
                                iconSize: 25
                                fill: 1
                                symbolWeight: 520
                                color: RaohaneTheme.accent
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                Layout.fillWidth: true
                                text: qsTr("Control Center")
                                color: RaohaneTheme.text
                                font.pixelSize: 17
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: (RaohaneConfig.profileDisplayName !== ""
                                    ? RaohaneConfig.profileDisplayName
                                    : RaohaneSystemInfo.username)
                                    + "  ·  " + RaohaneSystemInfo.hostname
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 8
                                elide: Text.ElideRight
                            }
                        }

                        ColumnLayout {
                            spacing: -2

                            Text {
                                Layout.alignment: Qt.AlignRight
                                text: Qt.formatTime(root.now, "HH:mm")
                                color: RaohaneTheme.text
                                font.pixelSize: 17
                                font.weight: Font.Medium
                            }

                            Text {
                                Layout.alignment: Qt.AlignRight
                                text: Qt.formatDate(root.now, "ddd, d MMM")
                                color: RaohaneTheme.textFaint
                                font.pixelSize: 7
                            }
                        }

                        ActionButton {
                            icon: "settings"
                            onClicked: RaohaneState.setPrimaryOpen("settings", true)
                        }

                        ActionButton {
                            icon: "power_settings_new"
                            emphasized: true
                            onClicked: RaohaneState.setPrimaryOpen("session", true)
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: RaohaneTheme.borderFaint
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    Layout.topMargin: 4
                    spacing: 8

                    Text {
                        text: qsTr("QUICK CONTROL")
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 7
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.9
                    }

                    Item { Layout.fillWidth: true }

                    StatusPill {
                        icon: RaohaneNetwork.materialSymbol
                        text: RaohaneNetwork.networkName.length > 0
                            ? RaohaneNetwork.networkName
                            : (RaohaneNetwork.ethernet ? qsTr("Ethernet") : qsTr("Offline"))
                        active: RaohaneNetwork.wifiConnected || RaohaneNetwork.ethernet
                    }
                }

                RaohaneQuickControls {
                    id: quickControls
                    Layout.fillWidth: true
                    Layout.preferredHeight: implicitHeight
                    screen: panelWindow.screen
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    Layout.topMargin: 12
                    Layout.bottomMargin: 12
                    color: RaohaneTheme.borderFaint
                }

                RaohaneNotificationCenter {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 170
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    Layout.topMargin: 10
                    color: RaohaneTheme.borderFaint
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    spacing: 8

                    Rectangle {
                        width: 7
                        height: 7
                        radius: 4
                        color: RaohanePrivacy.recordingActive || RaohanePrivacy.cameraActive || RaohanePrivacy.microphoneActive
                            ? RaohaneTheme.critical
                            : RaohaneTheme.success
                        scale: RaohanePrivacy.recordingActive || RaohanePrivacy.cameraActive || RaohanePrivacy.microphoneActive ? 1.15 : 1

                        Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
                        Behavior on scale {
                            NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeEmphasized }
                        }
                    }

                    Text {
                        text: RaohanePrivacy.recordingActive || RaohanePrivacy.cameraActive || RaohanePrivacy.microphoneActive
                            ? qsTr("Privacy activity")
                            : qsTr("System ready")
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 8
                        font.weight: Font.Medium
                    }

                    Text {
                        text: "·"
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 8
                    }

                    Text {
                        Layout.fillWidth: true
                        text: RaohaneSystemInfo.distroName
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 8
                        elide: Text.ElideRight
                    }

                    ActionButton {
                        icon: "restart_alt"
                        onClicked: {
                            Quickshell.execDetached(["hyprctl", "reload"])
                            Quickshell.reload(true)
                        }
                    }

                    ActionButton {
                        icon: "close"
                        onClicked: panelWindow.hide()
                    }
                }
            }
        }

        IpcHandler {
            target: "sidebarRight"
            function toggle(): void { RaohaneState.togglePrimary("controlCenter") }
            function open(): void { RaohaneState.setPrimaryOpen("controlCenter", true) }
            function close(): void { RaohaneState.setPrimaryOpen("controlCenter", false) }
        }

        CompositorGlobalShortcut {
            name: "sidebarRightToggle"
            description: "Toggles Raohane control center"
            onPressed: RaohaneState.togglePrimary("controlCenter")
        }
    }

    component ActionButton: RaohaneIconButton {
        Layout.preferredWidth: 31
        Layout.preferredHeight: 31
        buttonSize: 31
        iconSize: 16
        transparentIdle: !emphasized
        showSheen: false
    }

    component StatusPill: RaohaneSurface {
        id: pill
        required property string icon
        required property string text

        implicitWidth: pillRow.implicitWidth + 16
        implicitHeight: 24
        surfaceRadius: 10
        transparentIdle: !pill.active
        showSheen: false

        Row {
            id: pillRow
            anchors.centerIn: parent
            spacing: 5

            RaohaneIcon {
                text: pill.icon
                iconSize: 13
                fill: pill.active ? 1 : 0
                color: pill.active ? RaohaneTheme.accent : RaohaneTheme.textMuted
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: pill.text
                color: pill.active ? RaohaneTheme.text : RaohaneTheme.textMuted
                font.pixelSize: 7
                font.weight: Font.Medium
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
