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
                color: RaohaneTheme.accentSoft
                opacity: panelSurface.entered ? 0.32 : 0

                Behavior on opacity {
                    NumberAnimation { duration: RaohaneMotion.relaxed * 2; easing.type: RaohaneMotion.easeStandard }
                }

                SequentialAnimation on scale {
                    running: panelWindow.visible
                    loops: Animation.Infinite
                    NumberAnimation { from: 0.96; to: 1.04; duration: 3200; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 1.04; to: 0.96; duration: 3200; easing.type: Easing.InOutSine }
                }
            }

            Rectangle {
                z: 20
                anchors {
                    left: parent.left
                    top: parent.top
                    leftMargin: 16
                }
                width: 48
                height: 2
                radius: 1
                color: RaohaneTheme.accent
                opacity: 0.72
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                anchors.topMargin: 13
                anchors.bottomMargin: 10
                spacing: 0

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 66

                    RowLayout {
                        anchors.fill: parent
                        spacing: 9

                        RaohaneSurface {
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            surfaceRadius: 13
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
                                iconSize: 22
                                fill: 1
                                symbolWeight: 520
                                color: RaohaneTheme.accent
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                Layout.fillWidth: true
                                text: RaohaneConfig.profileDisplayName !== ""
                                    ? RaohaneConfig.profileDisplayName
                                    : RaohaneSystemInfo.username
                                color: RaohaneTheme.text
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: RaohaneSystemInfo.hostname + "  ·  " + (RaohaneSystemInfo.distroName || qsTr("Hyprland"))
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 7
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
                    Layout.preferredHeight: 34
                    spacing: 7

                    Text {
                        text: qsTr("CONTROLS")
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
                    Layout.topMargin: 9
                    Layout.bottomMargin: 8
                    color: RaohaneTheme.borderFaint
                }

                RaohaneNotificationCenter {
                    visible: !quickControls.pickerOpen
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: quickControls.pickerOpen ? 0 : 150
                }

                Rectangle {
                    visible: !quickControls.pickerOpen
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    Layout.topMargin: 8
                    color: RaohaneTheme.borderFaint
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    spacing: 7

                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        color: RaohanePrivacy.recordingActive || RaohanePrivacy.cameraActive || RaohanePrivacy.microphoneActive
                            ? RaohaneTheme.critical
                            : RaohaneTheme.success
                        scale: RaohanePrivacy.recordingActive || RaohanePrivacy.cameraActive || RaohanePrivacy.microphoneActive ? 1.14 : 1

                        Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
                        Behavior on scale {
                            NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeEmphasized }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: RaohanePrivacy.recordingActive || RaohanePrivacy.cameraActive || RaohanePrivacy.microphoneActive
                            ? qsTr("Privacy activity")
                            : qsTr("System ready")
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 8
                        font.weight: Font.Medium
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
        Layout.preferredWidth: 29
        Layout.preferredHeight: 29
        buttonSize: 29
        iconSize: 14
        transparentIdle: !emphasized
        showSheen: false
    }

    component StatusPill: RaohaneSurface {
        id: pill
        required property string icon
        required property string text

        implicitWidth: pillRow.implicitWidth + 14
        implicitHeight: 22
        surfaceRadius: 10
        transparentIdle: !pill.active
        showSheen: false

        Row {
            id: pillRow
            anchors.centerIn: parent
            spacing: 5

            RaohaneIcon {
                text: pill.icon
                iconSize: 12
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
