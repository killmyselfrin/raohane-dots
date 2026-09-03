pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.modules.raohane.config
import qs.modules.raohane.services

Item {
    id: root

    function openPage(page: string): void {
        RaohaneSettingsRouter.request(page, "")
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        RaohaneSurface {
            Layout.fillWidth: true
            Layout.preferredHeight: 190
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
                opacity: status === Image.Ready ? (RaohaneTheme.dark ? 0.42 : 0.30) : 0
            }

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: RaohaneTheme.dark ? "#ee161616" : "#eef5f2ec" }
                    GradientStop { position: 0.62; color: RaohaneTheme.dark ? "#c9161616" : "#d8f5f2ec" }
                    GradientStop { position: 1.0; color: RaohaneTheme.dark ? "#92161616" : "#9cf5f2ec" }
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
                    font.pixelSize: 19
                    font.weight: Font.DemiBold
                }

                Text {
                    text: qsTr("A minimal Hyprland shell, shaped live")
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
                    text: qsTr("%1% volume").arg(Math.round(RaohaneAudio.volume * 100))
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
            spacing: 10

            ColumnLayout {
                spacing: 1

                Text {
                    text: qsTr("Core surfaces")
                    color: RaohaneTheme.text
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }

                Text {
                    text: qsTr("Everything below applies live and stays inside the Raohane design system")
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 8
                }
            }

            Item { Layout.fillWidth: true }

            PathChip {
                label: qsTr("Open native.json")
                path: RaohanePaths.nativeConfigFile
                icon: "tune"
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: root.width > 820 ? 3 : 2
            columnSpacing: 10
            rowSpacing: 10

            DeckCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                icon: "palette"
                title: qsTr("Themes")
                detail: qsTr("Theme Library, accent color and Style Studio")
                page: "Themes"
            }

            DeckCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                icon: "wand_stars"
                title: qsTr("Appearance")
                detail: qsTr("Screen framing, rounding and interaction chrome")
                page: "Appearance"
            }

            DeckCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                icon: "monitor"
                title: qsTr("Displays")
                detail: qsTr("Resolution, refresh rate, scale, rotation and VRR")
                page: "Displays"
            }

            DeckCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                icon: "dock_to_bottom"
                title: qsTr("Bar & Dock")
                detail: qsTr("Floating bar, Context Island and application dock")
                page: "Bar & Dock"
            }

            DeckCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                icon: "music_note"
                title: qsTr("Media & OSD")
                detail: qsTr("Media overlay, Island behavior and system feedback")
                page: "Media & OSD"
            }

            DeckCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                icon: "view_quilt"
                title: qsTr("Desktop & Spaces")
                detail: qsTr("Wallpaper, transitions and workspace overview")
                page: "Desktop & Spaces"
            }

            DeckCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                icon: "instant_mix"
                title: qsTr("Quick Controls")
                detail: qsTr("Choose the controls shown in the command surface")
                page: "Quick Controls"
            }
        }
    }

    component PathChip: Rectangle {
        id: pathChip

        required property string label
        required property string path
        required property string icon

        width: pathRow.implicitWidth + 18
        height: 29
        radius: 10
        color: pathMouse.containsMouse ? RaohaneTheme.surfaceHover : "transparent"
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

        Layout.minimumHeight: 108
        surfaceRadius: 17
        hovered: cardMouse.containsMouse
        raised: false
        showSheen: false

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 6

            RowLayout {
                Layout.fillWidth: true

                Rectangle {
                    width: 32
                    height: 32
                    radius: 10
                    color: RaohaneTheme.surfaceSubtle
                    border.width: 1
                    border.color: cardMouse.containsMouse ? RaohaneTheme.borderStrong : RaohaneTheme.border

                    RaohaneIcon {
                        anchors.centerIn: parent
                        text: card.icon
                        iconSize: 17
                        color: cardMouse.containsMouse ? RaohaneTheme.accent : RaohaneTheme.textMuted
                    }
                }

                Item { Layout.fillWidth: true }

                RaohaneIcon {
                    text: "arrow_forward"
                    iconSize: 14
                    color: cardMouse.containsMouse ? RaohaneTheme.accent : RaohaneTheme.textFaint
                }
            }

            Text {
                Layout.fillWidth: true
                text: card.title
                color: RaohaneTheme.text
                font.pixelSize: 10
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
        height: 27
        radius: 10
        color: RaohaneTheme.surfaceSubtle
        border.width: 1
        border.color: critical ? RaohaneTheme.critical : active ? RaohaneTheme.borderStrong : RaohaneTheme.border

        Row {
            id: chipRow
            anchors.centerIn: parent
            spacing: 6

            RaohaneIcon {
                text: chip.icon
                iconSize: 13
                color: chip.critical ? RaohaneTheme.critical : chip.active ? RaohaneTheme.accent : RaohaneTheme.textMuted
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
        height: 25
        radius: 9
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
