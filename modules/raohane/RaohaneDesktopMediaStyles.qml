pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.services

// Interactive Minimal and Aurora MPRIS cards. Both reuse the existing
// RaohaneMedia singleton; no duplicate players, probes, polling or processes.
RaohaneSurface {
    id: root

    property bool compact: false
    property string faceStyle: "minimal"

    readonly property bool aurora: faceStyle === "aurora"
    readonly property bool hasMedia: RaohaneMedia.available
    readonly property string artwork: hasMedia ? String(RaohaneMedia.artUrl ?? "") : ""

    implicitHeight: compact ? 146 : 164
    surfaceRadius: aurora ? 20 : 12
    raised: aurora
    showSheen: aurora
    idleColor: aurora ? RaohaneTheme.surfaceRaised : RaohaneTheme.surfaceDeep
    idleBorderColor: aurora ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint
    clip: true

    Rectangle {
        anchors.fill: parent
        visible: root.aurora
        radius: root.surfaceRadius
        color: RaohaneTheme.accentSoft
        opacity: 0.28
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: root.compact ? 12 : 16
        spacing: root.compact ? 9 : 13

        Rectangle {
            Layout.preferredWidth: root.aurora ? (root.compact ? 80 : 100) : 4
            Layout.fillHeight: true
            radius: root.aurora ? 12 : 2
            color: root.aurora ? RaohaneTheme.surfaceDeep : RaohaneTheme.accent
            border.width: root.aurora ? 1 : 0
            border.color: RaohaneTheme.accentBorder
            clip: true

            Image {
                id: coverImage
                anchors.fill: parent
                visible: root.aurora && root.hasMedia && status === Image.Ready
                source: root.aurora && root.visible && root.hasMedia ? root.artwork : ""
                asynchronous: true
                sourceSize.width: 200
                sourceSize.height: 200
                fillMode: Image.PreserveAspectCrop
            }

            RaohaneIcon {
                visible: root.aurora && !coverImage.visible
                anchors.centerIn: parent
                text: root.hasMedia ? "album" : "music_note"
                iconSize: 34
                color: RaohaneTheme.accent
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: 0
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                RaohaneIcon {
                    text: "graphic_eq"
                    color: RaohaneTheme.accent
                    iconSize: 14
                }

                Text {
                    text: root.aurora ? qsTr("AURORA / NOW PLAYING") : qsTr("NOW PLAYING")
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: root.hasMedia ? (RaohaneMedia.playerName || qsTr("Player")) : qsTr("No media")
                    color: RaohaneTheme.textFaint
                    font.pixelSize: 8
                    elide: Text.ElideRight
                    Layout.maximumWidth: 95
                }
            }

            Item { Layout.fillHeight: true }

            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: root.hasMedia ? (RaohaneMedia.title || qsTr("Unknown track")) : qsTr("Ready for your music")
                color: RaohaneTheme.text
                font.pixelSize: root.aurora ? (root.compact ? 13 : 16) : 15
                font.weight: Font.DemiBold
                maximumLineCount: 2
                wrapMode: Text.WordWrap
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: root.hasMedia ? (RaohaneMedia.artist || RaohaneMedia.album || qsTr("Unknown artist"))
                    : qsTr("Start playback in any MPRIS player")
                color: root.aurora ? RaohaneTheme.accent : RaohaneTheme.textMuted
                font.pixelSize: 10
                elide: Text.ElideRight
            }

            Item { Layout.fillHeight: true }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 4
                radius: 2
                color: RaohaneTheme.borderFaint

                Rectangle {
                    width: parent.width * (root.hasMedia ? RaohaneMedia.progress : 0)
                    height: parent.height
                    radius: 2
                    color: RaohaneTheme.accent
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 7

                Text {
                    text: root.hasMedia ? RaohaneMedia.formatTime(RaohaneMedia.position) : "0:00"
                    font.pixelSize: 9
                    color: RaohaneTheme.textFaint
                }

                Item { Layout.fillWidth: true }

                MediaAction {
                    glyph: "skip_previous"
                    canUse: root.hasMedia && RaohaneMedia.canGoPrevious
                    onTriggered: RaohaneMedia.previous()
                }
                MediaAction {
                    glyph: RaohaneMedia.isPlaying ? "pause" : "play_arrow"
                    canUse: root.hasMedia && RaohaneMedia.canTogglePlaying
                    highlighted: true
                    onTriggered: RaohaneMedia.togglePlaying()
                }
                MediaAction {
                    glyph: "skip_next"
                    canUse: root.hasMedia && RaohaneMedia.canGoNext
                    onTriggered: RaohaneMedia.next()
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: root.hasMedia ? RaohaneMedia.formatTime(RaohaneMedia.length) : "0:00"
                    font.pixelSize: 9
                    color: RaohaneTheme.textFaint
                }
            }
        }
    }

    component MediaAction: Rectangle {
        id: control
        required property string glyph
        property bool canUse: false
        property bool highlighted: false
        signal triggered()

        Layout.preferredWidth: highlighted ? 29 : 25
        Layout.preferredHeight: highlighted ? 29 : 25
        radius: 9
        opacity: canUse ? 1 : 0.4
        color: highlighted ? RaohaneTheme.accentSoft : "transparent"
        border.width: highlighted ? 1 : 0
        border.color: RaohaneTheme.accentBorder

        RaohaneIcon {
            anchors.centerIn: parent
            text: control.glyph
            iconSize: control.highlighted ? 19 : 17
            color: RaohaneTheme.accent
        }

        MouseArea {
            anchors.fill: parent
            enabled: control.canUse && !RaohaneState.desktopWidgetEditMode
            cursorShape: Qt.PointingHandCursor
            onClicked: control.triggered()
        }
    }
}
