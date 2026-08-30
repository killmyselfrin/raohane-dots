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
        spacing: 12

        RaohaneSurface {
            Layout.fillWidth: true
            Layout.preferredHeight: 220
            surfaceRadius: RaohaneTheme.radiusLarge
            raised: true
            clip: true
            border.color: RaohaneTheme.accentBorder

            Image {
                anchors.fill: parent
                source: RaohaneConfig.wallpaperPath
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                opacity: status === Image.Ready ? 0.74 : 0
            }

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#f20b0813" }
                    GradientStop { position: 0.48; color: "#c30b0813" }
                    GradientStop { position: 1.0; color: "#66180c2a" }
                }
            }

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    leftMargin: 32
                    rightMargin: 32
                }
                height: 1
                color: RaohaneTheme.accentSecondary
                opacity: 0.36
            }

            Column {
                anchors {
                    left: parent.left
                    leftMargin: 24
                    top: parent.top
                    topMargin: 22
                }
                spacing: 5

                Text {
                    text: "RAOHANE / LIVING SHELL"
                    color: RaohaneTheme.text
                    font.pixelSize: 17
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.25
                }

                Text {
                    text: qsTr("Japanese cyber-noir · native Hyprland control deck")
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 10
                }
            }

            RaohaneContextIsland {
                anchors {
                    left: parent.left
                    leftMargin: 24
                    bottom: parent.bottom
                    bottomMargin: 22
                }
            }

            Column {
                anchors {
                    right: parent.right
                    rightMargin: 22
                    top: parent.top
                    topMargin: 22
                }
                spacing: 7

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

            Row {
                anchors {
                    right: parent.right
                    rightMargin: 22
                    bottom: parent.bottom
                    bottomMargin: 22
                }
                spacing: 7

                MoodChip { label: qsTr("Dreamy"); active: true }
                MoodChip { label: qsTr("Noir") }
                MoodChip { label: qsTr("Zen") }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 9

            ColumnLayout {
                spacing: 0

                Text {
                    text: qsTr("Shape Raohane")
                    color: RaohaneTheme.text
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }

                Text {
                    text: qsTr("native settings are applied live")
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 8
                }
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
            columns: root.width > 820 ? 3 : 2
            columnSpacing: 12
            rowSpacing: 12

            DeckCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                icon: "palette"
                title: qsTr("Appearance")
                detail: qsTr("Identity, quick behavior and signature shell mood")
                page: "Quick"
                accentIndex: 0
            }

            DeckCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                icon: "toast"
                title: qsTr("Bar & Dock")
                detail: qsTr("Floating pods, Context Island and application dock")
                page: "Bar"
                accentIndex: 1
            }

            DeckCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                icon: "texture"
                title: qsTr("Desktop & Spaces")
                detail: qsTr("Wallpaper, Overview, transitions and living canvas")
                page: "Desktop"
                accentIndex: 2
            }

            DeckCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                icon: "bottom_app_bar"
                title: qsTr("Interface")
                detail: qsTr("Screen chrome, corners, effects and interaction feel")
                page: "Interface"
                accentIndex: 3
            }

            DeckCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                icon: "select_window_2"
                title: qsTr("Hyprland")
                detail: qsTr("Compositor-facing behavior, workspaces and fullscreen")
                page: "Hyprland"
                accentIndex: 4
            }

            DeckCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                icon: "settings"
                title: qsTr("System & Services")
                detail: qsTr("Integrations, commands, autostart and native helpers")
                page: "Services"
                accentIndex: 5
            }
        }
    }

    component PathChip: Rectangle {
        id: pathChip

        required property string label
        required property string path
        required property string icon

        width: pathRow.implicitWidth + 20
        height: 30
        radius: 12
        color: pathMouse.containsMouse ? RaohaneTheme.accentSoft : RaohaneTheme.surfaceSubtle
        border.width: 1
        border.color: pathMouse.containsMouse ? RaohaneTheme.accentBorder : RaohaneTheme.border

        Row {
            id: pathRow
            anchors.centerIn: parent
            spacing: 6

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

    component DeckCard: RaohaneSurface {
        id: card

        required property string icon
        required property string title
        required property string detail
        required property string page
        property int accentIndex: 0

        Layout.minimumHeight: 112
        surfaceRadius: 19
        hovered: cardMouse.containsMouse
        raised: false

        Rectangle {
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
            }
            width: 3
            radius: 2
            color: card.accentIndex % 2 === 0
                ? RaohaneTheme.accent
                : RaohaneTheme.accentSecondary
            opacity: cardMouse.containsMouse ? 0.9 : 0.36
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 6

            RowLayout {
                Layout.fillWidth: true

                Rectangle {
                    width: 36
                    height: 36
                    radius: 13
                    color: cardMouse.containsMouse ? RaohaneTheme.accentHover : RaohaneTheme.accentSoft
                    border.width: 1
                    border.color: cardMouse.containsMouse ? RaohaneTheme.accentGlow : RaohaneTheme.border

                    RaohaneIcon {
                        anchors.centerIn: parent
                        text: card.icon
                        iconSize: 19
                        color: cardMouse.containsMouse ? RaohaneTheme.text : RaohaneTheme.accent
                    }
                }

                Item { Layout.fillWidth: true }

                RaohaneIcon {
                    text: "arrow_forward"
                    iconSize: 16
                    color: cardMouse.containsMouse ? RaohaneTheme.accent : RaohaneTheme.textFaint
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

        width: chipRow.implicitWidth + 18
        height: 28
        radius: 11
        color: critical
            ? "#35ff6f91"
            : active ? RaohaneTheme.accentSoft : RaohaneTheme.surfaceSubtle
        border.width: 1
        border.color: critical
            ? RaohaneTheme.critical
            : active ? RaohaneTheme.accentBorder : RaohaneTheme.border

        Row {
            id: chipRow
            anchors.centerIn: parent
            spacing: 6

            RaohaneIcon {
                text: chip.icon
                iconSize: 14
                color: chip.critical
                    ? RaohaneTheme.critical
                    : chip.active ? RaohaneTheme.accent : RaohaneTheme.textMuted
            }

            Text {
                text: chip.text
                color: RaohaneTheme.text
                font.pixelSize: 8
                font.weight: Font.DemiBold
            }
        }
    }

    component MoodChip: Rectangle {
        required property string label
        property bool active: false

        width: labelText.implicitWidth + 18
        height: 26
        radius: 10
        color: active ? RaohaneTheme.accentSoft : "#5d100d18"
        border.width: 1
        border.color: active ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint

        Text {
            id: labelText
            anchors.centerIn: parent
            text: label
            color: active ? RaohaneTheme.accent : RaohaneTheme.textMuted
            font.pixelSize: 8
            font.weight: Font.Medium
        }
    }
}
