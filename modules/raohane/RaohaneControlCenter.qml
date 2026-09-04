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
    readonly property int panelWidth: Math.min(442, Math.max(392, Math.round((root.focusedScreen?.width ?? 1280) * 0.29)))
    readonly property int panelHeight: Math.min(728, Math.max(620, Math.round((root.focusedScreen?.height ?? 800) - 38)))
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
            top: 12
            right: 12
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
            scale: entered ? 1 : 0.992

            transform: Translate {
                x: panelSurface.entered ? 0 : 18
                y: panelSurface.entered ? 0 : -4

                Behavior on x {
                    NumberAnimation { duration: RaohaneMotion.enter; easing.type: RaohaneMotion.easeEmphasized }
                }
                Behavior on y {
                    NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeEmphasized }
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
                    topMargin: -84
                    rightMargin: -70
                }
                width: 210
                height: 210
                radius: 105
                color: RaohaneTheme.accentSoft
                opacity: panelSurface.entered ? 0.20 : 0

                Behavior on opacity {
                    NumberAnimation { duration: RaohaneMotion.relaxed; easing.type: RaohaneMotion.easeStandard }
                }
            }

            Rectangle {
                z: 20
                anchors {
                    left: parent.left
                    top: parent.top
                    leftMargin: 18
                }
                width: 38
                height: 2
                radius: 1
                color: RaohaneTheme.accent
                opacity: 0.62
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                anchors.topMargin: 14
                anchors.bottomMargin: 10
                spacing: 0

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 62

                    RowLayout {
                        anchors.fill: parent
                        spacing: 9

                        RaohaneSurface {
                            Layout.preferredWidth: 42
                            Layout.preferredHeight: 42
                            surfaceRadius: 14
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
                            spacing: 1

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

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 31
                    spacing: 6

                    StatusPill {
                        icon: RaohaneNetwork.materialSymbol
                        text: RaohaneNetwork.networkName.length > 0
                            ? RaohaneNetwork.networkName
                            : (RaohaneNetwork.ethernet ? qsTr("Ethernet") : qsTr("Offline"))
                        active: RaohaneNetwork.wifiConnected || RaohaneNetwork.ethernet
                    }

                    StatusPill {
                        icon: RaohanePrivacy.recordingActive ? "screen_record"
                            : RaohanePrivacy.cameraActive ? "videocam"
                            : RaohanePrivacy.microphoneActive ? "mic" : "verified_user"
                        text: RaohanePrivacy.recordingActive || RaohanePrivacy.cameraActive || RaohanePrivacy.microphoneActive
                            ? qsTr("Privacy activity") : qsTr("System ready")
                        active: RaohanePrivacy.recordingActive || RaohanePrivacy.cameraActive || RaohanePrivacy.microphoneActive
                        critical: active
                    }

                    Item { Layout.fillWidth: true }
                }

                SectionHeader {
                    Layout.topMargin: 2
                    label: qsTr("CONTROLS")
                    icon: "tune"
                }

                RaohaneQuickControls {
                    id: quickControls
                    Layout.fillWidth: true
                    Layout.preferredHeight: implicitHeight
                    screen: panelWindow.screen
                }

                NowPlayingCard {
                    visible: !quickControls.pickerOpen && RaohaneMedia.available
                    Layout.fillWidth: true
                    Layout.preferredHeight: visible ? 58 : 0
                    Layout.topMargin: visible ? 8 : 0
                }

                SectionHeader {
                    visible: !quickControls.pickerOpen
                    Layout.topMargin: 5
                    label: qsTr("Notifications")
                    icon: RaohaneNotifications.silent ? "notifications_off" : "notifications"
                    count: RaohaneNotifications.unread
                }

                RaohaneNotificationCenter {
                    visible: !quickControls.pickerOpen
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: quickControls.pickerOpen ? 0 : 146
                }

                Rectangle {
                    visible: !quickControls.pickerOpen
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    Layout.topMargin: 6
                    color: RaohaneTheme.borderFaint
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 35
                    spacing: 7

                    Rectangle {
                        width: 5
                        height: 5
                        radius: 3
                        color: RaohanePrivacy.recordingActive || RaohanePrivacy.cameraActive || RaohanePrivacy.microphoneActive
                            ? RaohaneTheme.critical
                            : RaohaneTheme.success

                        Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: RaohanePrivacy.recordingActive || RaohanePrivacy.cameraActive || RaohanePrivacy.microphoneActive
                            ? qsTr("Privacy activity")
                            : qsTr("System ready")
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 7
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                    }

                    ActionButton {
                        icon: "restart_alt"
                        onClicked: RaohaneSession.reloadDesktop()
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

    component SectionHeader: Item {
        id: sectionHeader

        required property string label
        required property string icon
        property int count: 0

        Layout.fillWidth: true
        Layout.preferredHeight: 29

        RowLayout {
            anchors.fill: parent
            spacing: 6

            RaohaneIcon {
                text: sectionHeader.icon
                iconSize: 11
                color: RaohaneTheme.textFaint
            }

            Text {
                text: sectionHeader.label.toUpperCase()
                color: RaohaneTheme.textFaint
                font.pixelSize: 7
                font.weight: Font.DemiBold
                font.letterSpacing: 0.8
            }

            Rectangle {
                visible: sectionHeader.count > 0
                Layout.preferredWidth: Math.max(16, countText.implicitWidth + 8)
                Layout.preferredHeight: 16
                radius: 8
                color: RaohaneTheme.accentSoft

                Text {
                    id: countText
                    anchors.centerIn: parent
                    text: sectionHeader.count > 99 ? "99+" : String(sectionHeader.count)
                    color: RaohaneTheme.accent
                    font.pixelSize: 6
                    font.weight: Font.Bold
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 1
                color: RaohaneTheme.borderFaint
            }
        }
    }

    component StatusPill: RaohaneSurface {
        id: pill
        required property string icon
        required property string text
        property bool critical: false

        implicitWidth: Math.min(160, pillRow.implicitWidth + 14)
        implicitHeight: 22
        surfaceRadius: 10
        transparentIdle: !pill.active
        showSheen: false
        border.color: pill.critical ? Qt.rgba(RaohaneTheme.critical.r, RaohaneTheme.critical.g, RaohaneTheme.critical.b, 0.48)
            : pill.active ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint

        Row {
            id: pillRow
            anchors.centerIn: parent
            spacing: 5

            RaohaneIcon {
                text: pill.icon
                iconSize: 11
                fill: pill.active ? 1 : 0
                color: pill.critical ? RaohaneTheme.critical
                    : pill.active ? RaohaneTheme.accent : RaohaneTheme.textMuted
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                width: Math.min(118, implicitWidth)
                text: pill.text
                color: pill.critical ? RaohaneTheme.critical
                    : pill.active ? RaohaneTheme.text : RaohaneTheme.textMuted
                font.pixelSize: 7
                font.weight: Font.Medium
                elide: Text.ElideRight
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    component NowPlayingCard: RaohaneSurface {
        id: mediaCard

        surfaceRadius: 15
        showSheen: false
        raised: false
        hovered: mediaMouse.containsMouse
        interactive: true
        hoverScale: RaohaneMotion.subtleHoverScale
        border.color: hovered ? RaohaneTheme.borderStrong : RaohaneTheme.borderFaint

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 7
            spacing: 8

            Rectangle {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                radius: 12
                color: RaohaneTheme.accentSoft
                clip: true

                Image {
                    id: mediaArt
                    anchors.fill: parent
                    source: RaohaneMedia.artUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: status === Image.Ready
                }

                RaohaneIcon {
                    anchors.centerIn: parent
                    visible: !mediaArt.visible
                    text: "music_note"
                    iconSize: 19
                    fill: RaohaneMedia.isPlaying ? 1 : 0
                    color: RaohaneTheme.accent
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: RaohaneMedia.title.length > 0 ? RaohaneMedia.title : qsTr("Media")
                    color: RaohaneTheme.text
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: RaohaneMedia.artist.length > 0 ? RaohaneMedia.artist : RaohaneMedia.playerName
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 7
                    elide: Text.ElideRight
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 2
                    Layout.topMargin: 4
                    radius: 1
                    color: RaohaneTheme.borderFaint

                    Rectangle {
                        width: parent.width * RaohaneMedia.progress
                        height: parent.height
                        radius: 1
                        color: RaohaneTheme.accent

                        Behavior on width {
                            NumberAnimation { duration: RaohaneMotion.micro; easing.type: RaohaneMotion.easeStandard }
                        }
                    }
                }
            }

            RaohaneIconButton {
                buttonSize: 28
                iconSize: 14
                icon: RaohaneMedia.isPlaying ? "pause" : "play_arrow"
                emphasized: RaohaneMedia.isPlaying
                transparentIdle: !RaohaneMedia.isPlaying
                enabled: RaohaneMedia.canTogglePlaying
                onClicked: RaohaneMedia.togglePlaying()
            }

            RaohaneIconButton {
                buttonSize: 28
                iconSize: 14
                icon: "skip_next"
                transparentIdle: true
                enabled: RaohaneMedia.canGoNext
                onClicked: RaohaneMedia.next()
            }
        }

        MouseArea {
            id: mediaMouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.PointingHandCursor
            z: -1
            onClicked: RaohaneState.toggleSurface("mediaOverlay")
        }
    }
}
