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
        spacing: 14

        RaohaneSurface {
            Layout.fillWidth: true
            Layout.preferredHeight: 138
            surfaceRadius: RaohaneTheme.radiusLarge
            raised: false
            clip: true
            showSheen: false
            border.color: RaohaneTheme.borderStrong

            Loader {
                anchors.fill: parent
                active: !RaohaneWallpapers.isVideo(RaohaneConfig.wallpaperPath)

                sourceComponent: Image {
                    anchors.fill: parent
                    visible: !RaohaneWallpapers.isVideo(RaohaneConfig.wallpaperPath)
                    source: visible ? RaohaneConfig.wallpaperPath : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                    opacity: status === Image.Ready ? (RaohaneTheme.dark ? 0.24 : 0.18) : 0
                }
            }

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: RaohaneTheme.dark ? "#f2171920" : "#f6f4f1eb" }
                    GradientStop { position: 0.64; color: RaohaneTheme.dark ? "#dc171920" : "#e7f4f1eb" }
                    GradientStop { position: 1.0; color: RaohaneTheme.dark ? "#a9171920" : "#baf4f1eb" }
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 18

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 4

                    RowLayout {
                        spacing: 10

                        Rectangle {
                            Layout.preferredWidth: 34
                            Layout.preferredHeight: 34
                            radius: 11
                            color: RaohaneTheme.accentSoft
                            border.width: 1
                            border.color: RaohaneTheme.accentBorder

                            RaohaneIcon {
                                anchors.centerIn: parent
                                text: "spa"
                                iconSize: 18
                                fill: 1
                                symbolWeight: 560
                                color: RaohaneTheme.accent
                            }
                        }

                        ColumnLayout {
                            spacing: 0

                            Text {
                                text: qsTr("Raohane")
                                color: RaohaneTheme.text
                                font.pixelSize: 17
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: qsTr("A minimal Hyprland shell, shaped live")
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 9
                            }
                        }
                    }

                    RowLayout {
                        Layout.topMargin: 10
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
                }

                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 78
                    color: RaohaneTheme.borderFaint
                }

                ColumnLayout {
                    Layout.preferredWidth: 190
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        MoodChip { label: RaohaneTheme.presetName; active: true }
                        MoodChip { label: RaohaneTheme.dark ? qsTr("Dark") : qsTr("Light") }
                    }

                    PathChip {
                        Layout.fillWidth: true
                        label: qsTr("Open native.json")
                        path: RaohanePaths.nativeConfigFile
                        icon: "tune"
                    }
                }
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
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 2
            columnSpacing: 9
            rowSpacing: 9

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

            DeckCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                icon: "keyboard"
                title: qsTr("Keyboard & Motion")
                detail: qsTr("Keybinds, input behavior and animation preferences")
                page: "Keyboard & Motion"
            }
        }
    }

    component PathChip: RaohaneSurface {
        id: pathChip

        required property string label
        required property string path
        required property string icon

        implicitHeight: 31
        surfaceRadius: 10
        transparentIdle: true
        showSheen: false
        hovered: pathMouse.containsMouse
        interactive: true
        border.color: pathMouse.containsMouse ? RaohaneTheme.borderStrong : RaohaneTheme.borderFaint

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 9
            anchors.rightMargin: 9
            spacing: 6

            RaohaneIcon {
                text: pathChip.icon
                iconSize: 13
                color: pathMouse.containsMouse ? RaohaneTheme.accent : RaohaneTheme.textMuted
            }

            Text {
                Layout.fillWidth: true
                text: pathChip.label
                color: pathMouse.containsMouse ? RaohaneTheme.text : RaohaneTheme.textMuted
                font.pixelSize: 8
                elide: Text.ElideRight
            }

            RaohaneIcon {
                text: "arrow_outward"
                iconSize: 11
                color: RaohaneTheme.textFaint
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

        Layout.minimumHeight: 70
        surfaceRadius: 15
        hovered: cardMouse.containsMouse
        pressed: cardMouse.pressed
        interactive: true
        raised: false
        showSheen: false
        hoverScale: 1.004
        pressedScale: 0.994
        border.color: cardMouse.containsMouse ? RaohaneTheme.borderStrong : RaohaneTheme.borderFaint

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 11
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: 11
                color: cardMouse.containsMouse ? RaohaneTheme.accentSoft : RaohaneTheme.surfaceSubtle
                border.width: 1
                border.color: cardMouse.containsMouse ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint

                RaohaneIcon {
                    anchors.centerIn: parent
                    text: card.icon
                    iconSize: 17
                    fill: cardMouse.containsMouse ? 0.45 : 0
                    symbolWeight: cardMouse.containsMouse ? 520 : 430
                    color: cardMouse.containsMouse ? RaohaneTheme.accent : RaohaneTheme.textMuted
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: card.title
                    color: RaohaneTheme.text
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: card.detail
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 7
                    maximumLineCount: 1
                    elide: Text.ElideRight
                }
            }

            RaohaneIcon {
                text: "chevron_right"
                iconSize: 14
                color: cardMouse.containsMouse ? RaohaneTheme.accent : RaohaneTheme.textFaint
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

        Layout.preferredWidth: Math.min(164, chipRow.implicitWidth + 18)
        Layout.preferredHeight: 27
        radius: 10
        color: RaohaneTheme.surfaceSubtle
        border.width: 1
        border.color: critical ? Qt.rgba(RaohaneTheme.critical.r, RaohaneTheme.critical.g, RaohaneTheme.critical.b, 0.55)
            : active ? RaohaneTheme.borderStrong : RaohaneTheme.borderFaint

        Row {
            id: chipRow
            anchors.centerIn: parent
            spacing: 6

            RaohaneIcon {
                text: chip.icon
                iconSize: 12
                color: chip.critical ? RaohaneTheme.critical : chip.active ? RaohaneTheme.accent : RaohaneTheme.textMuted
            }

            Text {
                width: Math.min(120, implicitWidth)
                text: chip.text
                color: RaohaneTheme.text
                font.pixelSize: 7
                font.weight: Font.Medium
                elide: Text.ElideRight
            }
        }
    }

    component MoodChip: Rectangle {
        required property string label
        property bool active: false

        Layout.preferredWidth: labelText.implicitWidth + 18
        Layout.preferredHeight: 25
        radius: 9
        color: active ? RaohaneTheme.accentSoft : RaohaneTheme.surfaceSubtle
        border.width: 1
        border.color: active ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint

        Text {
            id: labelText
            anchors.centerIn: parent
            text: label
            color: active ? RaohaneTheme.accent : RaohaneTheme.textMuted
            font.pixelSize: 7
            font.weight: Font.Medium
        }
    }
}
