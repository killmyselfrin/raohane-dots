pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.modules.raohane.services

Scope {
    id: root

    readonly property var focusedScreen: Quickshell.screens.find(screen => screen.name === Hyprland.focusedMonitor?.name)
        ?? Quickshell.screens[0]
    property date now: new Date()

    function open(): void { RaohaneState.setPrimaryOpen("leftSidebar", true) }
    function close(): void { RaohaneState.setPrimaryOpen("leftSidebar", false) }
    function toggle(): void { RaohaneState.togglePrimary("leftSidebar") }

    Connections {
        target: RaohaneState
        function onLeftSidebarOpenChanged(): void {
            if (RaohaneState.leftSidebarOpen)
                root.now = new Date()
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: RaohaneState.leftSidebarOpen
        onTriggered: root.now = new Date()
    }

    PanelWindow {
        id: sidebarWindow

        visible: RaohaneState.leftSidebarOpen
        screen: root.focusedScreen
        implicitWidth: 380
        color: "transparent"
        exclusiveZone: 0
        exclusionMode: ExclusionMode.Ignore

        anchors {
            top: true
            bottom: true
            left: true
        }

        margins {
            top: 14
            bottom: 14
            left: 14
        }

        WlrLayershell.namespace: "quickshell:raohane-sidebar-left"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        Rectangle {
            anchors.fill: parent
            radius: 28
            color: RaohaneTheme.glassStrong
            border.width: 1
            border.color: RaohaneTheme.border

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: "RAOHANE / SIDE"
                            color: RaohaneTheme.accent
                            font.pixelSize: 10
                            font.bold: true
                            font.letterSpacing: 1.2
                        }

                        Text {
                            text: qsTr("Quick glance")
                            color: RaohaneTheme.text
                            font.pixelSize: 20
                            font.weight: Font.DemiBold
                        }
                    }

                    ColumnLayout {
                        spacing: 0
                        Text {
                            Layout.alignment: Qt.AlignRight
                            text: Qt.formatTime(root.now, "HH:mm")
                            color: RaohaneTheme.text
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }
                        Text {
                            Layout.alignment: Qt.AlignRight
                            text: Qt.formatDate(root.now, "ddd, d MMM")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 9
                        }
                    }

                    SmallButton {
                        glyph: "×"
                        onTriggered: root.close()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 106
                    radius: 20
                    color: "#14ffffff"
                    border.width: 1
                    border.color: RaohaneTheme.border

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        Rectangle {
                            Layout.preferredWidth: 78
                            Layout.preferredHeight: 78
                            radius: 16
                            color: RaohaneTheme.accentSoft
                            clip: true

                            Image {
                                id: mediaArt
                                anchors.fill: parent
                                source: RaohaneMedia.artUrl
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: mediaArt.status !== Image.Ready
                                text: "音"
                                color: RaohaneTheme.accent
                                font.pixelSize: 24
                                font.bold: true
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            Text {
                                Layout.fillWidth: true
                                text: RaohaneMedia.available && RaohaneMedia.title.length > 0
                                    ? RaohaneMedia.title : qsTr("No active player")
                                color: RaohaneTheme.text
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: RaohaneMedia.available && RaohaneMedia.artist.length > 0
                                    ? RaohaneMedia.artist : qsTr("Start music to see it here")
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }

                            Item { Layout.fillHeight: true }

                            RowLayout {
                                SmallButton {
                                    glyph: "⏮"
                                    enabled: RaohaneMedia.canGoPrevious
                                    onTriggered: RaohaneMedia.previous()
                                }
                                SmallButton {
                                    glyph: RaohaneMedia.isPlaying ? "Ⅱ" : "▶"
                                    emphasized: true
                                    enabled: RaohaneMedia.canTogglePlaying
                                    onTriggered: RaohaneMedia.togglePlaying()
                                }
                                SmallButton {
                                    glyph: "⏭"
                                    enabled: RaohaneMedia.canGoNext
                                    onTriggered: RaohaneMedia.next()
                                }
                                Item { Layout.fillWidth: true }
                                SmallButton {
                                    glyph: "↗"
                                    enabled: RaohaneMedia.available
                                    onTriggered: {
                                        root.close()
                                        RaohaneState.mediaOverlayOpen = true
                                    }
                                }
                            }
                        }
                    }
                }

                Text {
                    text: qsTr("AUDIO")
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 9
                    font.bold: true
                    font.letterSpacing: 1.2
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 78
                    radius: 18
                    color: "#10ffffff"
                    border.width: 1
                    border.color: RaohaneTheme.border

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: RaohaneAudio.muted ? qsTr("Muted") : qsTr("Volume")
                                color: RaohaneTheme.text
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: RaohaneAudio.ready ? Math.round(RaohaneAudio.volume * 100) + "%" : "—"
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 11
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 7
                            radius: height / 2
                            color: "#2affffff"

                            Rectangle {
                                width: parent.width * (RaohaneAudio.muted ? 0 : RaohaneAudio.volume)
                                height: parent.height
                                radius: parent.radius
                                color: RaohaneTheme.accent
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: RaohaneAudio.ready
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onPressed: mouse => RaohaneAudio.setVolume(mouse.x / width)
                                onPositionChanged: mouse => {
                                    if (pressed)
                                        RaohaneAudio.setVolume(mouse.x / width)
                                }
                            }
                        }
                    }
                }

                Text {
                    text: qsTr("SYSTEM")
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 9
                    font.bold: true
                    font.letterSpacing: 1.2
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 156
                    radius: 18
                    color: "#10ffffff"
                    border.width: 1
                    border.color: RaohaneTheme.border

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 9
                        spacing: 3

                        StatusRow {
                            icon: RaohaneNetwork.materialSymbol
                            title: RaohaneNetwork.ethernet ? qsTr("Ethernet") : qsTr("Network")
                            detail: RaohaneNetwork.networkName.length > 0
                                ? RaohaneNetwork.networkName
                                : (RaohaneNetwork.wifiEnabled ? qsTr("Not connected") : qsTr("Wi-Fi off"))
                            active: RaohaneNetwork.wifiConnected || RaohaneNetwork.ethernet
                            onTriggered: RaohaneState.setPrimaryOpen("controlCenter", true)
                        }

                        StatusRow {
                            icon: RaohaneBluetooth.connected ? "bluetooth_connected" : (RaohaneBluetooth.enabled ? "bluetooth" : "bluetooth_disabled")
                            title: qsTr("Bluetooth")
                            detail: RaohaneBluetooth.connected
                                ? RaohaneBluetooth.firstConnectedName
                                : (RaohaneBluetooth.enabled ? qsTr("Ready") : qsTr("Off"))
                            active: RaohaneBluetooth.connected
                            onTriggered: RaohaneBluetooth.toggle()
                        }

                        StatusRow {
                            icon: RaohaneNotifications.silent ? "notifications_off" : "notifications"
                            title: qsTr("Notifications")
                            detail: RaohaneNotifications.unread > 0
                                ? qsTr("%1 unread").arg(RaohaneNotifications.unread)
                                : qsTr("All caught up")
                            active: RaohaneNotifications.unread > 0
                            onTriggered: RaohaneState.setPrimaryOpen("controlCenter", true)
                        }

                        StatusRow {
                            icon: RaohanePrivacy.recordingActive ? "screen_record"
                                : RaohanePrivacy.cameraActive ? "videocam"
                                : RaohanePrivacy.microphoneActive ? "mic"
                                : "shield"
                            title: qsTr("Privacy")
                            detail: RaohanePrivacy.recordingActive ? qsTr("Screen capture active")
                                : RaohanePrivacy.cameraActive && RaohanePrivacy.microphoneActive ? qsTr("Camera and microphone active")
                                : RaohanePrivacy.cameraActive ? qsTr("Camera active")
                                : RaohanePrivacy.microphoneActive ? qsTr("Microphone active")
                                : qsTr("No capture devices active")
                            active: RaohanePrivacy.recordingActive || RaohanePrivacy.cameraActive || RaohanePrivacy.microphoneActive
                            onTriggered: RaohaneState.setPrimaryOpen("controlCenter", true)
                        }
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    rowSpacing: 8
                    columnSpacing: 8

                    ActionButton {
                        glyph: "⌕"
                        title: qsTr("Launcher")
                        onTriggered: RaohaneState.setPrimaryOpen("launcher", true)
                    }
                    ActionButton {
                        glyph: "◎"
                        title: qsTr("Control")
                        onTriggered: RaohaneState.setPrimaryOpen("controlCenter", true)
                    }
                    ActionButton {
                        glyph: "▧"
                        title: qsTr("Wallpaper")
                        onTriggered: RaohaneState.setPrimaryOpen("wallpaper", true)
                    }
                    ActionButton {
                        glyph: "文"
                        title: qsTr("Translate")
                        onTriggered: RaohaneState.setPrimaryOpen("screenTranslator", true)
                    }
                    ActionButton {
                        glyph: "⚙"
                        title: qsTr("Settings")
                        onTriggered: RaohaneState.setPrimaryOpen("settings", true)
                    }
                    ActionButton {
                        glyph: "⏻"
                        title: qsTr("Session")
                        onTriggered: RaohaneState.setPrimaryOpen("session", true)
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }
    }

    IpcHandler {
        target: "sidebarLeft"
        function toggle(): void { root.toggle() }
        function open(): void { root.open() }
        function close(): void { root.close() }
    }

    CompositorGlobalShortcut {
        name: "sidebarLeftToggle"
        description: "Toggle the Raohane left sidebar"
        onPressed: root.toggle()
    }

    component StatusRow: Rectangle {
        id: statusRow
        required property string icon
        required property string title
        required property string detail
        property bool active: false
        signal triggered()

        Layout.fillWidth: true
        Layout.preferredHeight: 31
        radius: 11
        color: statusMouse.containsMouse ? "#20ffffff" : "transparent"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 7
            anchors.rightMargin: 7
            spacing: 8

            RaohaneIcon {
                text: statusRow.icon
                iconSize: 15
                color: statusRow.active ? RaohaneTheme.accent : RaohaneTheme.textMuted
            }

            Text {
                text: statusRow.title
                color: RaohaneTheme.text
                font.pixelSize: 10
                font.weight: Font.DemiBold
            }

            Item { Layout.fillWidth: true }

            Text {
                Layout.maximumWidth: 170
                text: statusRow.detail
                color: RaohaneTheme.textMuted
                font.pixelSize: 9
                elide: Text.ElideRight
            }
        }

        MouseArea {
            id: statusMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: statusRow.triggered()
        }
    }

    component SmallButton: Rectangle {
        id: button
        required property string glyph
        property bool emphasized: false
        signal triggered()

        implicitWidth: 30
        implicitHeight: 30
        radius: 15
        opacity: button.enabled ? 1 : 0.35
        color: emphasized ? RaohaneTheme.accentSoft
            : buttonMouse.containsMouse && button.enabled ? "#24ffffff" : "transparent"
        border.width: emphasized ? 1 : 0
        border.color: RaohaneTheme.border

        Text {
            anchors.centerIn: parent
            text: button.glyph
            color: emphasized ? RaohaneTheme.accent : RaohaneTheme.text
            font.pixelSize: 14
            font.weight: Font.DemiBold
        }

        MouseArea {
            id: buttonMouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: button.enabled
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: button.triggered()
        }
    }

    component ActionButton: Rectangle {
        id: action
        required property string glyph
        required property string title
        signal triggered()

        Layout.fillWidth: true
        Layout.preferredHeight: 48
        radius: 16
        color: actionMouse.containsMouse ? "#24ffffff" : "#10ffffff"
        border.width: 1
        border.color: actionMouse.containsMouse ? RaohaneTheme.accentSoft : RaohaneTheme.border

        RowLayout {
            anchors.centerIn: parent
            spacing: 8
            Text {
                text: action.glyph
                color: RaohaneTheme.accent
                font.pixelSize: 15
            }
            Text {
                text: action.title
                color: RaohaneTheme.text
                font.pixelSize: 10
                font.weight: Font.DemiBold
            }
        }

        MouseArea {
            id: actionMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: action.triggered()
        }
    }
}
