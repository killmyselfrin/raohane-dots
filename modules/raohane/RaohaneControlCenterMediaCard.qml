pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

RaohaneSurface {
    id: root

    property bool mediaAvailable: false
    property bool playing: false
    property bool canGoPrevious: false
    property bool canTogglePlaying: false
    property bool canGoNext: false
    property real progress: 0
    property url artUrl: ""
    property string playerName: ""
    property string title: qsTr("Nothing playing")
    property string subtitle: qsTr("Media controls")
    property string elapsedText: "--:--"
    property string totalText: "—"

    signal openRequested()
    signal previousRequested()
    signal togglePlayingRequested()
    signal nextRequested()

    readonly property real clampedProgress: Math.max(0, Math.min(1, Number(root.progress) || 0))

    implicitHeight: root.mediaAvailable ? 220 : 118
    // Raohane Flow: softly raised edges and a quiet wash, with the full
    // card opening the existing overlay only when a player is available.
    surfaceRadius: RaohaneTheme.radiusHero
    raised: false
    showSheen: true
    showInnerRim: true
    interactive: root.mediaAvailable
    hovered: root.mediaAvailable && summaryMouse.containsMouse
    pressed: root.mediaAvailable && summaryMouse.pressed
    hoverScale: 1
    pressedScale: 1
    idleColor: RaohaneTheme.surfaceSubtle
    hoverColor: RaohaneTheme.surfaceHover
    idleBorderColor: RaohaneTheme.borderFaint
    hoverBorderColor: RaohaneTheme.borderStrong
    showStateRail: false
    stateRailColor: RaohaneTheme.accent
    stateRailWidth: 2
    stateRailLength: 30
    stateRailOpacity: 0
    clip: true

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: RaohaneTheme.spacing
        spacing: RaohaneTheme.spacingSmall

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            RowLayout {
                anchors.fill: parent
                spacing: RaohaneTheme.spacing

                RaohaneSurface {
                    Layout.preferredWidth: root.mediaAvailable ? 76 : 54
                    Layout.preferredHeight: root.mediaAvailable ? 76 : 54
                    Layout.alignment: Qt.AlignVCenter
                    surfaceRadius: RaohaneTheme.radiusLarge
                    raised: false
                    showSheen: false
                    showInnerRim: true
                    idleColor: RaohaneTheme.surfaceDeep
                    idleBorderColor: RaohaneTheme.borderFaint
                    clip: true

                    Image {
                        id: mediaArt
                        anchors.fill: parent
                        // Release artwork decoding when the card has no
                        // player or the containing panel is not visible.
                        source: root.mediaAvailable && root.visible ? root.artUrl : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: status === Image.Ready
                    }

                    RaohaneIcon {
                        anchors.centerIn: parent
                        visible: !mediaArt.visible
                        text: "music_note"
                        iconSize: root.mediaAvailable ? 28 : 22
                        fill: root.playing ? 1 : 0
                        symbolWeight: root.playing ? 540 : 400
                        color: root.playing ? RaohaneTheme.accent : RaohaneTheme.textFaint
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Math.max(1, RaohaneTheme.spacingTiny - 1)

                    RowLayout {
                        visible: root.mediaAvailable
                        Layout.fillWidth: true
                        Layout.preferredHeight: visible ? implicitHeight : 0
                        spacing: RaohaneTheme.spacingSmall

                        Text {
                            Layout.fillWidth: true
                            text: root.mediaAvailable ? qsTr("Now playing") : qsTr("Media")
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.7
                            elide: Text.ElideRight
                        }

                        Text {
                            visible: root.playerName.length > 0
                            Layout.minimumWidth: 0
                            Layout.maximumWidth: root.width * 0.36
                            text: root.playerName
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 9
                            elide: Text.ElideRight
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.title
                        color: RaohaneTheme.text
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.subtitle
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 10
                        elide: Text.ElideRight
                    }

                    Item { Layout.fillHeight: true }

                    Rectangle {
                        visible: root.mediaAvailable
                        Layout.fillWidth: true
                        Layout.preferredHeight: visible ? 5 : 0
                        radius: height / 2
                        color: RaohaneTheme.surfaceDeep

                        Rectangle {
                            width: parent.width * root.clampedProgress
                            height: parent.height
                            radius: parent.radius
                            color: RaohaneTheme.accent
                        }
                    }

                    RowLayout {
                        visible: root.mediaAvailable
                        Layout.fillWidth: true
                        Layout.preferredHeight: visible ? implicitHeight : 0
                        spacing: RaohaneTheme.spacingSmall

                        Text {
                            text: root.elapsedText
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 9
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: root.totalText
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 9
                        }
                    }
                }
            }

            MouseArea {
                id: summaryMouse
                anchors.fill: parent
                z: 20
                hoverEnabled: root.mediaAvailable
                enabled: root.mediaAvailable
                acceptedButtons: Qt.LeftButton
                cursorShape: root.mediaAvailable ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    if (root.mediaAvailable)
                        root.openRequested()
                }
            }
        }

        Rectangle {
            visible: root.mediaAvailable
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? 1 : 0
            color: RaohaneTheme.divider
        }

        RowLayout {
            visible: root.mediaAvailable
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? 30 : 0
            spacing: RaohaneTheme.spacingSmall

            Item { Layout.fillWidth: true }

            RaohaneIconButton {
                buttonSize: 28
                iconSize: 14
                icon: "skip_previous"
                transparentIdle: true
                showSheen: false
                hoverScale: 1
                pressedScale: 1
                enabled: root.canGoPrevious
                onClicked: root.previousRequested()
            }

            RaohaneIconButton {
                buttonSize: 30
                iconSize: 16
                icon: root.playing ? "pause" : "play_arrow"
                emphasized: root.canTogglePlaying
                transparentIdle: !root.canTogglePlaying
                showSheen: true
                hoverScale: 1
                pressedScale: 1
                enabled: root.canTogglePlaying
                onClicked: root.togglePlayingRequested()
            }

            RaohaneIconButton {
                buttonSize: 28
                iconSize: 14
                icon: "skip_next"
                transparentIdle: true
                showSheen: false
                hoverScale: 1
                pressedScale: 1
                enabled: root.canGoNext
                onClicked: root.nextRequested()
            }

            Item { Layout.fillWidth: true }
        }
    }
}
