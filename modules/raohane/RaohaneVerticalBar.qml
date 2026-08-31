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
                x: barWindow.mustShow ? 5 : -width - 3

                Behavior on x {
                    NumberAnimation {
                        duration: RaohaneMotion.standard
                        easing.type: RaohaneMotion.easeEmphasized
                    }
                }

                RaohaneSurface {
                    id: verticalSurface
                    anchors {
                        fill: parent
                        topMargin: 8
                        bottomMargin: 8
                    }
                    surfaceRadius: RaohaneTheme.radiusLarge
                    raised: true
                    showSheen: false
                    border.color: RaohaneTheme.borderStrong

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 7
                        spacing: 6

                        IconButton {
                            icon: "apps"
                            emphasized: RaohaneState.launcherOpen
                            tooltip: qsTr("Launcher")
                            onTriggered: RaohaneState.togglePrimary("launcher")
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: RaohaneTheme.borderFaint
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            Repeater {
                                model: Math.max(2, Math.min(10, RaohaneConfig.overviewWorkspaceCount))

                                delegate: RaohaneSurface {
                                    id: workspaceButton
                                    required property int index

                                    readonly property int workspaceId: index + 1
                                    readonly property var monitor: Hyprland.monitorFor(barWindow.screen)
                                    readonly property bool workspaceActive: (monitor?.activeWorkspace?.id ?? 1) === workspaceId
                                    readonly property var workspace: Hyprland.workspaces.values.find(candidate => candidate.id === workspaceId) ?? null
                                    readonly property bool occupied: (workspace?.toplevels?.values?.length ?? 0) > 0

                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.preferredWidth: 36
                                    Layout.preferredHeight: 29
                                    surfaceRadius: 10
                                    transparentIdle: true
                                    showSheen: false
                                    active: workspaceActive
                                    hovered: workspaceMouse.containsMouse
                                    pressed: workspaceMouse.pressed
                                    interactive: true
                                    hoverScale: RaohaneMotion.hoverScale
                                    pressedScale: RaohaneMotion.pressScale

                                    Rectangle {
                                        anchors {
                                            left: parent.left
                                            verticalCenter: parent.verticalCenter
                                            leftMargin: 2
                                        }
                                        width: 2
                                        height: workspaceButton.workspaceActive ? 15 : 5
                                        radius: 1
                                        color: RaohaneTheme.accent
                                        opacity: workspaceButton.workspaceActive ? 1 : 0

                                        Behavior on height {
                                            NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeEmphasized }
                                        }
                                        Behavior on opacity { NumberAnimation { duration: RaohaneMotion.micro } }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: workspaceButton.workspaceId
                                        color: workspaceButton.workspaceActive ? RaohaneTheme.text : RaohaneTheme.textMuted
                                        font.pixelSize: 9
                                        font.weight: workspaceButton.workspaceActive ? Font.DemiBold : Font.Medium

                                        Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
                                    }

                                    Rectangle {
                                        width: 4
                                        height: 4
                                        radius: 2
                                        anchors {
                                            right: parent.right
                                            rightMargin: 4
                                            verticalCenter: parent.verticalCenter
                                        }
                                        color: workspaceButton.workspaceActive ? RaohaneTheme.accent : RaohaneTheme.textFaint
                                        opacity: workspaceButton.occupied ? 1 : 0
                                        scale: workspaceButton.occupied ? 1 : 0.4

                                        Behavior on opacity { NumberAnimation { duration: RaohaneMotion.micro } }
                                        Behavior on scale {
                                            NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeEmphasized }
                                        }
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
                                : (RaohaneContext.mode === "media" ? "music_note" : "circle")
                            emphasized: RaohanePrivacy.recordingActive || RaohanePrivacy.cameraActive || RaohanePrivacy.microphoneActive || RaohaneContext.mode === "media"
                            tooltip: RaohaneContext.title
                            onTriggered: {
                                if (RaohaneContext.mode === "media")
                                    RaohaneState.mediaOverlayOpen = !RaohaneState.mediaOverlayOpen
                                else
                                    RaohaneState.togglePrimary("controlCenter")
                            }
                        }

                        IconButton {
                            icon: RaohaneNetwork.materialSymbol
                            emphasized: RaohaneNetwork.wifiConnected || RaohaneNetwork.ethernet
                            tooltip: RaohaneNetwork.networkName.length > 0 ? RaohaneNetwork.networkName : qsTr("Network")
                            onTriggered: RaohaneState.togglePrimary("controlCenter")
                        }

                        IconButton {
                            visible: RaohaneBluetooth.available
                            icon: RaohaneBluetooth.connected ? "bluetooth_connected" : (RaohaneBluetooth.enabled ? "bluetooth" : "bluetooth_disabled")
                            emphasized: RaohaneBluetooth.connected
                            tooltip: RaohaneBluetooth.connected ? RaohaneBluetooth.firstConnectedName : qsTr("Bluetooth")
                            onTriggered: RaohaneBluetooth.toggle()
                        }

                        IconButton {
                            icon: RaohaneNotifications.silent ? "notifications_off" : "notifications"
                            emphasized: RaohaneNotifications.unread > 0
                            tooltip: qsTr("Notifications")
                            badgeCount: RaohaneNotifications.unread
                            onTriggered: RaohaneState.togglePrimary("controlCenter")
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: RaohaneTheme.borderFaint
                        }

                        ColumnLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: -2

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: Qt.formatTime(root.now, "HH")
                                color: RaohaneTheme.text
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: Qt.formatTime(root.now, "mm")
                                color: RaohaneTheme.text
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                            }
                            Text {
                                visible: RaohaneConfig.barShowDate
                                Layout.alignment: Qt.AlignHCenter
                                text: Qt.formatDate(root.now, "dd")
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 7
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: RaohaneTheme.borderFaint
                        }

                        IconButton {
                            icon: RaohaneAudio.muted ? "volume_off" : (RaohaneAudio.volume > 0.66 ? "volume_up" : RaohaneAudio.volume > 0.05 ? "volume_down" : "volume_mute")
                            emphasized: !RaohaneAudio.muted && RaohaneAudio.volume > 0
                            tooltip: RaohaneAudio.muted ? qsTr("Muted") : qsTr("Volume %1%").arg(Math.round(RaohaneAudio.volume * 100))
                            onTriggered: RaohaneAudio.toggleMute()
                        }

                        IconButton {
                            icon: "tune"
                            emphasized: RaohaneState.controlCenterOpen
                            tooltip: qsTr("Control Center")
                            onTriggered: RaohaneState.togglePrimary("controlCenter")
                        }

                        IconButton {
                            icon: "power_settings_new"
                            tooltip: qsTr("Session")
                            onTriggered: RaohaneState.setPrimaryOpen("session", true)
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

    component IconButton: RaohaneIconButton {
        id: button

        property string tooltip: ""
        property int badgeCount: 0
        signal triggered()

        Layout.alignment: Qt.AlignHCenter
        buttonSize: 36
        iconSize: 16
        transparentIdle: true
        onClicked: button.triggered()

        Rectangle {
            anchors {
                right: parent.right
                top: parent.top
                rightMargin: 1
                topMargin: 1
            }
            width: 14
            height: 14
            radius: 7
            color: RaohaneTheme.accent
            opacity: button.badgeCount > 0 ? 1 : 0
            scale: button.badgeCount > 0 ? 1 : 0.45

            Text {
                anchors.centerIn: parent
                text: Math.min(9, button.badgeCount) + (button.badgeCount > 9 ? "+" : "")
                color: RaohaneTheme.background
                font.pixelSize: 6
                font.weight: Font.Bold
            }

            Behavior on opacity { NumberAnimation { duration: RaohaneMotion.micro } }
            Behavior on scale {
                NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeEmphasized }
            }
        }
    }
}
