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
            border.color: RaohaneTheme.borderStrong

            Image {
                anchors.fill: parent
                source: RaohaneConfig.wallpaperPath
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                opacity: status === Image.Ready ? (RaohaneTheme.dark ? 0.52 : 0.38) : 0
            }

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: RaohaneTheme.dark ? "#e8171817" : "#e8f4f1eb" }
                    GradientStop { position: 0.52; color: RaohaneTheme.dark ? "#c8171817" : "#ccefebE5" }
                    GradientStop { position: 1.0; color: RaohaneTheme.dark ? "#8a171817" : "#8af5f1eb" }
                }
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
                    text: qsTr("Raohane")
                    color: RaohaneTheme.text
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                }

                Text {
                    text: qsTr("Minimal Japanese shell · native Hyprland control deck")
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

                MoodChip { label: RaohaneTheme.presetName; active: true }
                MoodChip { label: RaohaneTheme.dark ? qsTr("Dark") : qsTr("Light") }
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
                title: qsTr("Themes")
                detail: qsTr("Minimal palettes and complete shell moods")
                page: "Themes"
            }

            DeckCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                icon: "toast"
                title: qsTr("Bar & Dock")
                detail: qsTr("Floating pods, Context Island and application dock")
                page: "Bar"
            }

            DeckCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                icon: "texture"
                title: qsTr("Desktop & Spaces")
                detail: qsTr("Wallpaper, Overview, transitions and living canvas")
                page: "Desktop"
            }

            DeckCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                icon: "bottom_app_bar"
                title: qsTr("Interface")
                detail: qsTr("Screen chrome, corners and interaction feel")
                page: "Interface"
            }

            DeckCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                icon: "select_window_2"
                title: qsTr("Hyprland")
                detail: qsTr("Compositor-facing behavior, workspaces and fullscreen")
                page: "Hyprland"
            }

            DeckCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                icon: "settings"
                title: qsTr("System & Services")
                detail: qsTr("Integrations, commands, autostart and native helpers")
                page: "Services"
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
        color: pathMouse.containsMouse ? RaohaneTheme.surfaceHover : RaohaneTheme.surfaceSubtle
        border.width: 1
        border.color: pathMouse.containsMouse ? RaohaneTheme.borderStrong : RaohaneTheme.border

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

        Layout.minimumHeight: 112
        surfaceRadius: 19
        hovered: cardMouse.containsMouse
        raised: false

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 6

            RowLayout {
                Layout.fillWidth: true

                Rectangle {
                    width: 34
                    height: 34
                    radius: 12
                    color: cardMouse.containsMouse ? RaohaneTheme.surfaceHover : RaohaneTheme.surfaceSubtle
                    border.width: 1
                    border.color: cardMouse.containsMouse ? RaohaneTheme.borderStrong : RaohaneTheme.border

                    RaohaneIcon {
                        anchors.centerIn: parent
                        text: card.icon
                        iconSize: 18
                        color: cardMouse.containsMouse ? RaohaneTheme.accent : RaohaneTheme.textMuted
                    }
                }

                Item { Layout.fillWidth: true }

                RaohaneIcon {
                    text: "arrow_forward"
                    iconSize: 15
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
        color: RaohaneTheme.surfaceSubtle
        border.width: 1
        border.color: critical
            ? RaohaneTheme.critical
            : active ? RaohaneTheme.borderStrong : RaohaneTheme.border

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
                font.weight: Font.Medium
            }
        }
    }

    component MoodChip: Rectangle {
        required property string label
        property bool active: false

        width: labelText.implicitWidth + 18
        height: 26
        radius: 10
        color: active ? RaohaneTheme.surfaceRaised : RaohaneTheme.surfaceSubtle
        border.width: 1
        border.color: active ? RaohaneTheme.borderStrong : RaohaneTheme.border

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
