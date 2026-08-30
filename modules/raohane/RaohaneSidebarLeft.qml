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
        implicitWidth: 372
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

        RaohaneSurface {
            anchors.fill: parent
            surfaceRadius: RaohaneTheme.radiusHero
            raised: true
            showSheen: false
            border.color: RaohaneTheme.borderStrong

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    spacing: 9

                    Rectangle {
                        width: 34
                        height: 34
                        radius: 11
                        color: RaohaneTheme.surfaceSubtle
                        border.width: 1
                        border.color: RaohaneTheme.border

                        RaohaneIcon {
                            anchors.centerIn: parent
                            text: "dashboard"
                            iconSize: 17
                            color: RaohaneTheme.accent
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            text: qsTr("Quick glance")
                            color: RaohaneTheme.text
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: qsTr("Media and system status")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 8
                        }
                    }

                    ColumnLayout {
                        spacing: -1
                        Text {
                            Layout.alignment: Qt.AlignRight
                            text: Qt.formatTime(root.now, "HH:mm")
                            color: RaohaneTheme.text
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                        }
                        Text {
                            Layout.alignment: Qt.AlignRight
                            text: Qt.formatDate(root.now, "ddd, d MMM")
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 7
                        }
                    }

                    IconControl {
                        icon: "close"
                        onTriggered: root.close()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: RaohaneTheme.borderFaint
                }

                RaohaneSurface {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 104
                    surfaceRadius: 16
                    raised: false
                    showSheen: false

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 11
                        spacing: 11

                        Rectangle {
                            Layout.preferredWidth: 76
                            Layout.preferredHeight: 76
                            radius: 14
                            color: RaohaneTheme.surfaceSubtle
                            border.width: 1
                            border.color: RaohaneTheme.border
                            clip: true

                            Image {
                                id: mediaArt
                                anchors.fill: parent
                                source: RaohaneMedia.artUrl
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: false
                            }

                            RaohaneIcon {
                                anchors.centerIn: parent
                                visible: mediaArt.status !== Image.Ready
                                text: "music_note"
                                iconSize: 25
                                color: RaohaneTheme.textMuted
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 3

                            Text {
                                Layout.fillWidth: true
                                text: RaohaneMedia.available && RaohaneMedia.title.length > 0
                                    ? RaohaneMedia.title : qsTr("No active player")
                                color: RaohaneTheme.text
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: RaohaneMedia.available && RaohaneMedia.artist.length > 0
                                    ? RaohaneMedia.artist : qsTr("Start music to see it here")
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 8
                                elide: Text.ElideRight
                            }

                            Item { Layout.fillHeight: true }

                            RowLayout {
                                spacing: 5

                                IconControl {
                                    icon: "skip_previous"
                                    enabled: RaohaneMedia.canGoPrevious
                                    onTriggered: RaohaneMedia.previous()
                                }
                                IconControl {
                                    icon: RaohaneMedia.isPlaying ? "pause" : "play_arrow"
                                    active: RaohaneMedia.isPlaying
                                    enabled: RaohaneMedia.canTogglePlaying
                                    onTriggered: RaohaneMedia.togglePlaying()
                                }
                                IconControl {
                                    icon: "skip_next"
                                    enabled: RaohaneMedia.canGoNext
                                    onTriggered: RaohaneMedia.next()
                                }
                                Item { Layout.fillWidth: true }
                                IconControl {
                                    icon: "open_in_new"
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

                SectionLabel { text: qsTr("Audio") }

                RaohaneSurface {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 70
                    surfaceRadius: 15
                    raised: false
                    showSheen: false

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 11
                        spacing: 7

                        RowLayout {
                            Layout.fillWidth: true

                            RaohaneIcon {
                                text: RaohaneAudio.muted ? "volume_off" : "volume_up"
                                iconSize: 15
                                color: RaohaneAudio.muted ? RaohaneTheme.textMuted : RaohaneTheme.accent
                            }
                            Text {
                                text: RaohaneAudio.muted ? qsTr("Muted") : qsTr("Volume")
                                color: RaohaneTheme.text
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: RaohaneAudio.ready ? Math.round(RaohaneAudio.volume * 100) + "%" : "—"
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 8
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 18

                            Rectangle {
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    verticalCenter: parent.verticalCenter
                                }
                                height: 5
                                radius: 3
                                color: RaohaneTheme.surfaceDeep
                                border.width: 1
                                border.color: RaohaneTheme.borderFaint

                                Rectangle {
                                    width: parent.width * (RaohaneAudio.muted ? 0 : RaohaneAudio.volume)
                                    height: parent.height
                                    radius: parent.radius
                                    color: RaohaneTheme.accent
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: RaohaneAudio.ready
                                preventStealing: true
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

                SectionLabel { text: qsTr("System") }

                RaohaneSurface {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 152
                    surfaceRadius: 15
                    raised: false
                    showSheen: false

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 7
                        spacing: 2

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

                SectionLabel { text: qsTr("Shortcuts") }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 3
                    rowSpacing: 6
                    columnSpacing: 6

                    ActionButton {
                        icon: "search"
                        title: qsTr("Launcher")
                        onTriggered: RaohaneState.setPrimaryOpen("launcher", true)
                    }
                    ActionButton {
                        icon: "tune"
                        title: qsTr("Control")
                        onTriggered: RaohaneState.setPrimaryOpen("controlCenter", true)
                    }
                    ActionButton {
                        icon: "wallpaper"
                        title: qsTr("Wallpaper")
                        onTriggered: RaohaneState.setPrimaryOpen("wallpaper", true)
                    }
                    ActionButton {
                        icon: "translate"
                        title: qsTr("Translate")
                        onTriggered: RaohaneState.setPrimaryOpen("screenTranslator", true)
                    }
                    ActionButton {
                        icon: "settings"
                        title: qsTr("Settings")
                        onTriggered: RaohaneState.setPrimaryOpen("settings", true)
                    }
                    ActionButton {
                        icon: "power_settings_new"
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

    component SectionLabel: Text {
        color: RaohaneTheme.textFaint
        font.pixelSize: 7
        font.weight: Font.DemiBold
        font.letterSpacing: 0.7
    }

    component StatusRow: Rectangle {
        id: statusRow
        required property string icon
        required property string title
        required property string detail
        property bool active: false
        signal triggered()

        Layout.fillWidth: true
        Layout.preferredHeight: 32
        radius: 9
        color: statusMouse.containsMouse ? RaohaneTheme.surfaceHover : "transparent"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 7
            anchors.rightMargin: 7
            spacing: 7

            RaohaneIcon {
                text: statusRow.icon
                iconSize: 14
                fill: statusRow.active ? 1 : 0
                color: statusRow.active ? RaohaneTheme.accent : RaohaneTheme.textMuted
            }

            Text {
                text: statusRow.title
                color: RaohaneTheme.text
                font.pixelSize: 9
                font.weight: Font.DemiBold
            }

            Item { Layout.fillWidth: true }

            Text {
                Layout.maximumWidth: 166
                text: statusRow.detail
                color: RaohaneTheme.textMuted
                font.pixelSize: 8
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

    component IconControl: Rectangle {
        id: button
        required property string icon
        property bool active: false
        signal triggered()

        implicitWidth: 30
        implicitHeight: 30
        radius: 9
        opacity: button.enabled ? 1 : 0.35
        color: button.active
            ? RaohaneTheme.surfaceRaised
            : buttonMouse.containsMouse && button.enabled ? RaohaneTheme.surfaceHover : "transparent"
        border.width: button.active || buttonMouse.containsMouse ? 1 : 0
        border.color: button.active ? RaohaneTheme.borderStrong : RaohaneTheme.border

        RaohaneIcon {
            anchors.centerIn: parent
            text: button.icon
            iconSize: 15
            fill: button.active ? 1 : 0
            color: button.active ? RaohaneTheme.accent : RaohaneTheme.textMuted
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
        required property string icon
        required property string title
        signal triggered()

        Layout.fillWidth: true
        Layout.preferredHeight: 42
        radius: 11
        color: actionMouse.containsMouse ? RaohaneTheme.surfaceHover : "transparent"
        border.width: 1
        border.color: actionMouse.containsMouse ? RaohaneTheme.borderStrong : RaohaneTheme.border

        Column {
            anchors.centerIn: parent
            spacing: 2

            RaohaneIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                text: action.icon
                iconSize: 15
                color: actionMouse.containsMouse ? RaohaneTheme.accent : RaohaneTheme.textMuted
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: action.title
                color: RaohaneTheme.text
                font.pixelSize: 7
                font.weight: Font.Medium
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
