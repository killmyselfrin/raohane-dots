pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.services

RaohaneSurface {
    id: root

    property bool compact: false

    implicitHeight: RaohaneMedia.available
        ? (root.compact ? 92 : 104)
        : (root.compact ? 64 : 72)
    surfaceRadius: 11
    raised: false
    showSheen: false
    border.color: RaohaneTheme.borderFaint

    Rectangle {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 2
        height: RaohaneMedia.available ? 36 : 24
        radius: 1
        color: RaohaneTheme.accent
        opacity: RaohaneMedia.available ? 0.92 : 0.58
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 11
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        spacing: 10

        Rectangle {
            id: contextArtwork

            Layout.preferredWidth: RaohaneMedia.available
                ? (root.compact ? 54 : 62)
                : 38
            Layout.preferredHeight: width
            radius: RaohaneMedia.available ? 9 : 8
            color: RaohaneTheme.accentSoft
            border.width: 1
            border.color: RaohaneTheme.borderFaint
            clip: true

            Image {
                id: artImage

                anchors.fill: parent
                visible: RaohaneMedia.available && status === Image.Ready
                source: RaohaneMedia.artUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }

            RaohaneIcon {
                anchors.centerIn: parent
                visible: !artImage.visible
                text: RaohaneMedia.available ? "music_note" : RaohaneContext.icon
                iconSize: RaohaneMedia.available ? 22 : 17
                fill: 1
                color: RaohaneTheme.accent
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: RaohaneMedia.available ? qsTr("NOW PLAYING") : qsTr("LIVE CONTEXT")
                color: RaohaneTheme.textFaint
                font.pixelSize: 7
                font.weight: Font.DemiBold
                font.letterSpacing: 1
            }

            Text {
                Layout.fillWidth: true
                text: RaohaneMedia.available ? (RaohaneMedia.title || qsTr("Unknown track")) : RaohaneContext.title
                color: RaohaneTheme.text
                font.pixelSize: root.compact ? 10 : 11
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: RaohaneMedia.available ? (RaohaneMedia.artist || RaohaneMedia.playerName) : RaohaneContext.detail
                color: RaohaneTheme.textMuted
                font.pixelSize: 8
                elide: Text.ElideRight
            }

            Rectangle {
                visible: RaohaneMedia.available
                Layout.fillWidth: true
                Layout.topMargin: 4
                Layout.preferredHeight: 2
                radius: 1
                color: RaohaneTheme.border

                Rectangle {
                    width: parent.width * RaohaneMedia.progress
                    height: parent.height
                    radius: 1
                    color: RaohaneTheme.accent
                }
            }
        }

        RaohaneIcon {
            visible: RaohaneMedia.available
            text: RaohaneMedia.isPlaying ? "graphic_eq" : "pause"
            iconSize: 15
            fill: 1
            color: RaohaneTheme.accent
        }
    }
}
