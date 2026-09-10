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
    surfaceRadius: RaohaneTheme.radiusLarge
    raised: false
    showSheen: false
    idleBorderColor: RaohaneTheme.borderFaint
    showStateRail: true
    stateRailColor: RaohaneTheme.accent
    stateRailOpacity: RaohaneMedia.available ? 0.92 : 0.58
    stateRailWidth: 2
    stateRailLength: RaohaneMedia.available ? 36 : 24

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: RaohaneTheme.panelPadding
        anchors.rightMargin: RaohaneTheme.panelPadding - 1
        anchors.topMargin: RaohaneTheme.spacing + 1
        anchors.bottomMargin: RaohaneTheme.spacing + 1
        spacing: RaohaneTheme.spacing + 1

        RaohaneSurface {
            id: contextArtwork

            Layout.preferredWidth: RaohaneMedia.available
                ? (root.compact ? 54 : 62)
                : 38
            Layout.preferredHeight: width
            surfaceRadius: RaohaneMedia.available ? RaohaneTheme.radius : RaohaneTheme.radiusSmall
            raised: false
            showSheen: false
            showInnerRim: false
            idleColor: RaohaneTheme.accentSoft
            idleBorderColor: RaohaneTheme.borderFaint
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
            spacing: Math.max(1, RaohaneTheme.spacingTiny - 1)

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
                Layout.topMargin: RaohaneTheme.spacingTiny + 1
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
