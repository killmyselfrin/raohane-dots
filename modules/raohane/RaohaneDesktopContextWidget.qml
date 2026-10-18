pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.services

// A dedicated media feature card, rather than a one-line system indicator.
// The MPRIS/context service remains the only source of live information.
RaohaneSurface {
    id: root

    property bool compact: false
    readonly property bool hasMedia: RaohaneMedia.available
    readonly property string coverUrl: root.hasMedia ? String(RaohaneMedia.artUrl ?? "") : ""

    implicitHeight: root.compact ? 146 : 164
    surfaceRadius: RaohaneTheme.radiusHero
    raised: true
    showSheen: true
    showInnerRim: true
    idleColor: RaohaneTheme.surfaceRaised
    idleBorderColor: RaohaneTheme.borderFaint
    clip: true
    showStateRail: true
    stateRailColor: root.hasMedia ? RaohaneTheme.accent : RaohaneTheme.accentSecondary
    stateRailWidth: 3
    stateRailLength: root.hasMedia ? 70 : 40

    Rectangle {
        anchors.fill: parent
        radius: root.surfaceRadius
        color: RaohaneTheme.accentSoft
        opacity: root.hasMedia ? 0.19 : 0.08
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.compact ? 13 : 17
        spacing: RaohaneTheme.spacingSmall

        RowLayout {
            Layout.fillWidth: true
            spacing: 7

            RaohaneIcon {
                text: root.hasMedia ? "graphic_eq" : "dynamic_feed"
                iconSize: 15
                color: RaohaneTheme.accent
            }

            Text {
                text: root.hasMedia ? qsTr("NOW PLAYING") : qsTr("LIVE CONTEXT")
                color: RaohaneTheme.textMuted
                font.pixelSize: 10
                font.weight: Font.DemiBold
                font.letterSpacing: 1.0
            }

            Item { Layout.fillWidth: true }

            RaohaneIcon {
                text: root.hasMedia
                    ? (RaohaneMedia.isPlaying ? "equalizer" : "pause")
                    : RaohaneContext.icon
                iconSize: 16
                color: RaohaneTheme.accent
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: root.compact ? 10 : 14

            RaohaneSurface {
                id: coverFrame

                Layout.preferredWidth: root.compact ? 62 : 80
                Layout.preferredHeight: root.compact ? 62 : 80
                surfaceRadius: RaohaneTheme.radiusLarge
                showSheen: false
                showInnerRim: true
                idleColor: RaohaneTheme.surfaceDeep
                idleBorderColor: RaohaneTheme.borderFaint
                clip: true

                // Release image work when this slot is hidden or MPRIS has no
                // album art; constrain decoding to a small fixed texture.
                Image {
                    id: artImage
                    anchors.fill: parent
                    anchors.margins: 1
                    visible: root.hasMedia && status === Image.Ready
                    source: root.visible && root.hasMedia ? root.coverUrl : ""
                    sourceSize.width: 160
                    sourceSize.height: 160
                    asynchronous: true
                    fillMode: Image.PreserveAspectCrop
                }

                RaohaneIcon {
                    anchors.centerIn: parent
                    visible: !artImage.visible
                    text: root.hasMedia ? "music_note" : RaohaneContext.icon
                    iconSize: root.compact ? 24 : 29
                    fill: 1
                    color: RaohaneTheme.accent
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: 3

                Text {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    text: root.hasMedia
                        ? (RaohaneMedia.title || qsTr("Unknown track"))
                        : RaohaneContext.title
                    color: RaohaneTheme.text
                    font.pixelSize: root.compact ? 12 : 15
                    font.weight: Font.DemiBold
                    maximumLineCount: 2
                    wrapMode: Text.WordWrap
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    text: root.hasMedia
                        ? (RaohaneMedia.artist || RaohaneMedia.playerName)
                        : RaohaneContext.detail
                    color: RaohaneTheme.textMuted
                    font.pixelSize: root.compact ? 10 : 11
                    maximumLineCount: 2
                    wrapMode: Text.WordWrap
                    elide: Text.ElideRight
                }

                Item { Layout.fillHeight: true }

                RowLayout {
                    visible: root.hasMedia && RaohaneMedia.length > 0
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: RaohaneMedia.formatTime(RaohaneMedia.position)
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 9
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: RaohaneMedia.formatTime(RaohaneMedia.length)
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 9
                    }
                }
            }
        }

        Rectangle {
            visible: root.hasMedia && RaohaneMedia.length > 0
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? 4 : 0
            radius: height / 2
            color: RaohaneTheme.border

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, RaohaneMedia.progress))
                height: parent.height
                radius: height / 2
                color: RaohaneTheme.accent
            }
        }
    }
}
