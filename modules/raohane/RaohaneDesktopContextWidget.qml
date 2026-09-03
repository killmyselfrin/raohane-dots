pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.services

RaohaneSurface {
    id: root

    property bool compact: false

    implicitHeight: RaohaneMedia.available ? 116 : 82
    surfaceRadius: 21
    raised: true
    showSheen: true
    opacity: 0.94

    RowLayout {
        anchors.fill: parent
        anchors.margins: 13
        spacing: 12

        Rectangle {
            id: contextArtwork

            Layout.preferredWidth: RaohaneMedia.available ? 74 : 44
            Layout.preferredHeight: width
            radius: RaohaneMedia.available ? 18 : 14
            color: RaohaneTheme.accentSoft
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
                iconSize: RaohaneMedia.available ? 28 : 21
                fill: 1
                color: RaohaneTheme.accent
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

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
                font.pixelSize: 12
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: RaohaneMedia.available ? (RaohaneMedia.artist || RaohaneMedia.playerName) : RaohaneContext.detail
                color: RaohaneTheme.textMuted
                font.pixelSize: 9
                elide: Text.ElideRight
            }

            Rectangle {
                visible: RaohaneMedia.available
                Layout.fillWidth: true
                Layout.topMargin: 5
                Layout.preferredHeight: 3
                radius: 2
                color: RaohaneTheme.border

                Rectangle {
                    width: parent.width * RaohaneMedia.progress
                    height: parent.height
                    radius: parent.radius
                    color: RaohaneTheme.accent

                    Behavior on width {
                        NumberAnimation {
                            duration: 450
                            easing.type: RaohaneMotion.easeStandard
                        }
                    }
                }
            }
        }

        RaohaneIcon {
            visible: RaohaneMedia.available
            text: RaohaneMedia.isPlaying ? "graphic_eq" : "pause"
            iconSize: 18
            fill: 1
            color: RaohaneTheme.accent
        }
    }
}
