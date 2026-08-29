pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
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
            implicitWidth: 72
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore

            property bool superShow: false
            readonly property bool autoHide: RaohaneConfig.barAutoHide
            readonly property bool mustShow: !autoHide || hoverRegion.containsMouse || superShow
            readonly property var hyprMonitor: Hyprland.monitorFor(barWindow.screen)
            readonly property bool monitorHasFullscreen: hyprMonitor?.activeWorkspace?.hasFullscreen ?? false
            readonly property bool monitorHasSpecialOpen: (hyprMonitor?.lastIpcObject?.specialWorkspace?.name ?? "") !== ""
            readonly property bool effectiveFullscreen: monitorHasFullscreen && !monitorHasSpecialOpen
            readonly property bool fullscreenSuppressed: effectiveFullscreen && !superShow

            visible: RaohaneState.barOpen && !RaohaneState.screenLocked && !fullscreenSuppressed
            exclusiveZone: fullscreenSuppressed
                ? 0
                : (autoHide && (!mustShow || !RaohaneConfig.barAutoHidePushWindows))
                    ? 0
                    : implicitWidth

            anchors {
                top: true
                bottom: true
                left: true
            }

            WlrLayershell.namespace: "quickshell:raohane-vertical-bar"
            WlrLayershell.layer: (monitorHasFullscreen && (monitorHasSpecialOpen || superShow))
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
                                            rightMargin: 4
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
                                            if (workspaceButton.workspace)
                                                workspaceButton.workspace.activate()
                                            else if (Hyprland.usingLua)
                                                Hyprland.dispatch(`hl.dsp.focus({ workspace = "${workspaceButton.workspaceId}" })`)
                                            else
                                                Hyprland.dispatch("workspace " + workspaceButton.workspaceId)
                                        }
                                    }
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }

                        IconButton {
                            icon: RaohanePrivacy.recordingActive ? "screen_record"
                                : RaohanePrivacy.cameraActive ? "videocam"
                                : RaohanePrivacy.microphoneActive ? "mic"
                                : (RaohaneContext.mode === "media" ? "music_note" : "spark")
                            emphasized: RaohanePrivacy.recordingActive || RaohanePrivacy.cameraActive || RaohanePrivacy.microphoneActive || RaohaneContext.mode === "media"
                            tooltip: RaohaneContext.title
                            onTriggered: {
                                if (RaohaneContext.mode === "media")
                                    RaohaneState.mediaOverlayOpen = !RaohaneState.mediaOverlayOpen
                                else
                                    RaohaneState.controlCenterOpen = !RaohaneState.controlCenterOpen
                            }
                        }

                        IconButton {
                            icon: RaohaneNetwork.materialSymbol
                            emphasized: RaohaneNetwork.wifiConnected || RaohaneNetwork.ethernet
                            tooltip: RaohaneNetwork.networkName.length > 0 ? RaohaneNetwork.networkName : qsTr("Network")
                            onTriggered: RaohaneState.controlCenterOpen = !RaohaneState.controlCenterOpen
                        }

                        IconButton {
                            visible: RaohaneBluetooth.available
                            icon: RaohaneBluetooth.connected ? "bluetooth_connected" : (RaohaneBluetooth.enabled ? "bluetooth" : "bluetooth_disabled")
                            emphasized: RaohaneBluetooth.connected
                            tooltip: RaohaneBluetooth.connected ? RaohaneBluetooth.firstConnectedName : qsTr("Bluetooth")
                            onTriggered: RaohaneBluetooth.toggle()
                        }

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 36
                            radius: 13
                            color: notificationMouse.containsMouse ? "#24ffffff" : "transparent"

                            RaohaneIcon {
                                anchors.centerIn: parent
                                text: RaohaneNotifications.silent ? "notifications_off" : "notifications"
                                iconSize: 17
                                color: RaohaneNotifications.unread > 0 ? RaohaneTheme.accent : RaohaneTheme.text
                            }

                            Rectangle {
                                visible: RaohaneNotifications.unread > 0
                                anchors {
                                    right: parent.right
                                    top: parent.top
                                    rightMargin: 1
                                    topMargin: 1
                                }
                                width: 15
                                height: 15
                                radius: 8
                                color: RaohaneTheme.accent

                                Text {
                                    anchors.centerIn: parent
                                    text: Math.min(9, RaohaneNotifications.unread) + (RaohaneNotifications.unread > 9 ? "+" : "")
                                    color: "#120d18"
                                    font.pixelSize: 7
                                    font.weight: Font.Bold
                                }
                            }

                            MouseArea {
                                id: notificationMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: RaohaneState.controlCenterOpen = !RaohaneState.controlCenterOpen
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: RaohaneTheme.border
                        }

                        ColumnLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: -2

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: Qt.formatTime(root.now, "HH")
                                color: RaohaneTheme.text
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: Qt.formatTime(root.now, "mm")
                                color: RaohaneTheme.text
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }
                            Text {
                                visible: RaohaneConfig.barShowDate
                                Layout.alignment: Qt.AlignHCenter
                                text: Qt.formatDate(root.now, "dd")
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 8
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: RaohaneTheme.border
                        }

                        IconButton {
                            icon: RaohaneAudio.muted ? "volume_off" : (RaohaneAudio.volume > 0.66 ? "volume_up" : RaohaneAudio.volume > 0.05 ? "volume_down" : "volume_mute")
                            emphasized: !RaohaneAudio.muted && RaohaneAudio.volume > 0
                            tooltip: RaohaneAudio.muted ? qsTr("Muted") : qsTr("Volume %1%").arg(Math.round(RaohaneAudio.volume * 100))
                            onTriggered: RaohaneAudio.toggleMute()
                        }

                        IconButton {
                            icon: "tune"
                            tooltip: qsTr("Control Center")
                            onTriggered: RaohaneState.controlCenterOpen = !RaohaneState.controlCenterOpen
                        }

                        IconButton {
                            icon: "power_settings_new"
                            tooltip: qsTr("Session")
                            onTriggered: RaohaneState.sessionOpen = true
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "bar"
        function toggle(): void { RaohaneState.barOpen = !RaohaneState.barOpen }
        function open(): void { RaohaneState.barOpen = true }
        function close(): void { RaohaneState.barOpen = false }
        function mode(): string { return "vertical" }
    }

    CompositorGlobalShortcut {
        name: "barToggle"
        description: "Toggles the Raohane bar"
        onPressed: RaohaneState.barOpen = !RaohaneState.barOpen
    }

    component IconButton: Rectangle {
        id: button
        required property string icon
        property string tooltip: ""
        property bool emphasized: false
        signal triggered()

        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: 36
        Layout.preferredHeight: 36
        radius: 13
        color: emphasized ? RaohaneTheme.accentSoft
            : buttonMouse.containsMouse ? "#24ffffff" : "transparent"
        border.width: emphasized ? 1 : 0
        border.color: emphasized ? RaohaneTheme.accent : "transparent"

        RaohaneIcon {
            anchors.centerIn: parent
            text: button.icon
            iconSize: 17
            color: emphasized ? RaohaneTheme.accent : RaohaneTheme.text
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