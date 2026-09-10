pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property bool lyricsOpen: false
    property bool gamingEdgeMode: false
    property bool mediaAvailable: false
    property bool playing: false
    property bool canSeek: false
    property bool canRaise: false
    property bool canGoPrevious: false
    property bool canTogglePlaying: false
    property bool canGoNext: false
    property bool volumeSupported: false
    property int playerCount: 0
    property real progress: 0
    property real volume: 0
    property color accent: RaohaneTheme.accent
    property url artUrl: ""
    property string playerName: ""
    property string title: ""
    property string artist: ""
    property string album: ""
    property string elapsedText: "--:--"
    property string remainingText: "--:--"

    signal cyclePlayerRequested(int step)
    signal seekRequested(real ratio)
    signal lyricsRequested()
    signal raiseRequested()
    signal closeRequested()
    signal previousRequested()
    signal togglePlayingRequested()
    signal nextRequested()
    signal volumeRequested(real value)

    implicitHeight: root.lyricsOpen ? 74 : root.gamingEdgeMode ? 90 : 108

    RowLayout {
        anchors.fill: parent
        anchors.margins: 2
        spacing: root.gamingEdgeMode ? 9 : 12

        Item {
            Layout.preferredWidth: root.lyricsOpen ? 60 : root.gamingEdgeMode ? 76 : 90
            Layout.preferredHeight: root.lyricsOpen ? 60 : root.gamingEdgeMode ? 76 : 90
            Layout.alignment: Qt.AlignVCenter
            clip: true

            Rectangle {
                anchors.fill: parent
                radius: root.lyricsOpen ? 13 : 16
                color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.13)
                border.width: 1
                border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.28)
            }

            Image {
                id: cover
                anchors.fill: parent
                source: root.artUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                visible: status === Image.Ready
            }

            Text {
                anchors.centerIn: parent
                visible: !root.mediaAvailable || cover.status !== Image.Ready
                text: "音"
                color: root.accent
                font.pixelSize: root.gamingEdgeMode ? 26 : 30
                font.weight: Font.DemiBold
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 1

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: root.gamingEdgeMode ? 14 : 18
                spacing: 5

                Rectangle {
                    width: 5
                    height: 5
                    radius: 3
                    color: root.playing ? root.accent : RaohaneTheme.textFaint
                }

                Text {
                    Layout.fillWidth: true
                    text: root.mediaAvailable
                        ? (root.playerName.length > 0 ? root.playerName : qsTr("Media player"))
                        : qsTr("No player")
                    color: RaohaneTheme.textFaint
                    font.pixelSize: 7
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                MiniButton {
                    visible: !root.gamingEdgeMode && root.playerCount > 1
                    icon: "chevron_left"
                    tooltip: qsTr("Previous player")
                    onClicked: root.cyclePlayerRequested(-1)
                }

                MiniButton {
                    visible: !root.gamingEdgeMode && root.playerCount > 1
                    icon: "chevron_right"
                    tooltip: qsTr("Next player")
                    onClicked: root.cyclePlayerRequested(1)
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.mediaAvailable && root.title.length > 0
                    ? root.title
                    : qsTr("Nothing is playing")
                color: RaohaneTheme.text
                font.pixelSize: root.gamingEdgeMode ? 13 : 15
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: root.mediaAvailable && root.artist.length > 0
                    ? root.artist
                    : qsTr("Start a MPRIS-compatible player")
                color: RaohaneTheme.textMuted
                font.pixelSize: root.gamingEdgeMode ? 8 : 9
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: !root.gamingEdgeMode && !root.lyricsOpen
                    && root.mediaAvailable && root.album.length > 0
                text: root.album
                color: RaohaneTheme.textFaint
                font.pixelSize: 7
                elide: Text.ElideRight
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 16
                spacing: root.gamingEdgeMode ? 4 : 6

                Text {
                    Layout.preferredWidth: root.gamingEdgeMode ? 31 : 35
                    text: root.elapsedText
                    color: RaohaneTheme.textFaint
                    font.pixelSize: root.gamingEdgeMode ? 7 : 8
                    horizontalAlignment: Text.AlignLeft
                }

                RaohaneSlider {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 15
                    from: 0
                    to: 1
                    stepSize: 0.001
                    value: root.progress
                    enabled: root.canSeek
                    showHandle: hovered || activeFocus
                    trackHeight: root.gamingEdgeMode ? 3 : 4
                    onMoved: ratio => root.seekRequested(ratio)
                }

                Text {
                    Layout.preferredWidth: root.gamingEdgeMode ? 35 : 40
                    text: root.remainingText
                    color: RaohaneTheme.textFaint
                    font.pixelSize: root.gamingEdgeMode ? 7 : 8
                    horizontalAlignment: Text.AlignRight
                }
            }
        }

        ColumnLayout {
            Layout.preferredWidth: root.gamingEdgeMode ? 118 : 142
            Layout.fillHeight: true
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                spacing: 3

                MiniButton {
                    icon: "lyrics"
                    tooltip: qsTr("Lyrics")
                    enabled: root.mediaAvailable
                    onClicked: root.lyricsRequested()
                }

                MiniButton {
                    visible: !root.gamingEdgeMode && root.canRaise
                    icon: "open_in_new"
                    tooltip: qsTr("Open player")
                    onClicked: root.raiseRequested()
                }

                Item { Layout.fillWidth: true }

                MiniButton {
                    icon: "close"
                    tooltip: qsTr("Close")
                    onClicked: root.closeRequested()
                }
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 42
                spacing: root.gamingEdgeMode ? 3 : 5

                MainButton {
                    icon: "skip_previous"
                    enabled: root.canGoPrevious
                    compact: root.gamingEdgeMode
                    onClicked: root.previousRequested()
                }

                MainButton {
                    icon: root.playing ? "pause" : "play_arrow"
                    enabled: root.canTogglePlaying
                    emphasized: true
                    compact: root.gamingEdgeMode
                    onClicked: root.togglePlayingRequested()
                }

                MainButton {
                    icon: "skip_next"
                    enabled: root.canGoNext
                    compact: root.gamingEdgeMode
                    onClicked: root.nextRequested()
                }
            }

            RowLayout {
                visible: !root.gamingEdgeMode && !root.lyricsOpen && root.volumeSupported
                Layout.fillWidth: true
                Layout.preferredHeight: visible ? 20 : 0
                spacing: 5

                RaohaneIcon {
                    text: root.volume <= 0.01 ? "volume_off" : "volume_up"
                    iconSize: 12
                    color: RaohaneTheme.textMuted
                }

                RaohaneSlider {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 18
                    from: 0
                    to: 1
                    stepSize: 0.01
                    value: root.volume
                    showHandle: hovered || activeFocus
                    trackHeight: 3
                    onMoved: value => root.volumeRequested(value)
                }
            }
        }
    }

    component MiniButton: RaohaneIconButton {
        property string tooltip: ""
        buttonSize: 28
        iconSize: 14
        transparentIdle: true
        showSheen: false
        hoverScale: 1
        pressedScale: 1
    }

    component MainButton: RaohaneIconButton {
        id: control
        property bool compact: false
        buttonSize: control.compact
            ? (control.emphasized ? 36 : 32)
            : (control.emphasized ? 40 : 36)
        iconSize: control.compact
            ? (control.emphasized ? 18 : 16)
            : (control.emphasized ? 20 : 17)
        surfaceRadius: control.emphasized ? 13 : 11
        showSheen: false
        hoverScale: 1
        pressedScale: 1
    }
}
