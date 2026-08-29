pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.modules.raohane.config
import qs.modules.raohane.services

Scope {
    id: root

    property date now: new Date()

    Timer {
        interval: 1000
        repeat: true
        running: RaohaneConfig.barVertical && RaohaneState.barOpen && !RaohaneState.screenLocked
        onTriggered: root.now = new Date()
    }

    Connections {
        target: RaohaneState
        function onBarOpenChanged(): void {
            if (RaohaneState.barOpen)
                root.now = new Date()
        }
    }

    Variants {
        model: {
            const screens = Quickshell.screens
            const configured = RaohaneConfig.barScreenList
            if (!configured || configured.length === 0)
                return screens
            return screens.filter(screen => configured.includes(screen.name))
        }

        PanelWindow {
            id: barWindow
            required property ShellScreen modelData

            screen: modelData
            visible: RaohaneState.barOpen && !RaohaneState.screenLocked
            implicitWidth: 72
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore

            property bool superShow: false
            readonly property bool autoHide: RaohaneConfig.barAutoHide
            readonly property bool mustShow: !autoHide || hoverRegion.containsMouse || superShow
            readonly property var hyprMonitor: Hyprland.monitorFor(barWindow.screen)
            readonly property bool monitorHasFullscreen: hyprMonitor?.activeWorkspace?.hasFullscreen ?? false
            readonly property bool monitorHasSpecialOpen: (hyprMonitor?.lastIpcObject?.specialWorkspace?.name ?? "") !== ""

            exclusiveZone: (autoHide && (!mustShow || !RaohaneConfig.barAutoHidePushWindows))
                ? 0
                : implicitWidth

            anchors {
                top: true
                bottom: true
                left: true
            }

            WlrLayershell.namespace: "quickshell:raohane-vertical-bar"
            WlrLayershell.layer: (monitorHasFullscreen && monitorHasSpecialOpen)
                ? WlrLayer.Overlay
                : WlrLayer.Top
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            Timer {
                id: superRevealTimer
                interval: RaohaneConfig.barShowOnSuperDelay
                repeat: false
                onTriggered: barWindow.superShow = true
            }

            Connections {
                target: RaohaneState

                function onSuperDownChanged(): void {
                    if (!RaohaneConfig.barShowOnSuper)
                        return
                    if (RaohaneState.superDown) {
                        superRevealTimer.restart()
                    } else {
                        superRevealTimer.stop()
                        barWindow.superShow = false
                    }
                }
            }

            MouseArea {
                id: hoverRegion
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
            }

            Item {
                id: barContent
                width: 62
                height: parent.height
                x: barWindow.mustShow ? 5 : -width - 2

                Behavior on x {
                    NumberAnimation {
                        duration: RaohaneTheme.animationDuration
                        easing.type: Easing.OutCubic
                    }
                }

                Rectangle {
                    anchors {
                        fill: parent
                        topMargin: 7
                        bottomMargin: 7
                    }
                    radius: 24
                    color: RaohaneTheme.glass
                    border.width: 1
                    border.color: RaohaneTheme.border

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 7
                        spacing: 6

                        IconButton {
                            icon: "apps"
                            emphasized: true
                            tooltip: qsTr("Launcher")
                            onTriggered: {
                                RaohaneState.overviewOpen = false
                                RaohaneState.launcherOpen = !RaohaneState.launcherOpen
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: RaohaneTheme.border
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            Repeater {
                                model: Math.max(2, Math.min(10, RaohaneConfig.overviewWorkspaceCount))

                                delegate: Rectangle {
                                    id: workspaceButton
                                    required property int index

                                    readonly property int workspaceId: index + 1
                                    readonly property var monitor: Hyprland.monitorFor(barWindow.screen)
                                    readonly property bool active: (monitor?.activeWorkspace?.id ?? 1) === workspaceId
                                    readonly property var workspace: Hyprland.workspaces.values.find(candidate => candidate.id === workspaceId) ?? null
                                    readonly property bool occupied: (workspace?.toplevels?.values?.length ?? 0) > 0

                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.preferredWidth: 36
                                    Layout.preferredHeight: 29
                                    radius: 11
                                    color: active ? RaohaneTheme.accentSoft
                                        : workspaceMouse.containsMouse ? "#24ffffff" : "transparent"
                                    border.width: active ? 1 : 0
                                    border.color: active ? RaohaneTheme.accent : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: workspaceButton.workspaceId
                                        color: workspaceButton.active ? RaohaneTheme.accent : RaohaneTheme.textMuted
                                        font.pixelSize: 9
                                        font.weight: workspaceButton.active ? Font.Bold : Font.Medium
                                    }

                                    Rectangle {
                                        visible: workspaceButton.occupied
                                        width: 3
                                        height: 7
                                        radius: 2
                                        anchors {
                                            right: parent.right
                                            rightMargin: 2
                                            verticalCenter: parent.verticalCenter
                                        }
                                        color: workspaceButton.active ? RaohaneTheme.accent : RaohaneTheme.textMuted
                                    }

                                    MouseArea {
                                        id: workspaceMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (Hyprland.usingLua)
                                                Hyprland.dispatch(`hl.dsp.focus({ workspace = "${workspaceButton.workspaceId}" })`)
                                            else
                                                Hyprland.dispatch("workspace " + workspaceButton.workspaceId)
                                        }
                                    }
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }

                        StatusDot {
                            icon: RaohaneNetwork.enabled ? (RaohaneNetwork.ssid.length > 0 ? "wifi" : "lan") : "wifi_off"
                            active: RaohaneNetwork.enabled
                            tooltip: RaohaneNetwork.ssid.length > 0 ? RaohaneNetwork.ssid : qsTr("Network")
                            onTriggered: RaohaneState.controlCenterOpen = !RaohaneState.controlCenterOpen
                        }

                        StatusDot {
                            icon: RaohaneBluetooth.powered ? "bluetooth" : "bluetooth_disabled"
                            active: RaohaneBluetooth.powered
                            tooltip: RaohaneBluetooth.powered ? qsTr("Bluetooth") : qsTr("Bluetooth off")
                            onTriggered: RaohaneState.controlCenterOpen = !RaohaneState.controlCenterOpen
                        }

                        StatusDot {
                            icon: RaohaneNotifications.doNotDisturb ? "notifications_off" : "notifications"
                            active: !RaohaneNotifications.doNotDisturb
                            tooltip: RaohaneNotifications.doNotDisturb ? qsTr("Do Not Disturb") : qsTr("Notifications")
                            badge: RaohaneNotifications.unreadCount
                            onTriggered: RaohaneNotifications.toggleDoNotDisturb()
                        }

                        StatusDot {
                            visible: RaohanePrivacy.anyCapture
                            icon: RaohanePrivacy.cameraActive ? "videocam" : RaohanePrivacy.microphoneActive ? "mic" : "screen_record"
                            active: true
                            warning: true
                            tooltip: qsTr("Privacy capture active")
                            onTriggered: RaohaneState.controlCenterOpen = true
                        }

                        StatusDot {
                            visible: RaohaneMedia.available
                            icon: RaohaneMedia.playing ? "music_note" : "pause"
                            active: RaohaneMedia.playing
                            tooltip: RaohaneMedia.title.length > 0 ? RaohaneMedia.title : qsTr("Media")
                            onTriggered: RaohaneState.mediaOverlayOpen = !RaohaneState.mediaOverlayOpen
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: RaohaneTheme.border
                        }

                        IconButton {
                            icon: RaohaneAudio.muted ? "volume_off" : RaohaneAudio.volume >= 0.55 ? "volume_up" : "volume_down"
                            tooltip: RaohaneAudio.muted
                                ? qsTr("Muted")
                                : qsTr("Volume %1%").arg(Math.round(RaohaneAudio.volume * 100))
                            onTriggered: RaohaneAudio.toggleMute()
                        }

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 44
                            Layout.preferredHeight: 54
                            radius: 15
                            color: clockMouse.containsMouse ? RaohaneTheme.accentSoft : "#18ffffff"
                            border.width: 1
                            border.color: RaohaneTheme.border

                            Column {
                                anchors.centerIn: parent
                                spacing: -2

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: Qt.formatTime(root.now, "HH")
                                    color: RaohaneTheme.text
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: Qt.formatTime(root.now, "mm")
                                    color: RaohaneTheme.accent
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                }
                            }

                            MouseArea {
                                id: clockMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: RaohaneState.controlCenterOpen = !RaohaneState.controlCenterOpen
                            }
                        }

                        IconButton {
                            icon: "tune"
                            tooltip: qsTr("Control Center")
                            onTriggered: RaohaneState.controlCenterOpen = !RaohaneState.controlCenterOpen
                        }

                        IconButton {
                            icon: "power_settings_new"
                            tooltip: qsTr("Session")
                            onTriggered: RaohaneState.sessionOpen = !RaohaneState.sessionOpen
                        }
                    }
                }
            }
        }
    }

    component StatusDot: Rectangle {
        id: status

        required property string icon
        property bool active: false
        property bool warning: false
        property int badge: 0
        property string tooltip: ""
        signal triggered()

        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: 38
        Layout.preferredHeight: 34
        radius: 12
        color: statusMouse.containsMouse ? RaohaneTheme.accentSoft : "transparent"

        RaohaneIcon {
            anchors.centerIn: parent
            text: status.icon
            iconSize: 17
            color: status.warning ? "#ff746e"
                : status.active ? RaohaneTheme.accent : RaohaneTheme.textMuted
        }

        Rectangle {
            visible: status.badge > 0
            width: 14
            height: 14
            radius: 7
            anchors {
                right: parent.right
                top: parent.top
                rightMargin: 1
                topMargin: 1
            }
            color: RaohaneTheme.accent

            Text {
                anchors.centerIn: parent
                text: status.badge > 9 ? "9+" : String(status.badge)
                color: "#100a14"
                font.pixelSize: 7
                font.weight: Font.Bold
            }
        }

        MouseArea {
            id: statusMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: status.triggered()
        }
    }

    component IconButton: Rectangle {
        id: button

        required property string icon
        property bool emphasized: false
        property string tooltip: ""
        signal triggered()

        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: 38
        Layout.preferredHeight: 36
        radius: 12
        color: buttonMouse.containsMouse || button.emphasized ? RaohaneTheme.accentSoft : "transparent"
        border.width: button.emphasized ? 1 : 0
        border.color: button.emphasized ? RaohaneTheme.accent : "transparent"

        RaohaneIcon {
            anchors.centerIn: parent
            text: button.icon
            iconSize: 17
            color: button.emphasized ? RaohaneTheme.accent : RaohaneTheme.text
        }

        MouseArea {
            id: buttonMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.triggered()
        }
    }
}
