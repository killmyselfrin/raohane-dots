pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.modules.raohane.config
import qs.modules.raohane.services

Item {
    id: root

    function openPage(page: string): void {
        RaohaneState.settingsPage = page
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 190
            radius: 22
            color: "#241f31"
            border.width: 1
            border.color: RaohaneTheme.border
            clip: true

            Image {
                anchors.fill: parent
                source: RaohaneConfig.wallpaperPath
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                opacity: status === Image.Ready ? 0.68 : 0
            }

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#e512101a" }
                    GradientStop { position: 0.55; color: "#a512101a" }
                    GradientStop { position: 1.0; color: "#4a12101a" }
                }
            }

            Column {
                anchors {
                    left: parent.left
                    leftMargin: 20
                    top: parent.top
                    topMargin: 18
                }
                spacing: 3

                Text {
                    text: "RAOHANE / CONTROL DECK"
                    color: RaohaneTheme.text
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.2
                }

                Text {
                    text: qsTr("A living Hyprland shell · ラオハネ")
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 10
                }
            }

            RaohaneContextIsland {
                anchors {
                    left: parent.left
                    leftMargin: 20
                    bottom: parent.bottom
                    bottomMargin: 18
                }
            }

            Column {
                anchors {
                    right: parent.right
                    rightMargin: 18
                    bottom: parent.bottom
                    bottomMargin: 18
                }
                spacing: 6

                StatusChip {
                    icon: RaohaneNetwork.materialSymbol
                    text: RaohaneNetwork.networkName || qsTr("Offline")
                    active: RaohaneNetwork.wifiStatus !== "disabled"
                }

                StatusChip {
                    icon: RaohaneAudio.muted ? "volume_off" : "volume_up"
                    text: qsTr("Volume %1%").arg(Math.round(RaohaneAudio.volume * 100))
                    active: RaohaneAudio.ready && !RaohaneAudio.muted
                }

                StatusChip {
                    icon: RaohanePrivacy.recordingActive ? "screen_record"
                        : RaohanePrivacy.cameraActive ? "videocam"
                        : RaohanePrivacy.microphoneActive ? "mic" : "shield"
                    text: RaohanePrivacy.recordingActive ? qsTr("Screen capture")
                        : RaohanePrivacy.cameraActive ? qsTr("Camera active")
                        : RaohanePrivacy.microphoneActive ? qsTr("Microphone active")
                        : qsTr("Privacy clear")
                    active: RaohanePrivacy.recordingActive || RaohanePrivacy.cameraActive || RaohanePrivacy.microphoneActive
                    critical: active
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: qsTr("Configure Raohane")
                color: RaohaneTheme.text
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }

            Text {
                text: qsTr("changes are written live")
                color: RaohaneTheme.textMuted
                font.pixelSize: 9
            }

            Item { Layout.fillWidth: true }

            PathChip {
                label: "native.json"
                path: RaohanePaths.nativeConfigFile
                icon: "tune"
            }

            PathChip {
                label: "autostart.conf"
                path: RaohanePaths.autostartFile
                icon: "rocket_launch"
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: root.width > 760 ? 3 : 2
            columnSpacing: 10
            rowSpacing: 10

            DeckCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                icon: "instant_mix"
                title: qsTr("Quick")
                detail: qsTr("Core shell behavior and fast presets")
                page: "Quick"
            }

            DeckCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                icon: "toast"
                title: qsTr("Bar")
                detail: qsTr("Layout, modules and Context Island")
                page: "Bar"
            }

            DeckCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                icon: "texture"
                title: qsTr("Desktop")
                detail: qsTr("Wallpaper, colors and living background")
                page: "Desktop"
            }

            DeckCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                icon: "bottom_app_bar"
                title: qsTr("Interface")
                detail: qsTr("Panels, effects and interaction style")
                page: "Interface"
            }

            DeckCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                icon: "select_window_2"
                title: qsTr("Hyprland")
                detail: qsTr("Compositor behavior and window rules")
                page: "Hyprland"
            }

            DeckCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                icon: "settings"
                title: qsTr("Services")
                detail: qsTr("System integrations, autostart and background helpers")
                page: "Services"
            }
        }
    }

    component PathChip: Rectangle {
        id: pathChip

        required property string label
        required property string path
        required property string icon

        width: pathRow.implicitWidth + 18
        height: 28
        radius: 14
        color: pathMouse.containsMouse ? RaohaneTheme.accentSoft : "#18ffffff"
        border.width: 1
        border.color: pathMouse.containsMouse ? RaohaneTheme.accent : RaohaneTheme.border

        Row {
            id: pathRow
            anchors.centerIn: parent
            spacing: 5

            RaohaneIcon {
                text: pathChip.icon
                iconSize: 13
                color: pathMouse.containsMouse ? RaohaneTheme.accent : RaohaneTheme.textMuted
            }

            Text {
                text: pathChip.label
                color: RaohaneTheme.textMuted
                font.pixelSize: 8
            }
        }

        MouseArea {
            id: pathMouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton)
                    Quickshell.clipboardText = pathChip.path
                else
                    Qt.openUrlExternally("file://" + pathChip.path)
            }
        }
    }

    component DeckCard: Rectangle {
        id: card

        required property string icon
        required property string title
        required property string detail
        required property string page

        Layout.minimumHeight: 104
        radius: 19
        color: cardMouse.containsMouse ? RaohaneTheme.accentSoft : "#7f17141f"
        border.width: 1
        border.color: cardMouse.containsMouse ? RaohaneTheme.accent : RaohaneTheme.border

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 13
            spacing: 5

            RowLayout {
                Layout.fillWidth: true

                Rectangle {
                    width: 34
                    height: 34
                    radius: 12
                    color: cardMouse.containsMouse ? "#28ffffff" : RaohaneTheme.accentSoft

                    RaohaneIcon {
                        anchors.centerIn: parent
                        text: card.icon
                        iconSize: 19
                        color: RaohaneTheme.accent
                    }
                }

                Item { Layout.fillWidth: true }

                RaohaneIcon {
                    text: "arrow_forward"
                    iconSize: 16
                    color: cardMouse.containsMouse ? RaohaneTheme.accent : RaohaneTheme.textMuted
                }
            }

            Text {
                Layout.fillWidth: true
                text: card.title
                color: RaohaneTheme.text
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }

            Text {
                Layout.fillWidth: true
                text: card.detail
                color: RaohaneTheme.textMuted
                font.pixelSize: 8
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
        }

        MouseArea {
            id: cardMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.openPage(card.page)
        }
    }

    component StatusChip: Rectangle {
        id: chip

        required property string icon
        required property string text
        property bool active: false
        property bool critical: false

        width: chipRow.implicitWidth + 16
        height: 26
        radius: 13
        color: critical ? "#35ff668c" : active ? RaohaneTheme.accentSoft : "#8517131f"
        border.width: 1
        border.color: critical ? RaohaneTheme.critical : RaohaneTheme.border

        Row {
            id: chipRow
            anchors.centerIn: parent
            spacing: 6

            RaohaneIcon {
                text: chip.icon
                iconSize: 14
                color: chip.critical ? RaohaneTheme.critical : chip.active ? RaohaneTheme.accent : RaohaneTheme.textMuted
            }

            Text {
                text: chip.text
                color: RaohaneTheme.text
                font.pixelSize: 8
                font.weight: Font.DemiBold
            }
        }
    }
}
